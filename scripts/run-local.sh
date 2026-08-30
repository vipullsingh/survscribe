#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BACKEND_DIR="$PROJECT_ROOT/apps/backend"
MOBILE_DIR="$PROJECT_ROOT/apps/mobile"

echo "================================================"
echo "   SurvScribe Local Development Environment     "
echo "================================================"

# 1. Detect & Check PostgreSQL
echo -e "\n[1/3] Checking PostgreSQL Database..."
DB_URL=""
if nc -z 127.0.0.1 5432 2>/dev/null; then
  DB_URL="postgres://survscribe:devpassword@localhost:5432/survscribe_dev?sslmode=disable"
  echo "Local PostgreSQL active on port 5432."
elif nc -z 127.0.0.1 5433 2>/dev/null; then
  DB_URL="postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
  echo "Docker PostgreSQL active on port 5433."
elif command -v docker &> /dev/null; then
  echo "Starting Docker PostgreSQL container..."
  docker compose -f "$BACKEND_DIR/deployments/docker-compose.yml" up -d 2>/dev/null || true
  sleep 2
  if nc -z 127.0.0.1 5433 2>/dev/null; then
    DB_URL="postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
    echo "PostgreSQL container started on port 5433."
  fi
fi

if [ -z "$DB_URL" ]; then
  DB_URL="postgres://survscribe:devpassword@localhost:5432/survscribe_dev?sslmode=disable"
  echo "Note: PostgreSQL is not responding. Backend will run in offline standalone mode."
fi

# 2. Restart Go Backend API Server (kill previous instance if listening on 8080)
echo -e "\n[2/3] Restarting Go Backend Server (http://localhost:8080)..."
if lsof -ti:8080 >/dev/null 2>&1; then
  echo "Stopping previous backend process on port 8080..."
  kill -9 $(lsof -ti:8080) 2>/dev/null || true
  sleep 1
fi

if command -v go &> /dev/null; then
  export DATABASE_URL="$DB_URL"
  export SURVSCRIBE_ENV="development"
  export LOG_LEVEL="debug"
  export LOG_FORMAT="text"
  export HTTP_ADDR=":8080"
  
  (cd "$BACKEND_DIR" && go run ./cmd/api) &
  BACKEND_PID=$!
  trap "kill $BACKEND_PID 2>/dev/null || true" EXIT
  echo "Backend running fresh (PID: $BACKEND_PID)."
  sleep 1
else
  echo "Warning: 'go' is not installed in PATH."
fi

# 3. Start Mobile Expo Dev Server
echo -e "\n[3/3] Starting Mobile Expo Dev Server..."
cd "$MOBILE_DIR"
npx expo start "$@"
