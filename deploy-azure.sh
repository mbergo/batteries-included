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

# Check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first:"
        echo "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        exit 1
    fi
    print_status "Azure CLI is installed"
}

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first:"
        echo "az aks install-cli"
        exit 1
    fi
    print_status "kubectl is installed"
}

# Login to Azure
login_azure() {
    print_status "Checking Azure login status..."
    if ! az account show &> /dev/null; then
        print_status "Please login to Azure..."
        az login
    else
        print_status "Already logged in to Azure"
    fi
}

# Register required Azure providers
register_providers() {
    print_status "Registering required Azure providers..."
    
    providers=("Microsoft.ContainerService" "Microsoft.Storage" "Microsoft.Network" "Microsoft.ManagedIdentity" "Microsoft.ContainerRegistry" "Microsoft.Authorization")
    
    for provider in "${providers[@]}"; do
        print_status "Registering $provider..."
        az provider register --namespace $provider --wait &
    done
    
    wait
    print_status "All providers registered successfully"
}

# Set variables
set_variables() {
    print_status "Setting up deployment variables..."
    
    # You can modify these variables according to your needs
    export RESOURCE_GROUP="${RESOURCE_GROUP:-batteries-included-rg}"
    export LOCATION="${LOCATION:-eastus}"
    export CLUSTER_NAME="${CLUSTER_NAME:-batteries-included-aks}"
    export NODE_COUNT="${NODE_COUNT:-3}"
    export NODE_SIZE="${NODE_SIZE:-Standard_D4s_v3}"
    # Generate shorter names that comply with Azure naming requirements
    RANDOM_SUFFIX=$(date +%s | tail -c 6)
    export STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-battinc${RANDOM_SUFFIX}}"
    export CONTAINER_NAME="${CONTAINER_NAME:-batteries-backups}"
    export ACR_NAME="${ACR_NAME:-battincacr${RANDOM_SUFFIX}}"
    export VNET_NAME="${VNET_NAME:-batteries-vnet}"
    export SUBNET_NAME="${SUBNET_NAME:-batteries-subnet}"
    export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    export TENANT_ID=$(az account show --query tenantId -o tsv)
    
    print_status "Configuration:"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Location: $LOCATION"
    echo "  Cluster Name: $CLUSTER_NAME"
    echo "  Node Count: $NODE_COUNT"
    echo "  Node Size: $NODE_SIZE"
    echo "  Storage Account: $STORAGE_ACCOUNT"
    echo "  Container Registry: $ACR_NAME"
}

# Create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP..."
    if az group show --name $RESOURCE_GROUP &> /dev/null; then
        print_warning "Resource group $RESOURCE_GROUP already exists"
    else
        az group create --name $RESOURCE_GROUP --location $LOCATION
        print_status "Resource group created successfully"
    fi
}

# Create storage account and container for backups
create_storage_account() {
    print_status "Creating storage account: $STORAGE_ACCOUNT..."
    if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT already exists"
    else
        az storage account create \
            --name $STORAGE_ACCOUNT \
            --resource-group $RESOURCE_GROUP \
            --location $LOCATION \
            --sku Standard_LRS \
            --kind StorageV2
        print_status "Storage account created successfully"
    fi
    
    # Get storage account key
    export STORAGE_KEY=$(az storage account keys list \
        --resource-group $RESOURCE_GROUP \
        --account-name $STORAGE_ACCOUNT \
        --query '[0].value' -o tsv)
    
    # Create container
    print_status "Creating storage container: $CONTAINER_NAME..."
    if az storage container exists --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --query exists -o tsv | grep -q true; then
        print_warning "Container $CONTAINER_NAME already exists"
    else
        az storage container create \
            --name $CONTAINER_NAME \
            --account-name $STORAGE_ACCOUNT \
            --account-key $STORAGE_KEY
        print_status "Storage container created successfully"
    fi
}

# Create Azure Container Registry
create_acr() {
    print_status "Creating Azure Container Registry: $ACR_NAME..."
    if az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "ACR $ACR_NAME already exists"
    else
        az acr create \
            --resource-group $RESOURCE_GROUP \
            --name $ACR_NAME \
            --sku Basic \
            --location $LOCATION
        print_status "ACR created successfully"
    fi
}

# Create Virtual Network
create_vnet() {
    print_status "Creating Virtual Network: $VNET_NAME..."
    if az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "VNet $VNET_NAME already exists"
    else
        az network vnet create \
            --resource-group $RESOURCE_GROUP \
            --name $VNET_NAME \
            --address-prefix 10.0.0.0/8 \
            --location $LOCATION
        print_status "VNet created successfully"
    fi
    
    print_status "Creating subnet: $SUBNET_NAME..."
    if az network vnet subnet show --name $SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "Subnet $SUBNET_NAME already exists"
    else
        az network vnet subnet create \
            --resource-group $RESOURCE_GROUP \
            --vnet-name $VNET_NAME \
            --name $SUBNET_NAME \
            --address-prefix 10.240.0.0/16
        print_status "Subnet created successfully"
    fi
}

