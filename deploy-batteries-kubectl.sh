#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Set configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-batteries-included-rg}"
CLUSTER_NAME="${CLUSTER_NAME:-batteries-included-aks}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-battinc26191}"
CONTAINER_NAME="${CONTAINER_NAME:-batteries-backups}"

# Get cluster credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify connection
print_status "Verifying cluster connection..."
kubectl cluster-info

# Create namespaces
print_status "Creating namespaces..."
kubectl create namespace battery-core --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace battery-base --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace battery-data --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace battery-ai --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace battery-istio --dry-run=client -o yaml | kubectl apply -f -

# Install Istio
print_status "Installing Istio..."
if ! kubectl get deployment istiod -n istio-system &> /dev/null; then
    print_status "Downloading Istio..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.27.0 sh -
    cd istio-1.27.0
    
    print_status "Installing Istio base..."
    ./bin/istioctl install --set profile=ambient -y
    cd ..
else
    print_warning "Istio already installed"
fi

# Install Gateway API CRDs
print_status "Installing Gateway API CRDs..."
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# Apply initial resources from spec.json
print_status "Creating initial battery-core namespace with labels..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: battery-core
  labels:
    app: battery-core
    app.kubernetes.io/managed-by: batteries-included
    app.kubernetes.io/name: battery-core
    app.kubernetes.io/version: latest
    battery/app: battery-core
    battery/managed: "true"
    battery/managed.direct: "true"
    istio-injection: disabled
    istio.io/dataplane-mode: ambient
    version: latest
EOF

# Create storage secret for CloudNativePG
print_status "Creating storage secret..."
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT \
    --query '[0].value' -o tsv)

kubectl create secret generic azure-storage-secret \
    --from-literal=storage-account-name=$STORAGE_ACCOUNT \
    --from-literal=storage-account-key="$STORAGE_KEY" \
    --namespace battery-data \
    --dry-run=client -o yaml | kubectl apply -f -

# Install CloudNativePG operator
print_status "Installing CloudNativePG operator..."
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.27/releases/cnpg-1.27.0.yaml

# Wait for operator to be ready
print_status "Waiting for CloudNativePG operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/cnpg-controller-manager -n cnpg-system || true

# Create PostgreSQL cluster for control server
print_status "Creating PostgreSQL cluster..."
cat <<EOF | kubectl apply -f -
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: controlserver
  namespace: battery-data
spec:
  instances: 1
  primaryUpdateStrategy: unsupervised
  
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      maintenance_work_mem: "64MB"
      checkpoint_completion_target: "0.9"
      wal_buffers: "16MB"
      default_statistics_target: "100"
      random_page_cost: "1.1"
      effective_io_concurrency: "200"
      min_wal_size: "1GB"
      max_wal_size: "4GB"
  
  bootstrap:
    initdb:
      database: control
      owner: battery-control-user
      secret:
        name: postgres-credentials
  
  storage:
    size: 10Gi
    storageClass: managed-csi
    
  monitoring:
    enabled: false
    
  resources:
    requests:
      memory: "1Gi"
      cpu: "1"
    limits:
      memory: "1Gi"
      cpu: "1"
EOF

# Create database credentials
print_status "Creating database credentials..."
CONTROL_PASSWORD=$(openssl rand -base64 32)
LOCAL_PASSWORD=$(openssl rand -base64 32)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: battery-data
type: Opaque
stringData:
  username: battery-control-user
  password: "$CONTROL_PASSWORD"
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-local-credentials
  namespace: battery-data
type: Opaque
stringData:
  username: battery-local-user
  password: "$LOCAL_PASSWORD"
EOF

# Create service account for workload identity
print_status "Creating service account for workload identity..."
kubectl create serviceaccount workload-identity-sa \
    --namespace battery-core \
    --dry-run=client -o yaml | kubectl apply -f -

# Get workload identity details
WORKLOAD_IDENTITY_NAME="${CLUSTER_NAME}-workload-identity"
WORKLOAD_CLIENT_ID=$(az identity show \
    --name $WORKLOAD_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --query clientId -o tsv 2>/dev/null || echo "pending")

if [ "$WORKLOAD_CLIENT_ID" != "pending" ]; then
    # Annotate service account with workload identity
    kubectl annotate serviceaccount workload-identity-sa \
        --namespace battery-core \
        azure.workload.identity/client-id=$WORKLOAD_CLIENT_ID \
        --overwrite
fi

# Deploy a simple control server pod for testing
print_status "Deploying test control server pod..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: control-server-config
  namespace: battery-core
data:
  config.yaml: |
    cluster_name: $CLUSTER_NAME
    cluster_type: azure
    usage: development
    default_size: small
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: control-server
  namespace: battery-core
  labels:
    app: control-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: control-server
  template:
    metadata:
      labels:
        app: control-server
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: control-server
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: CLUSTER_NAME
          value: "$CLUSTER_NAME"
        - name: CLUSTER_TYPE
          value: "azure"
        - name: STORAGE_ACCOUNT
          value: "$STORAGE_ACCOUNT"
        volumeMounts:
        - name: config
          mountPath: /etc/control-server
      volumes:
      - name: config
        configMap:
          name: control-server-config
---
apiVersion: v1
kind: Service
metadata:
  name: control-server
  namespace: battery-core
spec:
  selector:
    app: control-server
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Check deployment status
print_status "Checking deployment status..."
kubectl get pods --all-namespaces | grep battery || true
kubectl get svc --all-namespaces | grep battery || true

print_status "Basic Batteries Included components deployed!"
print_status "Note: This is a minimal deployment for testing."
print_status "The full deployment requires the 'bi' tool with proper configuration."

# Save configuration
print_status "Saving configuration..."
cat > azure-deployment-config.txt <<EOF
Resource Group: $RESOURCE_GROUP
Cluster Name: $CLUSTER_NAME
Storage Account: $STORAGE_ACCOUNT
Container Name: $CONTAINER_NAME
Control Password: $CONTROL_PASSWORD
Local Password: $LOCAL_PASSWORD
Workload Identity Client ID: $WORKLOAD_CLIENT_ID
EOF

print_status "Configuration saved to azure-deployment-config.txt"