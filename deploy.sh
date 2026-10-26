#!/usr/bin/env bash
set -euo pipefail

subscription_id="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
resource_group="${RESOURCE_GROUP:-rg-ai-gateway}"
suffix="${RESOURCE_SUFFIX:-${subscription_id:0:8}}"
publisher_email="${PUBLISHER_EMAIL:-$(az account show --query user.name -o tsv)}"

az account set --subscription "$subscription_id"
az group create \
  --name "$resource_group" \
  --location eastus2 \
  --output table

az deployment group create \
  --name ai-gateway \
  --resource-group "$resource_group" \
  --template-file main.bicep \
  --parameters \
    apimName="apim-ai-gw-$suffix" \
    primaryOpenAIName="aoai-uae-$suffix" \
    secondaryOpenAIName="aoai-eus2-$suffix" \
    publisherEmail="$publisher_email" \
  --output json

az deployment group show \
  --name ai-gateway \
  --resource-group "$resource_group" \
  --query properties.outputs \
  --output json
