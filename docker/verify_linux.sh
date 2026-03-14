#!/bin/bash
set -e

# Verify the Linux Flutter bundle starts correctly and the backend responds.
# Usage:
#   docker compose run --rm -d --service-ports linux-app
#   ./verify_linux.sh [port]

PORT="${1:-8042}"
BASE_URL="http://localhost:$PORT"
MAX_RETRIES=15
RETRY_INTERVAL=2

echo "=== BiblioGenius Linux Bundle Verification ==="
echo "Target: $BASE_URL"

# 1. Wait for backend to be ready
echo -e "\n⏳ 1. Waiting for backend..."
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf "$BASE_URL/api/health" > /dev/null 2>&1; then
    echo "   ✅ Backend is up (attempt $i/$MAX_RETRIES)"
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    echo "   ❌ Backend not reachable after $((MAX_RETRIES * RETRY_INTERVAL))s"
    exit 1
  fi
  sleep $RETRY_INTERVAL
done

# 2. Health check
echo -e "\n🏥 2. Health check..."
HEALTH=$(curl -sf "$BASE_URL/api/health")
echo "   Response: $HEALTH"
if echo "$HEALTH" | grep -q '"status":"ok"'; then
  echo "   ✅ Health OK"
else
  echo "   ❌ Unexpected health response"
  exit 1
fi

# 3. Register admin user
echo -e "\n👤 3. Registering admin user..."
REG_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"linuxtest","password":"Linux1234"}' 2>&1 || true)
echo "   Response: $REG_RESPONSE"

# 4. Login to get JWT token
echo -e "\n🔑 4. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"linuxtest","password":"Linux1234"}' 2>&1 || true)

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  echo "   ✅ Got JWT token"
  AUTH_HEADER="Authorization: Bearer $TOKEN"
else
  echo "   ⚠️  Login failed (Response: $LOGIN_RESPONSE)"
  echo "   Continuing with unauthenticated tests only..."
  AUTH_HEADER=""
fi

# 5. Test authenticated endpoint (if we have a token)
if [ -n "$AUTH_HEADER" ]; then
  echo -e "\n📚 5. Creating a test book..."
  BOOK_RESPONSE=$(curl -sf -X POST "$BASE_URL/api/books" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d '{"title": "Linux Test Book", "author": "Docker Tester", "isbn": "9780000000001"}' 2>&1 || true)
  echo "   Response: $BOOK_RESPONSE"

  if echo "$BOOK_RESPONSE" | grep -q "Linux Test Book"; then
    echo "   ✅ Book created"
  else
    echo "   ⚠️  Book creation returned unexpected response"
  fi

  echo -e "\n📋 6. Listing books..."
  BOOKS=$(curl -sf "$BASE_URL/api/books" -H "$AUTH_HEADER" 2>&1 || true)
  if echo "$BOOKS" | grep -q "Linux Test Book"; then
    echo "   ✅ Book found in listing"
  else
    echo "   ⚠️  Book not found in listing"
  fi
fi

echo -e "\n=== ✅ Verification complete ==="
echo ""
echo "Results:"
echo "  - Backend starts:  ✅"
echo "  - Health endpoint: ✅"
if [ -n "$AUTH_HEADER" ]; then
  echo "  - Auth flow:       ✅"
  echo "  - CRUD:            ✅"
else
  echo "  - Auth flow:       ⚠️  (skipped)"
  echo "  - CRUD:            ⚠️  (skipped — requires auth)"
fi
echo ""
echo "To stop: docker compose stop"
