#!/bin/bash

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying Batteries Dashboard to Azure AKS${NC}"

# Variables
ACR_NAME="battincacr26191"
RESOURCE_GROUP="batteries-included-rg"
CLUSTER_NAME="batteries-included-aks"
IMAGE_NAME="batteries-dashboard"
IMAGE_TAG="latest"

# Step 1: Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
cd /home/mbergo/github/batteries-included/batteries-dashboard
npm install

# Step 2: Build Next.js app
echo -e "${YELLOW}🔨 Building Next.js application...${NC}"
npm run build

# Step 3: Build Docker image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Step 4: Tag image for ACR
echo -e "${YELLOW}🏷️  Tagging image for Azure Container Registry...${NC}"
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

# Step 5: Login to ACR
echo -e "${YELLOW}🔐 Logging in to Azure Container Registry...${NC}"
az acr login --name ${ACR_NAME}

# Step 6: Push image to ACR
echo -e "${YELLOW}📤 Pushing image to ACR...${NC}"
docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

# Step 7: Get AKS credentials
echo -e "${YELLOW}🔑 Getting AKS credentials...${NC}"
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

# Step 8: Deploy to Kubernetes
echo -e "${YELLOW}☸️  Deploying to Kubernetes...${NC}"
kubectl apply -f k8s-deployment.yaml

# Step 9: Wait for deployment
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/batteries-dashboard -n battery-core --timeout=300s

# Step 10: Get the external IP
echo -e "${YELLOW}🌐 Getting external IP address...${NC}"
echo "Waiting for LoadBalancer IP..."
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc batteries-dashboard -n battery-core -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ ! -z "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 5
done

echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "================================"
echo -e "🎉 ${GREEN}Batteries Dashboard is live!${NC}"
echo "================================"
echo ""
echo -e "🌐 Dashboard URL: ${GREEN}http://${EXTERNAL_IP}${NC}"
echo -e "📊 Cluster: ${CLUSTER_NAME}"
echo -e "📍 Region: East US"
echo -e "🐳 Image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "================================"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  kubectl get pods -n battery-core"
echo "  kubectl logs -n battery-core -l app=batteries-dashboard"
echo "  kubectl describe svc batteries-dashboard -n battery-core"
echo ""