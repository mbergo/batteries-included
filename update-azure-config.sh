#!/bin/bash

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Gather all Azure resource information
print_status "Gathering Azure resource information..."

export RESOURCE_GROUP="batteries-included-rg"
export CLUSTER_NAME="batteries-included-aks"
export LOCATION="eastus"
export STORAGE_ACCOUNT="battinc26191"
export CONTAINER_NAME="batteries-backups"
export ACR_NAME="battincacr26191"

# Get subscription and tenant IDs
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TENANT_ID=$(az account show --query tenantId -o tsv)

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

# Get workload identity details
export WORKLOAD_CLIENT_ID=$(az identity show \
    --name batteries-included-aks-workload-identity \
    --resource-group $RESOURCE_GROUP \
    --query clientId -o tsv)

export WORKLOAD_OBJECT_ID=$(az identity show \
    --name batteries-included-aks-workload-identity \
    --resource-group $RESOURCE_GROUP \
    --query principalId -o tsv)

# Get VNet and subnet details
export VNET_NAME="batteries-vnet"
export SUBNET_NAME="batteries-subnet"

print_status "Resource Information:"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Tenant ID: $TENANT_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Location: $LOCATION"
echo "  Node Resource Group: $NODE_RESOURCE_GROUP"
echo "  Kubelet Identity ID: $KUBELET_IDENTITY_ID"
echo "  Workload Client ID: $WORKLOAD_CLIENT_ID"
echo "  OIDC Issuer: $OIDC_ISSUER"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container Name: $CONTAINER_NAME"
echo "  ACR Name: $ACR_NAME"

# Backup original files
print_status "Backing up original configuration files..."
cp bootstrap/azure-dev.spec.json bootstrap/azure-dev.spec.json.backup 2>/dev/null || true
cp bootstrap/azure-dev.install.json bootstrap/azure-dev.install.json.backup 2>/dev/null || true

# Generate secure passwords and keys
print_status "Generating secure credentials..."
CONTROL_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
LOCAL_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
JWK_D=$(openssl rand -base64 32 | tr -d '\n')
JWK_X=$(openssl rand -base64 32 | tr -d '\n' | head -c 43)
JWK_Y=$(openssl rand -base64 32 | tr -d '\n' | head -c 43)
INSTALL_ID=$(uuidgen)
HASH=$(date +%s | sha256sum | head -c 16)

