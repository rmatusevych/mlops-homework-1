#!/bin/bash
set -e

PROJECT_ID=${1:-1}  # Default project ID is 1
OUTPUT_FILE="dataset/yolo_export.zip"  # Default output filename

if [ -z "$REFRESH_TOKEN" ]; then
  echo "Error: REFRESH_TOKEN environment variable is not set."
  echo "Usage: export REFRESH_TOKEN=your_token"
  echo "Then run: ./export_yolo.sh [project_id]"
  exit 1
fi

# Create dataset directory if it doesn't exist
mkdir -p dataset

echo "Getting access token..."
# Get the full response first for debugging
TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/token/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh\": \"$REFRESH_TOKEN\"}")

echo "Token response: $TOKEN_RESPONSE"

# Extract access token using a more robust method
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access":"[^"]*"' | cut -d'"' -f4)

# Alternative extraction methods if the above doesn't work:
# ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | sed -n 's/.*"access":"\([^"]*\)".*/\1/p')
# Or if you have jq installed:
# ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to get access token."
  echo "Token response was: $TOKEN_RESPONSE"
  echo "Check your refresh token and Label Studio availability."
  exit 1
fi

echo "Access token obtained successfully."
echo "Exporting data from project #${PROJECT_ID} in YOLO format..."

# Use curl without -s to see any error messages
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "http://localhost:8080/api/projects/$PROJECT_ID/export?exportType=YOLO" \
  -o "$OUTPUT_FILE"

if [ -s "$OUTPUT_FILE" ]; then
  echo "Export successful! File saved as $OUTPUT_FILE"
  echo "File size: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
else
  echo "Error: Export failed or no data was exported."
  echo "Check if the file exists: $(ls -la "$OUTPUT_FILE" 2>/dev/null || echo 'File does not exist')"
  exit 1
fi

echo "Done. You can now use the exported data for your YOLO model training." 