# Create AKS cluster
create_aks_cluster() {
    print_status "Creating AKS cluster: $CLUSTER_NAME..."
    
    # Get subnet ID
    SUBNET_ID=$(az network vnet subnet show \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --name $SUBNET_NAME \
        --query id -o tsv)
    
    if az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "AKS cluster $CLUSTER_NAME already exists"
    else
        az aks create \
            --resource-group $RESOURCE_GROUP \
            --name $CLUSTER_NAME \
            --node-count $NODE_COUNT \
            --node-vm-size $NODE_SIZE \
            --enable-managed-identity \
            --network-plugin azure \
            --vnet-subnet-id $SUBNET_ID \
            --dns-service-ip 10.2.0.10 \
            --service-cidr 10.2.0.0/24 \
            --location $LOCATION \
            --generate-ssh-keys \
            --attach-acr $ACR_NAME \
            --enable-workload-identity \
            --enable-oidc-issuer
        print_status "AKS cluster created successfully"
    fi
    
    # Get credentials
    print_status "Getting AKS credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
}

# Get cluster information needed for configuration
get_cluster_info() {
    print_status "Getting cluster information..."
    
    # Get AKS cluster details
    export NODE_RESOURCE_GROUP=$(az aks show \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --query nodeResourceGroup -o tsv)
    
    export KUBELET_IDENTITY_ID=$(az aks show \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --query identityProfile.kubeletidentity.clientId -o tsv)
    
    export OIDC_ISSUER=$(az aks show \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --query oidcIssuerProfile.issuerUrl -o tsv)
    
    print_status "Cluster Information:"
    echo "  Node Resource Group: $NODE_RESOURCE_GROUP"
    echo "  Kubelet Identity ID: $KUBELET_IDENTITY_ID"
    echo "  OIDC Issuer: $OIDC_ISSUER"
}

# Create managed identity for workload identity
create_workload_identity() {
    print_status "Creating workload identity..."
    
    export WORKLOAD_IDENTITY_NAME="${CLUSTER_NAME}-workload-identity"
    
    if az identity show --name $WORKLOAD_IDENTITY_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_warning "Workload identity $WORKLOAD_IDENTITY_NAME already exists"
    else
        az identity create \
            --name $WORKLOAD_IDENTITY_NAME \
            --resource-group $RESOURCE_GROUP \
            --location $LOCATION
        print_status "Workload identity created successfully"
    fi
    
    export WORKLOAD_CLIENT_ID=$(az identity show \
        --name $WORKLOAD_IDENTITY_NAME \
        --resource-group $RESOURCE_GROUP \
        --query clientId -o tsv)
    
    export WORKLOAD_OBJECT_ID=$(az identity show \
        --name $WORKLOAD_IDENTITY_NAME \
        --resource-group $RESOURCE_GROUP \
        --query principalId -o tsv)
    
    print_status "Workload Identity Client ID: $WORKLOAD_CLIENT_ID"
}

# Assign necessary permissions
assign_permissions() {
    print_status "Assigning permissions..."
    
    # Assign Contributor role on resource group
    az role assignment create \
        --assignee $WORKLOAD_OBJECT_ID \
        --role "Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
        2>/dev/null || print_warning "Contributor role already assigned"
    
    # Assign Storage Blob Data Contributor for backup storage
    az role assignment create \
        --assignee $WORKLOAD_OBJECT_ID \
        --role "Storage Blob Data Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" \
        2>/dev/null || print_warning "Storage Blob Data Contributor role already assigned"
    
    # Assign Network Contributor for load balancer operations
    az role assignment create \
        --assignee $KUBELET_IDENTITY_ID \
        --role "Network Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
        2>/dev/null || print_warning "Network Contributor role already assigned"
    
    print_status "Permissions assigned successfully"
}

