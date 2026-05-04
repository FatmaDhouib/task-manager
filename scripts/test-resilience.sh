#!/bin/bash
# scripts/test-resilience.sh

echo "=== Task Manager Resilience Test ==="

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test 1: API Health Check
echo "Test 1: API Health Check..."
kubectl run health-test --image=curlimages/curl -it --rm --restart=Never -n task-manager -- \
  curl -s -o /dev/null -w "%{http_code}" http://backend-service:3000/health | grep -q "200"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend health check passed${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
fi

# Test 2: Database Connectivity
echo "Test 2: Database Connectivity..."
kubectl exec -it deployment/backend -n task-manager -- node -e "
  const { Client } = require('pg');
  const client = new Client({
    host: 'postgres-service',
    port: 5432,
    user: 'taskmanager',
    password: 'StrongPassword123!',
    database: 'taskmanager'
  });
  client.connect()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
fi

# Test 3: Create Task via API
echo "Test 3: Creating Task via API..."
kubectl run create-test --image=curlimages/curl -it --rm --restart=Never -n task-manager -- \
  curl -X POST http://backend-service:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Resilience Test","description":"Testing pod deletion","status":"pending"}' \
  | grep -q "title"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Task creation successful${NC}"
else
    echo -e "${RED}✗ Task creation failed${NC}"
fi

# Test 4: Pod Deletion Resilience
echo "Test 4: Testing Pod Deletion Resilience..."
BACKEND_POD=$(kubectl get pods -n task-manager -l app=backend -o name | head -1)
kubectl delete $BACKEND_POD -n task-manager
sleep 10
NEW_BACKEND=$(kubectl get pods -n task-manager -l app=backend -o name | wc -l)

if [ $NEW_BACKEND -eq 2 ]; then
    echo -e "${GREEN}✓ Backend pod auto-recovered${NC}"
else
    echo -e "${RED}✗ Backend pod recovery failed${NC}"
fi

# Test 5: Data Persistence
echo "Test 5: Testing Data Persistence..."
kubectl delete pod -l app=postgres -n task-manager
sleep 30
kubectl wait --for=condition=ready pod -l app=postgres -n task-manager --timeout=60s

kubectl run data-test --image=curlimages/curl -it --rm --restart=Never -n task-manager -- \
  curl -s http://backend-service:3000/api/tasks | grep -q "Resilience Test"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Data persisted after PostgreSQL restart${NC}"
else
    echo -e "${RED}✗ Data persistence failed${NC}"
fi

echo "=== Resilience Test Complete ==="