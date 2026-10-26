# Azure AI Gateway

Azure API Management and Azure OpenAI infrastructure for a multi-region AI
gateway. This repository contains deployment templates and API policies only;
presentation generators, slides, screenshots, and generated files are excluded.

## Architecture

- API Management Standard v2 with a system-assigned managed identity.
- Azure OpenAI accounts in UAE North and East US 2, with local key authentication
  disabled and the Cognitive Services OpenAI User role assigned to the gateway.
- A language-model backend pool with primary/secondary priorities and a
  circuit breaker for HTTP 429 responses.
- A language-model policy with a 100,000-token-per-minute limit, keyed by
  `x-pipeline-id` or the caller IP address.
- An image API with a five-request-per-minute limit and placeholder backend URLs.
  Image model deployment is intentionally not included.

## Files

| File | Purpose |
| --- | --- |
| [main.bicep](main.bicep) | Complete infrastructure deployment |
| [deploy.sh](deploy.sh) | Azure CLI deployment entry point |
| [apim-backend-pool.bicep](apim-backend-pool.bicep) | Text backend pool for an existing APIM service |
| [apim-image-api.bicep](apim-image-api.bicep) | Image API and backend pool for an existing APIM service |
| [apim-image-backend-pool.bicep](apim-image-backend-pool.bicep) | Standalone image backend pool |
| [apim-policy.xml](apim-policy.xml) | Text API authentication, throttling, and routing |
| [apim-image-policy.xml](apim-image-policy.xml) | Image API authentication, throttling, and routing |
| [apim-load-balancing-policy.xml](apim-load-balancing-policy.xml) | Routing-only text API policy |

## Prerequisites

- Azure CLI with Bicep available, and Bash (for example, Git Bash or WSL on Windows).
- An authenticated Azure subscription with permission to create resources and
  role assignments.
- Azure OpenAI quota and access to the selected model/version in both regions.

The template retains its existing model defaults: `gpt-5.6-terra`, version
`2026-07-09`, deployment `gpt-5-6-terra`. Confirm availability in your subscription
before deployment; template compilation does not validate regional model access.

## Deploy to Azure

Running these commands creates billable Azure resources. Publishing this
repository to GitHub does not deploy Azure resources.

From Bash in the repository directory:

```bash
az login
export AZURE_SUBSCRIPTION_ID="<subscription-id>"
export RESOURCE_GROUP="rg-ai-gateway"
export RESOURCE_SUFFIX="<unique-suffix>"
export PUBLISHER_EMAIL="<publisher-email>"
bash deploy.sh
```

The subscription defaults to the active Azure CLI subscription. The resource
suffix defaults to its first eight characters, and the publisher email defaults
to the signed-in Azure CLI user name. Set `PUBLISHER_EMAIL` explicitly when that
user name is not an email address. Use a unique suffix to avoid global name
collisions.

To customize model parameters or regions, deploy the template directly:

```bash
az group create --name rg-ai-gateway --location eastus2
az deployment group create \
  --name ai-gateway \
  --resource-group rg-ai-gateway \
  --template-file main.bicep \
  --parameters \
    apimName="apim-ai-gw-<unique-suffix>" \
    primaryOpenAIName="aoai-uae-<unique-suffix>" \
    secondaryOpenAIName="aoai-eus2-<unique-suffix>" \
    publisherEmail="<publisher-email>" \
    modelName="<available-model>" \
    modelVersion="<available-version>" \
    deploymentName="<deployment-name>"
```

## API routes

- Text: `POST https://<apim-name>.azure-api.net/ai/chat/completions`
- Images: `POST https://<apim-name>.azure-api.net/images/generations`

Both APIs require an APIM subscription key. Azure OpenAI requests also require an
appropriate `api-version` query parameter. The image route is configuration-only
until real backend URLs and the required managed-identity role assignments on the
target accounts are configured. Supply the URLs via `imagePrimaryBackendUrl` and
`imageSecondaryBackendUrl` when deploying the main template.

## Local validation

Compile without writing generated JSON files:

```bash
az bicep build --file main.bicep --stdout > /dev/null
az bicep build --file apim-backend-pool.bicep --stdout > /dev/null
az bicep build --file apim-image-api.bicep --stdout > /dev/null
az bicep build --file apim-image-backend-pool.bicep --stdout > /dev/null
bash -n deploy.sh
```

Keep credentials, local parameter files, and generated artifacts out of commits.