# Update configuration files with actual values
update_configuration() {
    print_status "Updating configuration files..."
    
    # Update azure-dev.spec.json
    cp bootstrap/azure-dev.spec.json bootstrap/azure-dev.spec.json.bak
    
    # Use sed to replace placeholders
    sed -i "s/AZURE_SUBSCRIPTION_ID_PLACEHOLDER/$SUBSCRIPTION_ID/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_TENANT_ID_PLACEHOLDER/$TENANT_ID/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_RESOURCE_GROUP_PLACEHOLDER/$RESOURCE_GROUP/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_LOCATION_PLACEHOLDER/$LOCATION/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_NODE_RESOURCE_GROUP_PLACEHOLDER/$NODE_RESOURCE_GROUP/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_VNET_NAME_PLACEHOLDER/$VNET_NAME/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_SUBNET_NAME_PLACEHOLDER/$SUBNET_NAME/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_KUBELET_IDENTITY_ID_PLACEHOLDER/$KUBELET_IDENTITY_ID/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_CLIENT_ID_PLACEHOLDER/$WORKLOAD_CLIENT_ID/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_STORAGE_ACCOUNT_PLACEHOLDER/$STORAGE_ACCOUNT/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_CONTAINER_NAME_PLACEHOLDER/$CONTAINER_NAME/g" bootstrap/azure-dev.spec.json
    
    # Generate random passwords
    CONTROL_PASSWORD=$(openssl rand -base64 32)
    LOCAL_PASSWORD=$(openssl rand -base64 32)
    
    sed -i "s/AZURE_DEV_CONTROL_PASSWORD_PLACEHOLDER/$CONTROL_PASSWORD/g" bootstrap/azure-dev.spec.json
    sed -i "s/AZURE_DEV_LOCAL_PASSWORD_PLACEHOLDER/$LOCAL_PASSWORD/g" bootstrap/azure-dev.spec.json
    
    # Generate control JWK
    print_status "Generating control JWK..."
    # This is a placeholder - in production, use proper JWK generation
    JWK_D=$(openssl rand -base64 32 | tr -d '\n')
    JWK_X=$(openssl rand -base64 32 | tr -d '\n' | head -c 43)
    JWK_Y=$(openssl rand -base64 32 | tr -d '\n' | head -c 43)
    
    sed -i "s/azure_dev_key_placeholder_replace_with_real_key/$JWK_D/g" bootstrap/azure-dev.spec.json
    sed -i "s/azure_dev_x_placeholder_replace_with_real_value/$JWK_X/g" bootstrap/azure-dev.spec.json
    sed -i "s/azure_dev_y_placeholder_replace_with_real_value/$JWK_Y/g" bootstrap/azure-dev.spec.json
    
    # Update install.json
    cp bootstrap/azure-dev.install.json bootstrap/azure-dev.install.json.bak
    sed -i "s/azure_dev_key_placeholder_replace_with_real_key/$JWK_D/g" bootstrap/azure-dev.install.json
    sed -i "s/azure_dev_x_placeholder_replace_with_real_value/$JWK_X/g" bootstrap/azure-dev.install.json
    sed -i "s/azure_dev_y_placeholder_replace_with_real_value/$JWK_Y/g" bootstrap/azure-dev.install.json
    
    # Generate install ID and hash
    INSTALL_ID=$(uuidgen)
    HASH=$(date +%s | sha256sum | head -c 16)
    
    sed -i "s/batt_azure_dev_install_id_placeholder/$INSTALL_ID/g" bootstrap/azure-dev.spec.json
    sed -i "s/batt_azure_dev_install_id_placeholder/$INSTALL_ID/g" bootstrap/azure-dev.install.json
    sed -i "s/AZURE_DEV_HASH_PLACEHOLDER/$HASH/g" bootstrap/azure-dev.spec.json
    
    print_status "Configuration files updated"
}

# Deploy Batteries Included
deploy_batteries_included() {
    print_status "Deploying Batteries Included to AKS..."
    
    # Check if bi command exists
    if ! command -v bi &> /dev/null; then
        print_status "Building bi command..."
        if [ -f "bi/bi" ]; then
            export PATH=$PATH:$(pwd)/bi
        else
            # Try to build it
            cd bi
            go build -o bi .
            cd ..
            export PATH=$PATH:$(pwd)/bi
        fi
    fi
    
    # Verify cluster connection
    print_status "Verifying cluster connection..."
    kubectl cluster-info
    
    # Deploy using bi command
    print_status "Starting Batteries Included deployment..."
    bi start bootstrap/azure-dev.spec.json
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for pods to be ready
    print_status "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -n battery-core --all --timeout=600s || true
    
    # Check pod status
    print_status "Pod status:"
    kubectl get pods --all-namespaces | grep battery
    
    # Get service endpoints
    print_status "Service endpoints:"
    kubectl get svc --all-namespaces | grep battery
    
    # Get ingress/gateway information
    print_status "Gateway information:"
    kubectl get gateway --all-namespaces 2>/dev/null || true
    kubectl get ingress --all-namespaces 2>/dev/null || true
    
    print_status "Deployment verification completed"
}

# Cleanup function
cleanup() {
    print_warning "Cleaning up Azure resources..."
    read -p "Are you sure you want to delete all resources? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        az group delete --name $RESOURCE_GROUP --yes --no-wait
        print_status "Resource group deletion initiated"
    fi
}

# Main execution
main() {
    print_status "Starting Batteries Included deployment on Azure..."
    
    # Check prerequisites
    check_azure_cli
    check_kubectl
    
    # Login and setup
    login_azure
    register_providers
    set_variables
    
    # Create Azure resources
    create_resource_group
    create_storage_account
    create_acr
    create_vnet
    create_aks_cluster
    
    # Configure cluster
    get_cluster_info
    create_workload_identity
    assign_permissions
    
    # Update and deploy
    update_configuration
    deploy_batteries_included
    
    # Verify
    verify_deployment
    
    print_status "Deployment completed successfully!"
    print_status "Access your Batteries Included dashboard at the endpoints shown above"
    print_status "Configuration files have been updated with actual Azure values"
    print_status "To cleanup resources, run: $0 cleanup"
}

# Handle cleanup command
if [[ "$1" == "cleanup" ]]; then
    cleanup
    exit 0
fi

# Run main function
main