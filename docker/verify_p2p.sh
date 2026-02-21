#!/bin/bash
set -e

# Configuration
NODE_A_URL="http://localhost:8001"
NODE_B_URL="http://localhost:8002"

echo "🔍 Starting P2P Verification..."
echo "Node A: $NODE_A_URL"
echo "Node B: $NODE_B_URL"

# 1. Create a book on Node A
echo -e "\n📚 1. Creating book on Node A..."
BOOK_TITLE="Dune - P2P Edition $(date +%s)"
RESPONSE=$(curl -s -X POST "$NODE_A_URL/api/books" \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"$BOOK_TITLE\", \"author\": \"Frank Herbert\", \"isbn\": \"123456\", \"summary\": \"Test book\"}")

echo "Response: $RESPONSE"

# 2. Pull operations from Node A
echo -e "\n📥 2. Pulling operations from Node A..."
OPS=$(curl -s "$NODE_A_URL/api/peers/pull")
echo "Operations from A: $OPS"

# Check if OPS is not empty array
if [ "$OPS" == "[]" ]; then
  echo "❌ Error: No operations found on Node A!"
  exit 1
fi

# 3. Push operations to Node B
echo -e "\n📤 3. Pushing operations to Node B..."
# Wrap operations in the expected structure { "operations": [...] }
PAYLOAD="{\"operations\": $OPS}"
PUSH_RESPONSE=$(curl -s -X POST "$NODE_B_URL/api/peers/push" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "Push Response: $PUSH_RESPONSE"

# 4. Verify operations on Node B
echo -e "\n✅ 4. Verifying operations on Node B..."
OPS_B=$(curl -s "$NODE_B_URL/api/peers/pull")
echo "Operations on B: $OPS_B"

if [[ "$OPS_B" == *"$BOOK_TITLE"* ]]; then
  echo -e "\n🎉 SUCCESS: Book operation successfully synced to Node B!"
else
  echo -e "\n❌ FAILURE: Book operation not found on Node B."
  exit 1
fi

# 5. Verify Remote Search (Proxy)
echo -e "\n🔎 5. Verifying Remote Search (Node B -> Node A)..."

# First, connect Node B to Node A (so B knows about A)
# Internal URL for Docker container-to-container communication
NODE_A_INTERNAL_URL="http://bibliogenius-a:8000"

echo "Connecting Node B to Node A..."
CONNECT_RESPONSE=$(curl -s -X POST "$NODE_B_URL/api/peers/connect" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Node A\", \"url\": \"$NODE_A_INTERNAL_URL\"}")

PEER_ID=$(echo $CONNECT_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ -z "$PEER_ID" ]; then
    echo "⚠️  Connection failed or peer exists. Attempting to find existing peer..."
    # Fallback: Find existing peer by URL using jq
    PEER_ID=$(curl -s "$NODE_B_URL/api/peers" | jq -r ".[] | select(.url == \"$NODE_A_INTERNAL_URL\") | .id")
fi

echo "Connected/Found. Peer ID: $PEER_ID"

if [ -z "$PEER_ID" ]; then
    echo "❌ Failed to connect or find Node A"
    exit 1
fi

# Search via Proxy
echo "Searching for '$BOOK_TITLE' via Node B..."
SEARCH_RESPONSE=$(curl -s -X POST "$NODE_B_URL/api/peers/proxy_search" \
  -H "Content-Type: application/json" \
  -d "{\"peer_id\": $PEER_ID, \"query\": \"Dune\"}")

echo "Search Response: $SEARCH_RESPONSE"

if [[ "$SEARCH_RESPONSE" == *"$BOOK_TITLE"* ]]; then
  echo -e "\n🎉 SUCCESS: Remote search found the book!"
else
  echo -e "\n❌ FAILURE: Remote search did not find the book."
  exit 1
fi
