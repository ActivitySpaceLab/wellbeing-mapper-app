#!/bin/bash

echo "=== Simple Qualtrics API Test ==="
echo ""

# Check if QUALTRICS_API_TOKEN is set
if [ -z "$QUALTRICS_API_TOKEN" ]; then
    echo "❌ Error: QUALTRICS_API_TOKEN environment variable not set"
    echo "Please set it with: export QUALTRICS_API_TOKEN=your_token_here"
    exit 1
fi

QUALTRICS_TOKEN="$QUALTRICS_API_TOKEN"
QUALTRICS_URL="https://pretoria.eu.qualtrics.com"

test_survey() {
    local survey_name="$1"
    local survey_id="$2"
    
    echo "--- Testing $survey_name ($survey_id) ---"
    
    # Check survey structure
    echo "Checking survey structure..."
    response=$(curl -s -X GET "$QUALTRICS_URL/API/v3/surveys/$survey_id" \
        -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"httpStatus":"200 - OK"'; then
        echo "✅ Survey structure retrieved successfully"
        
        # Check for questions using basic text processing
        question_count=$(echo "$response" | grep -o '"QID[0-9]*"' | wc -l | tr -d ' ')
        echo "Questions found: $question_count"
        
        if [ "$question_count" -eq 0 ]; then
            echo "❌ No questions found in survey structure!"
            echo "This may explain why data doesn't appear in dashboard"
        else
            echo "Sample question IDs found:"
            echo "$response" | grep -o '"QID[0-9]*"' | head -5 | sed 's/"//g' | sed 's/^/  /'
        fi
    else
        echo "❌ Failed to get survey structure"
    fi
    
    # Submit test data
    echo ""
    echo "Submitting test data..."
    
    timestamp=$(date +%s)
    
    if [ "$survey_name" = "Initial Survey" ]; then
        test_data='{"QID1":"TEST-UUID-INITIAL-'$timestamp'","QID2":"25","QID3":"Johannesburg","QID4":"African","QID5":"Female","QID6":"4","QID7":"5"}'
    elif [ "$survey_name" = "Biweekly Survey" ]; then
        test_data='{"QID1":"TEST-UUID-BIWEEKLY-'$timestamp'","QID2":"30","QID3":"Cape Town","QID4":"Coloured","QID5":"Male","QID6":"3","QID7":"4"}'
    elif [ "$survey_name" = "Consent Survey" ]; then
        test_data='{"QID1":"TEST-CODE-'$timestamp'","QID2":"TEST-UUID-CONSENT-'$timestamp'","QID3":"1","QID4":"1","QID5":"1","QID6":"1","QID7":"0","QID8":"1","QID9":"1","QID10":"1","QID11":"1","QID12":"1","QID13":"0","QID14":"1","QID15":"Test Participant","QID16":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'
    fi
    
    submit_response=$(curl -s -X POST "$QUALTRICS_URL/API/v3/surveys/$survey_id/responses" \
        -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$test_data")
    
    if echo "$submit_response" | grep -q '"httpStatus":"200 - OK"'; then
        echo "✅ Data submitted successfully"
        
        response_id=$(echo "$submit_response" | grep -o '"responseId":"[^"]*"' | cut -d'"' -f4)
        echo "Response ID: $response_id"
        
        # Wait and check response data
        sleep 3
        echo "Checking submitted data visibility..."
        
        retrieve_response=$(curl -s -X GET "$QUALTRICS_URL/API/v3/surveys/$survey_id/responses/$response_id" \
            -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
            -H "Content-Type: application/json")
        
        if echo "$retrieve_response" | grep -q '"httpStatus":"200 - OK"'; then
            echo "✅ Response retrieved successfully"
            
            # Count non-empty values
            value_count=$(echo "$retrieve_response" | grep -o '"QID[0-9]*":"[^"]*"' | grep -v '""' | wc -l | tr -d ' ')
            echo "Fields with data: $value_count"
            
            if [ "$value_count" -eq 0 ]; then
                echo "❌ Response exists but all field values are empty!"
                echo "This confirms the data visibility issue"
            else
                echo "✅ Found $value_count fields with data"
                echo "Sample values:"
                echo "$retrieve_response" | grep -o '"QID[0-9]*":"[^"]*"' | grep -v '""' | head -3 | sed 's/^/  /'
            fi
        else
            echo "❌ Failed to retrieve response"
        fi
        
    else
        echo "❌ Data submission failed"
        echo "Response: $submit_response"
    fi
    
    echo ""
}

# Test each survey
test_survey "Initial Survey" "SV_8pudN8qTI6iQKY6"
test_survey "Biweekly Survey" "SV_aXmfOtAIRmIVdfU"  
test_survey "Consent Survey" "SV_eu4OVw6dpbWY5hQ"

echo "=== Test Complete ==="
