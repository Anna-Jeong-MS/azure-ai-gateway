# Azure AI Gateway

English | [Korean](kr/README.md)

A step-by-step guide to placing Azure API Management in front of Azure OpenAI text and image models.

Official documentation checked: **2026-10-26**. Portal labels can change; the guides include English menu names.

## Five-step guide

Follow the **five step folders at the repository root** in order. Each groups related tasks and includes inputs, portal instructions, completion criteria, troubleshooting, and Microsoft documentation.

| Step | Tasks |
| --- | --- |
| [01. Existing models and APIM preparation](step-01-prepare-resources/README.md) | Record existing endpoints and deployment names; check permissions and public connectivity; create Standard v2 APIM |
| [02. Identity and access](step-02-identity-access/README.md) | Enable the APIM system-assigned identity; grant resource-scoped access to each AI account |
| [03. Backends and pools](step-03-backend-pools/README.md) | Register four backends; configure identity authentication and circuit breakers; create text and image pools |
| [04. APIs and policies](step-04-api-policies/README.md) | Create APIs, operations, and subscriptions; route to pools; optionally add limits and retries |
| [05. Validation and operations](step-05-validation/README.md) | Test successful calls, errors, individual backends, and failover; configure monitoring and complete the checklist |

Meet each task's **completion criteria before proceeding**. Add optional features only after basic calls succeed.

The same five-step structure is available under [kr/](kr/README.md).

## Architecture

```text
Client -- public HTTPS + APIM subscription key --> APIM Standard v2 (system-assigned managed identity)
                                     |
                                     +-- /text  --> text-pool
                                     |              +-- text-aoai-01 (region A)
                                     |              +-- text-aoai-02 (region B)
                                     |
                                     +-- /image --> image-pool
                                                    +-- image-aoai-01 (region A)
                                                    +-- image-aoai-02 (region B)

APIM -- public HTTPS + Microsoft Entra token --> each Azure OpenAI account
```

## Scope and source mapping

The guide turns the local requirements into an implementation sequence for **two text-model accounts and two image-model accounts**, using the local source PDF's identity, token-limit, and backend-pool examples. Customer names, account names, and resource identifiers have not been copied into these guides.

| Source material | Covered in |
| --- | --- |
| PDF p.16: security, resiliency, scalability, and observability | Steps 02-05 |
| PDF p.20-21: 2,000 TPM per team, subscription-ID isolation, keyless authentication | Step 02, optional token limits in step 04, and step 05 |
| PDF p.22: PTU/PAYG pools and circuit breakers | Step 03 and failover validation in step 05 |
| Requirements: Standard v2, existing model details, and operator permissions | Steps 01-02 |
| Requirements: backends, pools, APIs, policies, and checks | Steps 03-05 |
| PDF p.8, 23, 29: semantic caching; p.9, 24: Content Safety | Follow-up extensions outside this required configuration |
| PDF introductions to MCP, A2A, API Center, and Foundry preview features | Outside this implementation scope |

The PDF is a feature overview, not a current pricing or availability contract. Do not reuse its free-call allowances, prices, GA/preview labels, or region lists without checking current documentation. Caching and Content Safety require additional resources, permissions, policies, and tests; completing this guide does not configure them.

## Clarifications based on official documentation

- **Fixed configuration:** Use **Standard v2 with public network access enabled**. Do not configure VNet injection, outbound VNet integration, or private endpoints in this walkthrough. Calling AI accounts in different regions does not require multi-region deployment of APIM itself. [Tier comparison](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- **Quota:** Separate regions do not guarantee additional capacity. Check whether the particular model, version, and deployment type use a subscription-level shared quota pool. [Quotas and limits](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- **API separation:** Different paths do not technically require separate APIs. This guide separates text and image APIs to give them distinct policy and operational boundaries.
- **Failover and retries:** Circuit breaking, pool selection, and retrying the current request are separate mechanisms. Only backend text 429 responses are optionally retried once; image-generation POST requests are not automatically retried by default.
- **Authentication:** The client's APIM subscription key is separate from APIM's managed identity for model access. The Cognitive Services OpenAI User role permits inference and some read operations, not inference alone. [Role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)

## Before starting

- Text `gpt-5.5` and image `gpt-image-2.5-flare` models are **already deployed**. Record their actual endpoints, deployment names, versions, and types; do not create AI accounts or deploy, rename, or resize models.
- The default examples use Azure OpenAI `*.openai.azure.com` endpoints and **deployment paths with a date-based `api-version`**. Do not mix them with Foundry project endpoints or OpenAI v1 paths. Step 04 documents a separate text v1 alternative.
- Replace `<...>` placeholders with your values. Keep customer-specific values and secrets in local records only.
- All resource configuration and testing use the **Azure portal only**, including its policy editor and API test console. No CLI, PowerShell, or Cloud Shell steps are required.
- Public connectivity does not mean anonymous access: keep APIM subscription validation and managed identity/RBAC authentication to model accounts enabled.
- Existing local PDFs, requirements, images, deployment code, and policy files remain local and are excluded through `.gitignore`. These guides do not overwrite those files.
- No Azure resource changes or inference calls were performed while writing the guide. Actual behavior must be verified in step 05. Following the procedures can incur Azure charges.

[Start with existing models and APIM preparation](step-01-prepare-resources/README.md).
