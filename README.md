# Azure AI Gateway

English | [Korean](kr/README.md)

A step-by-step guide to placing Azure API Management in front of Azure OpenAI text and image models.

Official documentation checked: **2026-10-26**. Portal labels can change; the guides include English menu names.

## Five-step guide

Follow the **five step folders at the repository root** in order. Each groups related tasks and includes inputs, portal instructions, completion criteria, troubleshooting, and Microsoft documentation.

| Step | Tasks |
| --- | --- |
| [01. Preparation and resources](step-01-prepare-resources/README.md) | Check inputs, permissions, quota, and networking; deploy AI accounts and models; select a tier and create APIM |
| [02. Identity and access](step-02-identity-access/README.md) | Enable the APIM system-assigned identity; grant resource-scoped access to each AI account |
| [03. Backends and pools](step-03-backend-pools/README.md) | Register four backends; configure identity authentication and circuit breakers; create text and image pools |
| [04. APIs and policies](step-04-api-policies/README.md) | Create APIs, operations, and subscriptions; route to pools; optionally add limits and retries |
| [05. Validation and operations](step-05-validation/README.md) | Test successful calls, errors, individual backends, and failover; configure monitoring and complete the checklist |

Meet each task's **completion criteria before proceeding**. Add optional features only after basic calls succeed.

The same five-step structure is available under [kr/](kr/README.md).

## Architecture

```text
Client -- APIM subscription key --> APIM (system-assigned managed identity)
                                     |
                                     +-- /text  --> text-pool
                                     |              +-- text-aoai-01 (region A)
                                     |              +-- text-aoai-02 (region B)
                                     |
                                     +-- /image --> image-pool
                                                    +-- image-aoai-01 (region A)
                                                    +-- image-aoai-02 (region B)

APIM -- Microsoft Entra token --> each Azure OpenAI account
```

## Scope and source mapping

The guide turns the local requirements into an implementation sequence for **two text-model accounts and two image-model accounts**, using the local source PDF's identity, token-limit, and backend-pool examples. Customer names, account names, and resource identifiers have not been copied into these guides.

| Source material | Covered in |
| --- | --- |
| PDF p.16: security, resiliency, scalability, and observability | Steps 02-05 |
| PDF p.20-21: 2,000 TPM per team, subscription-ID isolation, keyless authentication | Step 02, optional token limits in step 04, and step 05 |
| PDF p.22: PTU/PAYG pools and circuit breakers | Step 03 and failover validation in step 05 |
| Requirements: tier selection, model deployments, and operator permissions | Steps 01-02 |
| Requirements: backends, pools, APIs, policies, and checks | Steps 03-05 |
| PDF p.8, 23, 29: semantic caching; p.9, 24: Content Safety | Follow-up extensions outside this required configuration |
| PDF introductions to MCP, A2A, API Center, and Foundry preview features | Outside this implementation scope |

The PDF is a feature overview, not a current pricing or availability contract. Do not reuse its free-call allowances, prices, GA/preview labels, or region lists without checking current documentation. Caching and Content Safety require additional resources, permissions, policies, and tests; completing this guide does not configure them.

## Clarifications based on official documentation

- **Tiers and networking:** Standard v2 supports inbound private endpoints and outbound virtual network integration. Distinguish classic Premium from Premium v2 when considering multi-region deployment of APIM itself. [Tier comparison](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- **Quota:** Separate regions do not guarantee additional capacity. Check whether the particular model, version, and deployment type use a subscription-level shared quota pool. [Quotas and limits](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- **API separation:** Different paths do not technically require separate APIs. This guide separates text and image APIs to give them distinct policy and operational boundaries.
- **Failover and retries:** Circuit breaking, pool selection, and retrying the current request are separate mechanisms. Only backend text 429 responses are optionally retried once; image-generation POST requests are not automatically retried by default.
- **Authentication:** The client's APIM subscription key is separate from APIM's managed identity for model access. The Cognitive Services OpenAI User role permits inference and some read operations, not inference alone. [Role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)

## Before starting

- Target models are `gpt-5.5` for text and `gpt-image-2.5-flare` for images. Check model, version, region, and deployment-type availability in the actual subscription first.
- The default examples use Azure OpenAI `*.openai.azure.com` endpoints and **deployment paths with a date-based `api-version`**. Do not mix them with Foundry project endpoints or OpenAI v1 paths. Step 04 documents a separate text v1 alternative.
- Replace `<...>` placeholders with your values. Keep customer-specific values and secrets in local records only.
- CLI examples use PowerShell. The primary instructions use the Azure portal.
- Existing local PDFs, requirements, images, deployment code, and policy files remain local and are excluded through `.gitignore`. These guides do not overwrite those files.
- No Azure resource changes or inference calls were performed while writing the guide. Actual behavior must be verified in step 05. Following the procedures can incur Azure charges.

[Start with step 01](step-01-prepare-resources/README.md).
