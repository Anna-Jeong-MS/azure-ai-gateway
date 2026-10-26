# Azure AI Gateway

English | [Korean](kr/README.md)

Create a new Azure API Management gateway for already-deployed text and image models, using the Azure portal.

## Configuration

| Item | Setting |
| --- | --- |
| APIM tier | **Standard v2**, initially one unit |
| Network | Public HTTPS; no VNet injection, VNet integration, or private endpoints |
| Models | Already-deployed `gpt-5.5` and `gpt-image-2.5-flare` |
| Text API | **Language Model API > Create OpenAI API** |
| Image API | **HTTP**, with an image-generation operation |
| Client to APIM | APIM subscription key in `Ocp-Apim-Subscription-Key` |
| APIM to model | System-assigned Managed Identity through the API inbound policy |

The text API creates one backend automatically. Reuse it as Text Primary and add Text Secondary plus two image backends: **one automatic + three manual = four single backends**.

## Steps

| Step | Tasks |
| --- | --- |
| [01. Create APIM](step-01-prepare-resources/README.md) | Record model connection details and create Standard v2 APIM |
| [02. Create APIs](step-02-create-apis/README.md) | Create the text Language Model API and image HTTP API immediately after APIM |
| [03. Configure identity and backends](step-03-backend-pools/README.md) | Enable identity, assign roles, configure backends/circuit breakers, and create pools |
| [04. Apply policies](step-04-api-policies/README.md) | Create subscriptions and apply authentication, routing, and optional limits/retries |
| [05. Test the gateway](step-05-validation/README.md) | Test calls, access controls, individual backends, and failover |

## Request paths

| API | Client-facing path |
| --- | --- |
| Text | `/text/chat/completions?api-version=<text-version>` |
| Image | `/image/deployments/<image-deployment>/images/generations?api-version=<image-version>` |

Clients send an APIM subscription key, not a model account key or managed identity token. APIM validates the key, removes it before forwarding, and obtains its own model-access token.

Replace `<...>` with actual values. Keep subscription keys, tokens, prompts, images, and unredacted traces out of Git. Resource creation and inference calls incur Azure charges.

[Start with step 01](step-01-prepare-resources/README.md).
