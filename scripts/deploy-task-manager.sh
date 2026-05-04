#!/bin/bash
# deploy-task-manager.sh

echo "=== Deploying Task Manager to K3s ==="

# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Apply configmaps
kubectl apply -f k8s/configmaps/backend-config.yaml
kubectl apply -f k8s/configmaps/postgres-init.yaml

# Apply secrets
kubectl apply -f k8s/secrets/db-secrets.yaml

# Deploy database
kubectl apply -f k8s/deployments/postgres-statefulset.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 30
kubectl wait --for=condition=ready pod -l app=postgres -n task-manager --timeout=120s

# Deploy backend
kubectl apply -f k8s/deployments/backend-deployment.yaml

# Wait for backend
sleep 10
kubectl wait --for=condition=ready pod -l app=backend -n task-manager --timeout=60s

# Deploy frontend
kubectl apply -f k8s/deployments/frontend-deployment.yaml

# Wait for frontend
sleep 10
kubectl wait --for=condition=ready pod -l app=frontend -n task-manager --timeout=60s

# Apply ingress and HPA
kubectl apply -f k8s/ingress/ingress.yaml
kubectl apply -f k8s/hpa/hpa.yaml
kubectl apply -f k8s/networkpolicy/network-policy.yaml

# Run tests
./scripts/test-resilience.sh

# Get access URL
VM_IP=$(hostname -I | awk '{print $1}')

echo "========================================="
echo "✅ Task Manager Deployment Complete!"
echo "========================================="
echo "Access URL: http://$VM_IP:30080"
echo ""
echo "API Endpoints:"
echo "  GET  /api/tasks          - List all tasks"
echo "  POST /api/tasks          - Create a task"
echo "  PUT  /api/tasks/:id      - Update a task"
echo "  DELETE /api/tasks/:id    - Delete a task"
echo ""
echo "Useful Commands:"
echo "  kubectl get pods -n task-manager"
echo "  kubectl logs -f deployment/backend -n task-manager"
echo "  kubectl port-forward -n task-manager service/frontend-service 8080:80"
echo "========================================="