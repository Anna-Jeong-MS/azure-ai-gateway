# 01. Preparation and resources

English | [Korean](../kr/step-01-prepare-resources/README.md)

[Contents](../README.md) | [Next: identity and access](../step-02-identity-access/README.md)

## 1-A. Prerequisites and inputs

### Objective

Confirm the subscription, permissions, models, networking, and costs before creating anything. Reuse the existing resource group. This section does not change resources.

### 1-A-1. Check operator permissions

1. Sign in to the [Azure portal](https://portal.azure.com) and confirm the directory and subscription.
2. Open the existing resource group.
3. Select **Access control (IAM) > View my access** and check your roles and their scopes.
4. Assign an owner for each task below. If the organization uses PIM, activate the required role. Also check role-assignment conditions, deny assignments, and Azure Policy.

| Task | Example built-in role | Scope and caveat |
| --- | --- | --- |
| Create APIM and AI accounts | Contributor | Target resource group. Permission on an existing APIM resource alone does not authorize creating a new service |
| Manage an existing APIM service, APIs, backends, and identity | API Management Service Contributor or Contributor | Target APIM service. Attaching a user-assigned identity can need additional permissions; this guide uses a system-assigned identity |
| Manage model deployments | Cognitive Services OpenAI Contributor | Existing Azure OpenAI account; creating the account is a separate permission |
| Assign roles to the APIM identity | Role Based Access Control Administrator, User Access Administrator, or Owner | AI account or an ancestor scope with `Microsoft.Authorization/roleAssignments/write` |
| Make direct inference test calls | Cognitive Services OpenAI User | AI account being called. Do not assume a Contributor management role grants data-plane inference access |

These are practical examples, not a universal minimum-permission definition. An organization's custom roles and conditions can provide the required access instead. **Contributor alone cannot assign Azure roles.**

### 1-A-2. Record inputs

Copy this table into local working notes and fill in actual values. Do not store secret values in the table or in Git.

| Input | Example or selection rule |
| --- | --- |
| Tenant ID / Azure subscription ID | Actual target values |
| Existing resource group | `<existing-resource-group>` |
| APIM name | `apim-ai-gateway-<unique-suffix>` |
| APIM region | A region supporting the chosen Standard v2 configuration |
| Publisher name / email | Approved organization name / administrator email |
| Regions A / B | For example, UAE North / East US 2, only after checking models and organizational policy |
| Text model | Target `gpt-5.5`; record exact version and deployment type |
| Image model | Target `gpt-image-2.5-flare`; record exact version and deployment type |
| Shared text deployment name | `gpt-55` |
| Shared image deployment name | `gpt-image-25-flare` |
| Text / image API versions | Date-based versions verified from each deployment's official sample; they can differ |
| Distribution strategy | Default exercise: priorities 1 / 2, weights 100 / 100 |
| Network path to model accounts | Approved public or private connectivity |

**Account name, model name, and deployment name are different values.** For example, account `aoai-text-a-demo` can host model `gpt-5.5` under deployment name `gpt-55`.

### 1-A-3. Plan the four accounts

| Purpose | Local alias | Example account name | Region | Deployment name |
| --- | --- | --- | --- | --- |
| Text primary | Text A | `aoai-text-a-<suffix>` | A | `gpt-55` |
| Text secondary | Text B | `aoai-text-b-<suffix>` | B | `gpt-55` |
| Image primary | Image A | `aoai-image-a-<suffix>` | A | `gpt-image-25-flare` |
| Image secondary | Image B | `aoai-image-b-<suffix>` | B | `gpt-image-25-flare` |

Text and image deployments can share an account, but these requirements use four accounts. Reuse accounts that are already prepared rather than creating duplicates.

### 1-A-4. Check model access, quota, and processing location

1. Find each target model and version in the Foundry model catalog.
2. Check that **each model** can be deployed in both selected regions using the selected deployment type. If not, stop and agree on an approved region or model alternative.
3. In Foundry's quota view, record the subscription, model, version, deployment type, quota-pool scope, and available capacity.
4. Global Standard inference can be processed across regions. Creating the resource in a region does not mean inference is restricted to that region.
5. Where data residency matters, confirm the actual processing boundaries of the available Data Zone or regional deployment type with the security owner.

**Important:** Current 2026 documentation describes a transition to subscription-level quota management, starting with particular models. Global Standard deployments of the same model and version can share a quota pool across regions. Other models can still have regional quota arrangements. Do not calculate twice the capacity merely because you create a second account or choose a second region.

### 1-A-5. Confirm networking and cost approval

1. Evaluate client-to-APIM and APIM-to-AI connectivity separately.
2. For private AI accounts, prepare outbound APIM VNet integration, connected networks, approved private endpoints, and private DNS first.
3. With private inbound APIM access, the test machine must reach the private network. The portal's Test button does not automatically bypass network restrictions.
4. Do not temporarily open a firewall if public testing is prohibited by organizational policy.
5. Review APIM fixed charges, model inference or provisioned-capacity charges, monitoring, and network costs. Do not treat the PDF's preview or free-usage descriptions as current pricing.

### Optional: prepare a CLI session

Run only in PowerShell with Azure CLI installed. Skip this if using only the portal.

```powershell
az login
$SubscriptionId = "<subscription-id>"
$ResourceGroup = "<existing-resource-group>"
$ApimName = "<apim-name>"
az account set --subscription $SubscriptionId
az account show --query "{subscription:id, tenant:tenantId, name:name}" --output table
```

Recheck variables and authentication context in each new PowerShell session.

### Completion criteria

- [ ] Record actual values for all four accounts and which existing resources will be reused.
- [ ] Confirm owners and permissions for resource creation, deployment, role assignment, and testing.
- [ ] Confirm model versions, regions, deployment types, and actual quota pools.
- [ ] Obtain networking and cost approval.

### Official documentation

- [Assign Azure roles in the portal](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Azure OpenAI role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [Model catalog and availability](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Azure OpenAI quotas and limits](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- [Deployment types and data processing boundaries](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types)
- [APIM private endpoints](https://learn.microsoft.com/en-us/azure/api-management/private-endpoint)

---

## 1-B. AI accounts and model deployments

### Objective and prerequisites

Prepare the four accounts and four model deployments planned above. **Check and reuse existing accounts and deployments.** Do not run the existing local deployment script, which can have different text-model defaults.

### 1-B-1. Create or check each account

Repeat for Text A, Text B, Image A, and Image B:

1. Search for **Azure OpenAI** in the Azure portal.
2. If an account already exists, open it and record its subscription, resource group, and region.
3. If needed, select **Create**.
4. Select the existing resource group and approved region; enter a globally unique account name.
5. Select the available pricing tier and approved networking configuration.
6. Select **Review + create > Create** and wait for deployment to finish.
7. Find the endpoint and resource ID in **Keys and Endpoint** or the overview. **Do not copy account keys into working documents.**
8. Confirm that the account endpoint is `https://<account>.openai.azure.com/`.

This procedure targets Azure OpenAI accounts. Do not assume a Foundry project API, partner serverless endpoint, or Azure AI Inference URL is interchangeable. If the portal opens the new Foundry interface, verify which account's Azure OpenAI endpoint hosts the deployment.

### 1-B-2. Deploy the text model

1. From Text A, open **Go to Microsoft Foundry**.
2. Check the selected account/project connection. Under **Models + endpoints / Deployments**, select **Deploy model**. Labels can differ between the classic and new interfaces.
3. Find `gpt-5.5` in the catalog.
4. Select the approved model version and deployment type.
5. Set the deployment name to **`gpt-55`**.
6. Allocate available capacity within quota and deploy.
7. Repeat in Text B using the **same deployment name, model, version, and compatible request schema**.
8. For an intentional PTU-to-PAYG design, deployment types can differ, but model, version, and request compatibility must match.

If access approval, quota, or model availability blocks deployment, stop here. Do not silently substitute another model; update the inputs and obtain approval.

### 1-B-3. Deploy the image model

1. Find `gpt-image-2.5-flare` in Image A's model catalog.
2. Confirm that the subscription can deploy the selected version and deployment type in the chosen region.
3. Set the deployment name to **`gpt-image-25-flare`** and deploy.
4. Repeat in Image B with the same name and compatible settings.
5. Check supported request fields and response formats in the model documentation and deployment's **View code / Consume** sample.

If the image model is not deployed, the image branch remains incomplete. A placeholder URL is not evidence of a successful image API.

### 1-B-4. Establish direct-call baselines

1. Run one direct text or image request against each deployment using its playground or official sample. Keep prompts short and generate only one image to minimize charges.
2. Prefer Microsoft Entra ID authentication. The test operator also needs account-scoped inference access.
3. Record the actual endpoint, **date-based `api-version`**, deployment name, body fields, success status, and response schema.
4. Verify that the paths used in this guide match the successful calls:

```text
Text:
https://<text-account>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-api-version>

Image:
https://<image-account>.openai.azure.com/openai/deployments/gpt-image-25-flare/images/generations?api-version=<image-api-version>
```

5. If the official sample uses **`/openai/v1/...` with `model` in the body**, do not convert it just by adding a date-based version. Confirm support for the deployment-path API and establish a successful direct call first. If choosing v1, use step 04's separate text conversion table and independently verify the image model's official API.
6. Resolve direct-call failures before introducing APIM.

### Working record

| Account | Endpoint | Model / version | Deployment name | Type / quota | API version | Direct call |
| --- | --- | --- | --- | --- | --- | --- |
| Text A | Actual value | Actual value | `gpt-55` | Actual value | Actual value | Pass/fail |
| Text B | Actual value | Actual value | `gpt-55` | Actual value | Actual value | Pass/fail |
| Image A | Actual value | Actual value | `gpt-image-25-flare` | Actual value | Actual value | Pass/fail |
| Image B | Actual value | Actual value | `gpt-image-25-flare` | Actual value | Actual value | Pass/fail |

### Completion criteria

- [ ] Record resource IDs and endpoints for all four accounts.
- [ ] Confirm matching deployment names and API compatibility within each pool.
- [ ] Successfully call all four actual model deployments.
- [ ] Record text and image API versions separately.

### Troubleshooting

- **Model missing:** Check catalog availability, region, deployment type, and subscription access conditions.
- **429:** Check the actual quota pool and deployment capacity. Another account does not necessarily add quota.
- **404:** Compare account, deployment name, API path, and API version.
- **403 or connection failure:** Investigate operator RBAC separately from firewalls and private DNS.

### Official documentation

- [Create and deploy an Azure OpenAI resource: classic portal](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/create-resource)
- [Model catalog and availability](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Use image-generation models](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [API lifecycle and v1 differences](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)

---

## 1-C. Select a tier and create APIM

### Objective

Prepare APIM for the APIs, policies, and pools. For an existing service, check its tier, region, networking, and operator access, then skip creation.

### 1-C-1. Select the tier

This is a **design proposal for this exercise**, not a universal production recommendation. Confirm cost, throughput, and networking requirements.

| Tier | Assessment for this exercise | Feature caveat |
| --- | --- | --- |
| Standard v2 | Production candidate and reference tier for this guide | SLA, outbound VNet integration, and inbound gateway private endpoints |
| Basic v2 | Development/testing candidate without network-isolated backends | Has an SLA, but not the same private-connectivity features as Standard v2 |
| Developer | Non-production development/evaluation only | No SLA |
| Premium (classic) | Consider when APIM itself needs multi-region deployment | Do not treat it as equivalent to Premium v2 |
| Premium v2 | Consider for VNet injection, availability zones, and larger capacity | Current comparison does not list APIM multi-region deployment as supported |
| Consumption | Excluded from this exercise | Backend circuit breakers are unsupported; policy support also differs |

**Calling AI backends in multiple regions** is different from **deploying APIM gateways in multiple regions**. A single Standard v2 APIM instance can call AI accounts in different regions.

Standard v2 supports inbound private endpoints, so a private endpoint requirement alone does not automatically imply Premium.

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
| Pricing tier | Approved tier; this guide uses Standard v2 |
| Units | Start with 1 and adjust after load validation |

3. On **Monitor + secure**, review the need and cost of add-on services.
4. On **Networking**, select the approved configuration.
5. You can enable the system-assigned identity on **Managed identity** now. If so, step 02 only needs to verify it.
6. In **Review + create**, recheck cost, tier, networking, and the existing resource group.
7. Select **Create** and wait until deployment finishes and the service is Online. Do not assume a fixed provisioning time.
8. Record the gateway URL, `https://<apim-name>.azure-api.net`.

### 1-C-3. Check networking

- Even with public AI endpoints, check that account firewalls permit APIM access.
- For private accounts, configure outbound routing and name resolution, including reachability to region B.
- With an inbound APIM private endpoint, verify approval, private DNS, and client connectivity before restricting public access.
- Standard v2 VNet integration uses a VNet in the same region and subscription as APIM. Connectivity to remote AI accounts requires a separate connected-network design.

### Completion criteria

- [ ] Record why the tier was chosen.
- [ ] Confirm the APIM service is Online and record its gateway URL.
- [ ] Confirm both client-to-APIM and APIM-to-AI connectivity plans.

### Troubleshooting

- **Tier or region unavailable:** Check current availability and choose an approved supported region.
- **Creation denied:** Check resource-group creation permission, not just permission on an existing APIM service.
- **Private backend unreachable:** Investigate DNS, VNets, and firewalls independently of managed identity.

### Official documentation

- [Create APIM in the portal](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [Feature-based tier comparison](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- [v2 tiers and networking differences](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [Inbound private endpoints](https://learn.microsoft.com/en-us/azure/api-management/private-endpoint)
