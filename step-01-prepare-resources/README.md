# 01. Existing models and APIM preparation

English | [Korean](../kr/step-01-prepare-resources/README.md)

[Contents](../README.md) | [Next: identity and access](../step-02-identity-access/README.md)

## 1-A. Prerequisites and inputs

### Objective

Assume all text and image models are already deployed. Record their existing connection details, then prepare Standard v2 APIM with public connectivity. Reuse the existing resource group and do not create AI accounts or model deployments.

### 1-A-1. Check operator permissions

1. Sign in to the [Azure portal](https://portal.azure.com) and confirm the directory and subscription.
2. Open the existing resource group.
3. Select **Access control (IAM) > View my access** and check your roles and their scopes.
4. Assign an owner for each task below. If the organization uses PIM, activate the required role. Also check role-assignment conditions, deny assignments, and Azure Policy.

| Task | Example built-in role | Scope and caveat |
| --- | --- | --- |
| Create APIM | Contributor | Target resource group. Permission on an existing APIM resource alone does not authorize creating a new service |
| Manage an existing APIM service, APIs, backends, and identity | API Management Service Contributor or Contributor | Target APIM service. Attaching a user-assigned identity can need additional permissions; this guide uses a system-assigned identity |
| Assign roles to the APIM identity | Role Based Access Control Administrator, User Access Administrator, or Owner | AI account or an ancestor scope with `Microsoft.Authorization/roleAssignments/write` |
| Optional playground baseline test | Cognitive Services OpenAI User | Existing AI account. APIM test calls instead use APIM's identity for backend access |

These are practical examples, not a universal minimum-permission definition. An organization's custom roles and conditions can provide the required access instead. **Contributor alone cannot assign Azure roles.**

### 1-A-2. Record inputs

Copy this table into local working notes and fill in actual values. Do not store secret values in the table or in Git.

| Input | Example or selection rule |
| --- | --- |
| Tenant ID / Azure subscription ID | Actual target values |
| Existing resource group | `<existing-resource-group>` |
| APIM name | `apim-ai-gateway-<unique-suffix>` |
| APIM tier | **Standard v2** |
| APIM region | A region supporting the chosen Standard v2 configuration |
| APIM networking | Public network access enabled; no VNet injection, VNet integration, or private endpoint |
| Publisher name / email | Approved organization name / administrator email |
| Regions A / B | For example, UAE North / East US 2, only after checking models and organizational policy |
| Text model | Existing `gpt-5.5` deployment; record its version and deployment type |
| Image model | Existing `gpt-image-2.5-flare` deployment; record its version and deployment type |
| Existing shared text deployment name | Example `gpt-55`; use the actual existing name |
| Existing shared image deployment name | Example `gpt-image-25-flare`; use the actual existing name |
| Text / image API versions | Date-based versions verified from each deployment's official sample; they can differ |
| Distribution strategy | Default exercise: priorities 1 / 2, weights 100 / 100 |
| Network path to model accounts | Public HTTPS endpoints with account access rules permitting APIM |

**Account name, model name, and deployment name are different values.** For example, account `aoai-text-a-demo` can host model `gpt-5.5` under deployment name `gpt-55`.

### 1-A-3. Inventory the four existing accounts

| Purpose | Local alias | Example account name | Region | Deployment name |
| --- | --- | --- | --- | --- |
| Text primary | Text A | `aoai-text-a-<suffix>` | A | `gpt-55` |
| Text secondary | Text B | `aoai-text-b-<suffix>` | B | `gpt-55` |
| Image primary | Image A | `aoai-image-a-<suffix>` | A | `gpt-image-25-flare` |
| Image secondary | Image B | `aoai-image-b-<suffix>` | B | `gpt-image-25-flare` |

These are logical aliases and examples for existing resources, not names to provision. Text and image deployments can share an account; if they do, record the actual mapping and do not create another account just to match the table.

Replace example deployment names in the later API operation paths with existing names. If the two deployments in a pool have different names, stop and agree on explicit per-backend path mapping or separate APIs. Do not rename or redeploy models to match this guide.

### 1-A-4. Check model access, quota, and processing location

1. Find each target model and version in the Foundry model catalog.
2. In each existing deployment's details, verify its model, version, region, deployment type, and successful provisioning state. Do not create or change deployments.
3. In Foundry's quota view, record the subscription, model, version, deployment type, quota-pool scope, and available capacity.
4. Global Standard inference can be processed across regions. Creating the resource in a region does not mean inference is restricted to that region.
5. Where data residency matters, confirm the actual processing boundaries of the available Data Zone or regional deployment type with the security owner.

**Important:** Current 2026 documentation describes a transition to subscription-level quota management, starting with particular models. Global Standard deployments of the same model and version can share a quota pool across regions. Other models can still have regional quota arrangements. Do not calculate twice the capacity merely because you create a second account or choose a second region.

### 1-A-5. Confirm networking and cost approval

1. Use public HTTPS for both client-to-APIM and APIM-to-AI connectivity.
2. Keep APIM public network access enabled. Do not create a VNet, subnet, private endpoint, or private DNS zone for this walkthrough; do not enable outbound VNet integration.
3. Confirm each AI account's public endpoint and approved access rules allow APIM requests. Public networking does not remove APIM subscription validation or managed identity/RBAC requirements.
4. If an existing AI account is private-only or policy prohibits the required public access, stop and agree on a separate design. Do not disable a firewall or change existing private connectivity without approval.
5. Review APIM fixed charges, model inference or provisioned-capacity charges, monitoring, and network costs. Do not treat the PDF's preview or free-usage descriptions as current pricing.

### Completion criteria

- [ ] Inventory the existing text/image accounts and deployment names without creating resources.
- [ ] Confirm owners and permissions for APIM creation, role assignment, and portal testing; model-management permission is not required by this walkthrough.
- [ ] Confirm model versions, regions, deployment types, and actual quota pools.
- [ ] Confirm Standard v2 and approved public HTTPS connectivity without VNet or private endpoints; obtain cost approval.

### Official documentation

- [Assign Azure roles in the portal](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Azure OpenAI role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [Model catalog and availability](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Azure OpenAI quotas and limits](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- [Deployment types and data processing boundaries](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types)
- [APIM v2 tiers and networking options](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)

---

## 1-B. Verify existing model connection details

### Objective and prerequisites

All models are already deployed. This section is read-only: verify existing accounts, endpoints, deployment names, and API versions in the portal. Do not select **Create**, **Deploy model**, or redeploy a model, and do not run the existing local deployment script.

### 1-B-1. Find each existing account

Repeat for Text A, Text B, Image A, and Image B:

1. Search for **Azure OpenAI** in the Azure portal.
2. If an account already exists, open it and record its subscription, resource group, and region.
3. Find the endpoint and resource ID in **Keys and Endpoint** or the overview. **Do not copy account keys into working documents.**
4. Confirm that the account endpoint is `https://<account>.openai.azure.com/`.
5. Inspect the account's **Networking** settings and confirm its public endpoint/access rules permit APIM access. Do not create a private endpoint or change existing rules without approval.

This procedure targets Azure OpenAI accounts. Do not assume a Foundry project API, partner serverless endpoint, or Azure AI Inference URL is interchangeable. If the portal opens the new Foundry interface, verify which account's Azure OpenAI endpoint hosts the deployment.

### 1-B-2. Inspect existing text deployments

1. From Text A, open **Go to Microsoft Foundry**.
2. Check the selected account/project connection and open **Models + endpoints / Deployments**. Labels can differ between the classic and new interfaces.
3. Open the existing `gpt-5.5` deployment and record its deployment name, version, type, and status.
4. Open **View code / Consume** and record the endpoint, supported API version, and request format. Do not copy account keys.
5. Repeat in Text B and confirm compatible model/version/request behavior and matching deployment names for the common-path pool design.
6. Different deployment types are acceptable for an already-established PTU-to-PAYG design if the request interface is compatible.

If a deployment is missing or incompatible, ask its owner to resolve the prerequisite. Do not create, resize, rename, or substitute models as part of APIM setup.

### 1-B-3. Inspect existing image deployments

1. Open Image A's existing `gpt-image-2.5-flare` deployment.
2. Record its deployment name, version, region, type, and successful provisioning state.
3. Repeat in Image B and compare deployment names and compatible API settings.
4. Check request fields, response formats, endpoint, and API version in the model documentation and **View code / Consume** sample.

If a model is unexpectedly absent, stop and contact the deployment owner. A placeholder URL does not satisfy the existing-model prerequisite.

### 1-B-4. Confirm API paths and optional portal baselines

1. Inspect each existing deployment's portal sample without running SDK or command-line examples. Optionally send one request in its Playground if the operator already has access; keep prompts short and generate one image.
2. For the optional Playground call, prefer Microsoft Entra ID authentication and verify the operator's inference role. If unavailable, record the baseline as not performed and test through APIM in step 05 instead.
3. Record the actual endpoint, **date-based `api-version`**, deployment name, body fields, and response schema from the portal sample; if a call was made, record its result too.
4. Verify that the example paths match the existing deployments' supported API:

```text
Text:
https://<text-account>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-api-version>

Image:
https://<image-account>.openai.azure.com/openai/deployments/gpt-image-25-flare/images/generations?api-version=<image-api-version>
```

5. If the official sample uses **`/openai/v1/...` with `model` in the body**, do not convert it just by adding a date-based version. Confirm deployment-path support in the model documentation. If choosing v1, use step 04's separate text conversion table and independently verify the image model's official API.
6. Record optional Playground failures separately from APIM errors; resolve known model problems before proceeding.

### Working record

| Account | Endpoint | Model / version | Deployment name | Type / quota | API version | Direct call |
| --- | --- | --- | --- | --- | --- | --- |
| Text A | Actual value | Actual value | Actual name (example `gpt-55`) | Actual value | Actual value | Pass/fail/not performed |
| Text B | Actual value | Actual value | Actual name (example `gpt-55`) | Actual value | Actual value | Pass/fail/not performed |
| Image A | Actual value | Actual value | Actual name (example `gpt-image-25-flare`) | Actual value | Actual value | Pass/fail/not performed |
| Image B | Actual value | Actual value | Actual name (example `gpt-image-25-flare`) | Actual value | Actual value | Pass/fail/not performed |

### Completion criteria

- [ ] Record resource IDs and endpoints for all four accounts.
- [ ] Confirm matching deployment names and API compatibility within each pool.
- [ ] Confirm existing deployment health and API compatibility; record optional Playground results or defer call validation to step 05.
- [ ] Record text and image API versions separately.

### Troubleshooting

- **Model missing:** Check catalog availability, region, deployment type, and subscription access conditions.
- **429:** Check the actual quota pool and deployment capacity. Another account does not necessarily add quota.
- **404:** Compare account, deployment name, API path, and API version.
- **403 or connection failure:** Investigate operator RBAC separately from public network access rules, firewalls, and public DNS.

### Official documentation

- [Model catalog and availability](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Use image-generation models](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [API lifecycle and v1 differences](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)

---

## 1-C. Create Standard v2 APIM with public access

### Objective

Prepare Standard v2 APIM for the APIs, policies, and pools using public connectivity. For an existing service, verify this configuration and operator access before reusing it; do not silently change its tier or networking.

### 1-C-1. Confirm the fixed configuration

The tier and networking choice are fixed for this walkthrough:

| Setting | Required value | Notes |
| --- | --- | --- |
| APIM pricing tier | **Standard v2** | Start with one unit; validate capacity separately |
| Inbound connectivity | Public HTTPS | Public network access enabled; keep subscription validation |
| VNet injection | Not used | Do not select a VNet or subnet |
| Outbound VNet integration | Disabled / not configured | Call AI accounts through their public endpoints |
| Private endpoints | Not configured | No private DNS setup is required for this design |

**Calling AI backends in multiple regions** is different from **deploying APIM gateways in multiple regions**. A single Standard v2 APIM instance can call AI accounts in different regions.

VNet injection and outbound VNet integration are different features. Standard v2 supports outbound integration, but this design uses neither. Do not add private connectivity as a prerequisite.

### 1-C-2. Create the instance

1. In the Azure portal, open **API Management services > Create**.
2. Enter:

| Basics field | Value |
| --- | --- |
| Subscription | Confirmed target subscription |
| Resource group | Existing resource group |
| Region | Approved region supporting the tier, considering latency |
| Resource name | Unique `apim-ai-gateway-<unique-suffix>` |
| Organization name | Approved organization name |
| Administrator email | Actual administrator email |
| Pricing tier | **Standard v2** |
| Units | Start with 1 and adjust after load validation |

3. On **Monitor + secure**, review the need and cost of add-on services.
4. On **Networking**, use the public endpoint and keep **Public network access enabled**. Leave virtual network configuration at **None / not configured** where shown; do not enable VNet integration or add a private endpoint.
5. You can enable the system-assigned identity on **Managed identity** now. If so, step 02 only needs to verify it.
6. In **Review + create**, recheck cost, tier, networking, and the existing resource group.
7. Select **Create** and wait until deployment finishes and the service is Online. Do not assume a fixed provisioning time.
8. Record the gateway URL, `https://<apim-name>.azure-api.net`.

### 1-C-3. Check networking

- In APIM's **Networking** settings, confirm public network access is enabled, VNet integration is not configured, and no private endpoint has been added for this walkthrough.
- Check public DNS/HTTPS reachability to APIM and both regions' AI endpoints.
- Confirm AI account access rules permit APIM requests. Do not assume enabling a public endpoint automatically permits every caller or provides a fixed APIM outbound IP.
- Keep subscription-key validation at APIM and managed identity authentication to AI accounts. Public access is a network choice, not anonymous access.
- Do not modify existing private-only accounts to fit the guide without approval; stop and resolve the design mismatch instead.

### Completion criteria

- [ ] Confirm the deployed pricing tier is **Standard v2**.
- [ ] Confirm the APIM service is Online and record its gateway URL.
- [ ] Verify public network access is enabled and VNet injection/integration and private endpoints are not configured for this walkthrough.
- [ ] Confirm both client-to-APIM and APIM-to-AI public HTTPS access rules.

### Troubleshooting

- **Standard v2 unavailable in the selected region:** Check availability and choose an approved Standard v2 region; do not silently substitute another tier.
- **Creation denied:** Check resource-group creation permission, not just permission on an existing APIM service.
- **Public backend unreachable:** Check public network access, account access rules, public DNS, and TLS independently of managed identity.

### Official documentation

- [Create APIM in the portal](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [Feature-based tier comparison](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- [v2 tiers and networking differences](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
