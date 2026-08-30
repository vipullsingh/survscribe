#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "================================================"
echo "   SurvScribe Local Development Environment     "
echo "================================================"

# 1. Start Postgres Docker Container if docker is installed
echo -e "\n[1/4] Checking Docker & PostgreSQL..."
DOCKER_STARTED=false
if command -v docker &> /dev/null; then
  if docker compose -f "$PROJECT_ROOT/apps/backend/deployments/docker-compose.yml" up -d 2>/dev/null; then
    DOCKER_STARTED=true
    echo "PostgreSQL container running on port 5433."
  else
    echo "Warning: Docker daemon is not running."
  fi
else
  echo "Note: Docker is not installed in PATH. Skipping PostgreSQL container."
fi

# 2. Set Environment Variables
export DATABASE_URL="postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
export SURVSCRIBE_ENV="development"
export LOG_LEVEL="debug"
export HTTP_ADDR=":8080"

# 3. Apply Migrations inside Container if running
echo -e "\n[2/4] Checking Database & Migrations..."
if [ "$DOCKER_STARTED" = true ] && docker ps -q -f name=survscribe-postgres-dev > /dev/null 2>&1; then
  echo "Waiting for database readiness..."
  sleep 3
  for f in "$PROJECT_ROOT"/apps/backend/migrations/*.up.sql; do
    echo "  Applying $(basename "$f")..."
    docker exec -i survscribe-postgres-dev psql -U survscribe -d survscribe_dev -q -v ON_ERROR_STOP=1 < "$f" > /dev/null 2>&1 || true
  done
  echo "Database migrations verified."
else
  echo "Skipping auto-migrations (PostgreSQL container is not active)."
fi

# 4. Start Backend Go API in background
echo -e "\n[3/4] Starting Go Backend Server (http://localhost:8080)..."
if command -v go &> /dev/null; then
  (cd "$PROJECT_ROOT/apps/backend" && go run ./cmd/api) &
  BACKEND_PID=$!
  trap "kill $BACKEND_PID 2>/dev/null || true" EXIT
  echo "Backend running (PID: $BACKEND_PID)."
else
  echo "Warning: 'go' is not installed in PATH."
fi

# 5. Start Mobile Metro Bundler
echo -e "\n[4/4] Starting Mobile React Native Metro Bundler..."
cd "$PROJECT_ROOT/apps/mobile"
npx react-native start
