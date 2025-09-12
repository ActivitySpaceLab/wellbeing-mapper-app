#!/bin/bash

echo "=== Comprehensive Qualtrics Survey Structure Test ==="
echo ""

# Check if QUALTRICS_API_TOKEN is set
if [ -z "$QUALTRICS_API_TOKEN" ]; then
    echo "❌ Error: QUALTRICS_API_TOKEN environment variable not set"
    echo "Please set it with: export QUALTRICS_API_TOKEN=your_token_here"
    exit 1
fi

QUALTRICS_TOKEN="$QUALTRICS_API_TOKEN"
QUALTRICS_URL="https://pretoria.eu.qualtrics.com"

# Test all three survey IDs (updated to new surveys)
declare -A SURVEYS
SURVEYS["Initial Survey"]="SV_aflSCXazOJiTkqy"
SURVEYS["Biweekly Survey"]="SV_0D4JPS2pOapx5lk" 
SURVEYS["Consent Survey"]="SV_3OXso1SLL2yte8C"

test_survey_structure() {
    local survey_name="$1"
    local survey_id="$2"
    
    echo "--- Testing $survey_name ($survey_id) ---"
    
    # 1. Check survey structure
    echo "Checking survey structure..."
    response=$(curl -s -X GET "$QUALTRICS_URL/API/v3/surveys/$survey_id" \
        -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"httpStatus":"200 - OK"'; then
        echo "✅ Survey structure retrieved successfully"
        
        # Extract survey name and status
        survey_title=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('name', 'Unknown'))")
        is_active=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('isActive', 'Unknown'))")
        
        echo "Survey Name: $survey_title"
        echo "Survey Active: $is_active"
        
        # Check for questions
        question_count=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); questions=data.get('result', {}).get('questions', {}); print(len(questions))")
        echo "Questions found: $question_count"
        
        if [ "$question_count" -eq 0 ]; then
            echo "❌ No questions found in survey structure!"
            echo "This may explain why data doesn't appear in dashboard"
        else
            echo "Sample question IDs:"
            echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
questions = data.get('result', {}).get('questions', {})
for i, (qid, q) in enumerate(questions.items()):
    if i < 3:
        text = q.get('questionText', 'No text')[:50]
        print(f'  {qid}: {text}...')
    elif i == 3:
        print(f'  ... and {len(questions)-3} more')
        break
"
        fi
    else
        echo "❌ Failed to get survey structure"
        echo "Response: $response"
    fi
    
    # 2. Submit test data
    echo ""
    echo "Submitting test data..."
    
    timestamp=$(date +%s)
    
    case "$survey_name" in
        "Initial Survey")
            test_data='{
                "QID1": "TEST-UUID-INITIAL-'$timestamp'",
                "QID2": "25",
                "QID3": "Johannesburg", 
                "QID4": "African",
                "QID5": "Female",
                "QID6": "4",
                "QID7": "5"
            }'
            ;;
        "Biweekly Survey")
            test_data='{
                "QID1": "TEST-UUID-BIWEEKLY-'$timestamp'",
                "QID2": "30",
                "QID3": "Cape Town",
                "QID4": "Coloured", 
                "QID5": "Male",
                "QID6": "3",
                "QID7": "4"
            }'
            ;;
        "Consent Survey")
            test_data='{
                "QID1": "TEST-CODE-'$timestamp'",
                "QID2": "TEST-UUID-CONSENT-'$timestamp'",
                "QID3": "1",
                "QID4": "1",
                "QID5": "1",
                "QID6": "1",
                "QID7": "0",
                "QID8": "1",
                "QID9": "1",
                "QID10": "1",
                "QID11": "1",
                "QID12": "1",
                "QID13": "0",
                "QID14": "1",
                "QID15": "Test Participant Signature",
                "QID16": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
            }'
            ;;
    esac
    
    submit_response=$(curl -s -X POST "$QUALTRICS_URL/API/v3/surveys/$survey_id/responses" \
        -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$test_data")
    
    if echo "$submit_response" | grep -q '"httpStatus":"200 - OK"'; then
        echo "✅ Data submitted successfully"
        
        response_id=$(echo "$submit_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('responseId', 'None'))")
        echo "Response ID: $response_id"
        
        # Wait a moment then try to retrieve the response
        sleep 3
        echo "Checking if submitted data appears in response..."
        
        retrieve_response=$(curl -s -X GET "$QUALTRICS_URL/API/v3/surveys/$survey_id/responses/$response_id" \
            -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
            -H "Content-Type: application/json")
        
        if echo "$retrieve_response" | grep -q '"httpStatus":"200 - OK"'; then
            echo "✅ Response retrieved successfully"
            
            # Check if values are present
            echo "Checking for field values..."
            echo "$retrieve_response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data.get('result', {})
values = result.get('values', {})

print(f'Fields in response: {len(values)}')
non_empty_count = 0
for key, value in values.items():
    if value and str(value).strip():
        non_empty_count += 1
        if non_empty_count <= 3:
            print(f'  {key}: \"{value}\"')

if non_empty_count == 0:
    print('❌ Response exists but all field values are empty!')
    print('This confirms the data visibility issue')
    print('Raw values:', json.dumps(values, indent=2))
else:
    print(f'✅ Found {non_empty_count} fields with data')
"
        else
            echo "❌ Failed to retrieve response"
            echo "Response: $retrieve_response"
        fi
        
    else
        echo "❌ Data submission failed"
        echo "Response: $submit_response"
    fi
    
    echo ""
}

# Test each survey
for survey_name in "Initial Survey" "Biweekly Survey" "Consent Survey"; do
    survey_id="${SURVEYS[$survey_name]}"
    test_survey_structure "$survey_name" "$survey_id"
done

echo "=== Test Complete ==="
