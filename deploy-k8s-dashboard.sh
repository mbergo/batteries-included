#!/bin/bash

echo "Deploying Kubernetes Dashboard..."

# Deploy Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Wait for dashboard to be ready
echo "Waiting for dashboard to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/kubernetes-dashboard -n kubernetes-dashboard

# Create a LoadBalancer service for external access
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard-lb
  namespace: kubernetes-dashboard
spec:
  type: LoadBalancer
  selector:
    k8s-app: kubernetes-dashboard
  ports:
    - port: 443
      targetPort: 8443
      protocol: TCP
EOF

echo "Getting dashboard token..."
# Get token for admin user
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=24h)

echo "Waiting for LoadBalancer IP..."
sleep 30

# Get the external IP
EXTERNAL_IP=$(kubectl get svc kubernetes-dashboard-lb -n kubernetes-dashboard -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "================================"
echo "Kubernetes Dashboard deployed!"
echo "================================"
echo ""
echo "Access Methods:"
echo ""
echo "1. Via LoadBalancer (may show certificate warning):"
echo "   https://$EXTERNAL_IP"
echo ""
echo "2. Via kubectl proxy (more secure):"
echo "   kubectl proxy"
echo "   Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "Login Token:"
echo "$TOKEN"
echo ""
echo "================================"
echo "Save this token securely!"
echo "================================"