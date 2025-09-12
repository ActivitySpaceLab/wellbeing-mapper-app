#!/bin/bash

echo "=== COMPREHENSIVE QUALTRICS API DIAGNOSIS ==="
echo ""

# Check if QUALTRICS_API_TOKEN is set
if [ -z "$QUALTRICS_API_TOKEN" ]; then
    echo "❌ Error: QUALTRICS_API_TOKEN environment variable not set"
    echo "Please set it with: export QUALTRICS_API_TOKEN=your_token_here"
    exit 1
fi

QUALTRICS_TOKEN="$QUALTRICS_API_TOKEN"
QUALTRICS_URL="https://pretoria.eu.qualtrics.com"
SURVEY_ID="SV_8pudN8qTI6iQKY6"

echo "1. Testing different API formats..."

# Test 1: Basic format we've been using
echo "Test 1: Basic values format"
response1=$(curl -s -X POST "$QUALTRICS_URL/API/v3/surveys/$SURVEY_ID/responses" \
    -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"values":{"QID1":"TEST1","QID3":"25"}}')

echo "  Response: $response1"
rid1=$(echo "$response1" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('responseId', 'NONE'))" 2>/dev/null)
echo "  Response ID: $rid1"

# Test 2: With finished flag
echo ""
echo "Test 2: With finished=true flag"
response2=$(curl -s -X POST "$QUALTRICS_URL/API/v3/surveys/$SURVEY_ID/responses" \
    -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"values":{"QID1":"TEST2","QID3":"26"},"finished":true}')

echo "  Response: $response2"
rid2=$(echo "$response2" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('responseId', 'NONE'))" 2>/dev/null)
echo "  Response ID: $rid2"

# Test 3: With status field 
echo ""
echo "Test 3: With status=0 (complete)"
response3=$(curl -s -X POST "$QUALTRICS_URL/API/v3/surveys/$SURVEY_ID/responses" \
    -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"values":{"QID1":"TEST3","QID3":"27"},"status":0}')

echo "  Response: $response3"
rid3=$(echo "$response3" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('responseId', 'NONE'))" 2>/dev/null)
echo "  Response ID: $rid3"

echo ""
echo "2. Waiting 5 seconds for processing..."
sleep 5

echo ""
echo "3. Checking data visibility for each test..."

check_response() {
    local test_name="$1"
    local response_id="$2"
    
    if [ "$response_id" != "NONE" ] && [ -n "$response_id" ]; then
        echo "Checking $test_name (ID: $response_id):"
        
        data=$(curl -s -X GET "$QUALTRICS_URL/API/v3/surveys/$SURVEY_ID/responses/$response_id" \
            -H "X-API-TOKEN: $QUALTRICS_TOKEN" \
            -H "Content-Type: application/json")
        
        # Check for specific QID values
        qid1=$(echo "$data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('values', {}).get('QID1', 'NOT_FOUND'))" 2>/dev/null)
        qid3=$(echo "$data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('values', {}).get('QID3', 'NOT_FOUND'))" 2>/dev/null)
        
        echo "  QID1: $qid1"
        echo "  QID3: $qid3"
        
        if [ "$qid1" != "NOT_FOUND" ] || [ "$qid3" != "NOT_FOUND" ]; then
            echo "  ✅ DATA VISIBLE!"
        else
            echo "  ❌ Data not visible"
        fi
    else
        echo "Skipping $test_name - no valid response ID"
    fi
    echo ""
}

check_response "Test 1 (Basic)" "$rid1"
check_response "Test 2 (Finished)" "$rid2" 
check_response "Test 3 (Status)" "$rid3"

echo "=== END OF DIAGNOSIS ==="