# Create updated spec.json
print_status "Creating updated azure-dev.spec.json..."
cat > bootstrap/azure-dev.spec.json <<EOF
{
  "initial_resources": {
    "/namespace/battery_core": {
      "apiVersion": "v1",
      "kind": "Namespace",
      "metadata": {
        "annotations": {
          "battery/hash": "$HASH"
        },
        "labels": {
          "app": "battery-core",
          "app.kubernetes.io/managed-by": "batteries-included",
          "app.kubernetes.io/name": "battery-core",
          "app.kubernetes.io/version": "latest",
          "battery/app": "battery-core",
          "battery/managed": "true",
          "battery/managed.direct": "true",
          "battery/owner": "batt_azure_dev_battery_core_id",
          "istio-injection": "disabled",
          "istio.io/dataplane-mode": "ambient",
          "version": "latest"
        },
        "name": "battery-core"
      }
    }
  },
  "kube_cluster": {
    "config": {
      "resource_group": "$RESOURCE_GROUP",
      "cluster_name": "$CLUSTER_NAME",
      "location": "$LOCATION",
      "subscription_id": "$SUBSCRIPTION_ID",
      "tenant_id": "$TENANT_ID"
    },
    "provider": "azure"
  },
  "slug": "azure-dev",
  "target_summary": {
    "batteries": [
      {
        "config": {
          "type": "gateway_api"
        },
        "group": "net_sec",
        "id": "batt_azure_dev_gateway_api_id",
        "inserted_at": null,
        "type": "gateway_api",
        "updated_at": null
      },
      {
        "config": {
          "cni_image": "docker.io/istio/install-cni:1.27.0-distroless",
          "namespace": "battery-istio",
          "pilot_image": "docker.io/istio/pilot:1.27.0-distroless",
          "type": "istio",
          "ztunnel_image": "docker.io/istio/ztunnel:1.27.0-distroless"
        },
        "group": "net_sec",
        "id": "batt_azure_dev_istio_id",
        "inserted_at": null,
        "type": "istio",
        "updated_at": null
      },
      {
        "config": {
          "proxy_image": "docker.io/istio/proxyv2:1.27.0-distroless",
          "type": "istio_gateway"
        },
        "group": "net_sec",
        "id": "batt_azure_dev_istio_gateway_id",
        "inserted_at": null,
        "type": "istio_gateway",
        "updated_at": null
      },
      {
        "config": {
          "ai_namespace": "battery-ai",
          "base_namespace": "battery-base",
          "cluster_name": "$CLUSTER_NAME",
          "cluster_type": "azure",
          "control_jwk": {
            "crv": "P-256",
            "d": "$JWK_D",
            "kty": "EC",
            "x": "$JWK_X",
            "y": "$JWK_Y"
          },
          "core_namespace": "battery-core",
          "data_namespace": "battery-data",
          "default_size": "small",
          "install_id": "$INSTALL_ID",
          "type": "battery_core",
          "usage": "development"
        },
        "group": "magic",
        "id": "batt_azure_dev_battery_core_id",
        "inserted_at": null,
        "type": "battery_core",
        "updated_at": null
      },
      {
        "config": {
          "image": "mcr.microsoft.com/oss/kubernetes/azure-load-balancer-controller:v1.7.0",
          "resource_group_name": "$RESOURCE_GROUP",
          "subscription_id": "$SUBSCRIPTION_ID",
          "tenant_id": "$TENANT_ID",
          "cluster_name": "$CLUSTER_NAME",
          "location": "$LOCATION",
          "node_resource_group": "$NODE_RESOURCE_GROUP",
          "vnet_name": "$VNET_NAME",
          "subnet_name": "$SUBNET_NAME",
          "kubelet_identity_id": "$KUBELET_IDENTITY_ID",
          "type": "azure_load_balancer_controller"
        },
        "group": "magic",
        "id": "batt_azure_dev_load_balancer_controller_id",
        "inserted_at": null,
        "type": "azure_load_balancer_controller",
        "updated_at": null
      },
      {
        "config": {
          "image": "mcr.microsoft.com/oss/azure/karpenter/karpenter:v0.37.0",
          "subscription_id": "$SUBSCRIPTION_ID",
          "resource_group_name": "$RESOURCE_GROUP",
          "location": "$LOCATION",
          "tenant_id": "$TENANT_ID",
          "client_id": "$WORKLOAD_CLIENT_ID",
          "cluster_name": "$CLUSTER_NAME",
          "node_resource_group": "$NODE_RESOURCE_GROUP",
          "instance_types": ["Standard_D2s_v3", "Standard_D4s_v3"],
          "type": "azure_karpenter"
        },
        "group": "magic",
        "id": "batt_azure_dev_karpenter_id",
        "inserted_at": null,
        "type": "azure_karpenter",
        "updated_at": null
      },
      {
        "config": {
          "storage_account_name": "$STORAGE_ACCOUNT",
          "container_name": "$CONTAINER_NAME",
          "default_postgres_image": "ghcr.io/batteries-included/postgresql:17.6",
          "image": "ghcr.io/cloudnative-pg/cloudnative-pg:1.27.0",
          "type": "cloudnative_pg"
        },
        "group": "data",
        "id": "batt_azure_dev_cloudnative_pg_id",
        "inserted_at": null,
        "type": "cloudnative_pg",
        "updated_at": null
      }
    ],
    "postgres_clusters": [
      {
        "backup_config": {
          "type": "object_store",
          "storage_account_name": "$STORAGE_ACCOUNT",
          "container_name": "$CONTAINER_NAME"
        },
        "cpu_limits": 1000,
        "cpu_requested": 1000,
        "database": {
          "name": "control",
          "owner": "battery-control-user"
        },
        "memory_limits": 1073741824,
        "memory_requested": 1073741824,
        "name": "controlserver",
        "num_instances": 1,
        "password_versions": [
          {
            "password": "$CONTROL_PASSWORD",
            "username": "battery-control-user",
            "version": 2
          },
          {
            "password": "$LOCAL_PASSWORD",
            "username": "battery-local-user",
            "version": 1
          }
        ],
        "storage_size": 10737418240,
        "type": "internal",
        "users": [
          {
            "credential_namespaces": [],
            "roles": ["superuser", "createrole", "createdb", "login"],
            "username": "battery-local-user"
          },
          {
            "credential_namespaces": ["battery-core"],
            "roles": ["createdb", "login"],
            "username": "battery-control-user"
          }
        ],
        "virtual_size": "small"
      }
    ],
    "ferret_services": [],
    "install_status": null,
    "ip_address_pools": [],
    "knative_services": [],
    "model_instances": [],
    "notebooks": [],
    "projects": [],
    "redis_instances": [],
    "stable_versions_report": null,
    "traditional_services": []
  }
}
EOF

# Create updated install.json
print_status "Creating updated azure-dev.install.json..."
cat > bootstrap/azure-dev.install.json <<EOF
{
  "control_jwk": {
    "crv": "P-256",
    "d": "$JWK_D",
    "kty": "EC",
    "x": "$JWK_X",
    "y": "$JWK_Y"
  },
  "default_size": "small",
  "deleted_at": null,
  "id": "$INSTALL_ID",
  "inserted_at": null,
  "kube_provider": "azure",
  "kube_provider_config": {
    "resource_group": "$RESOURCE_GROUP",
    "cluster_name": "$CLUSTER_NAME",
    "location": "$LOCATION",
    "subscription_id": "$SUBSCRIPTION_ID",
    "tenant_id": "$TENANT_ID"
  },
  "slug": "azure-dev",
  "team_id": "batt_0198f3777ee67f649fe3819852d4ea20",
  "updated_at": null,
  "usage": "development",
  "user_id": null
}
EOF

# Save credentials to a secure file
print_status "Saving credentials..."
cat > azure-credentials.txt <<EOF
Azure Deployment Credentials
============================
Resource Group: $RESOURCE_GROUP
Cluster Name: $CLUSTER_NAME
Location: $LOCATION

Database Credentials:
Control User Password: $CONTROL_PASSWORD
Local User Password: $LOCAL_PASSWORD

Azure Resources:
Subscription ID: $SUBSCRIPTION_ID
Tenant ID: $TENANT_ID
Storage Account: $STORAGE_ACCOUNT
Container Name: $CONTAINER_NAME
ACR Name: $ACR_NAME

Identities:
Kubelet Identity ID: $KUBELET_IDENTITY_ID
Workload Client ID: $WORKLOAD_CLIENT_ID

Install ID: $INSTALL_ID
EOF

chmod 600 azure-credentials.txt

print_status "Configuration files updated successfully!"
print_status "Credentials saved to azure-credentials.txt (keep this secure!)"
print_status "Original files backed up with .backup extension"