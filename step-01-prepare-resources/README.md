# 01. Create APIM

English | [Korean](../kr/step-01-prepare-resources/README.md)

[Contents](../README.md) | [Next: create APIs](../step-02-create-apis/README.md)

## 1-1. Check operator permissions

1. Sign in to the [Azure portal](https://portal.azure.com).
2. Confirm the directory, subscription, and target resource group.
3. Open **Access control (IAM) > View my access** and confirm:

| Task | Required access |
| --- | --- |
| Create APIM | Contributor or equivalent at the target resource group |
| Configure APIM | API Management Service Contributor or equivalent on APIM |
| Assign model-account roles | Role Based Access Control Administrator, User Access Administrator, Owner, or equivalent role-assignment permission at each AI account |

Contributor alone does not grant role-assignment permission.

## 1-2. Record the deployed model details

The models are already deployed. Record their connection details without creating or changing deployments.

1. Open each Azure OpenAI account and record its **Resource ID** and endpoint from **Overview / Keys and Endpoint**.
2. Open the deployment in Foundry **Models + endpoints / Deployments**.
3. Record the deployment name, model/version, region, deployment type, and provisioning status.
4. Open **View code / Consume** and record the supported date-based `api-version` and request schema. Do not copy model keys.
5. Confirm the account's public network access rules permit requests from APIM.

| Alias | Model | Deployment name used in examples |
| --- | --- | --- |
| Text A / Text B | `gpt-5.5` | `gpt-55` |
| Image A / Image B | `gpt-image-2.5-flare` | `gpt-image-25-flare` |

Use the actual names in all later URLs. For this walkthrough, use matching image deployment names in both image accounts because the operation path is shared. Each text backend carries its own deployment name in its base URL.

Record the available model quota and processing-location requirements. Different accounts or regions can share a quota pool; region separation alone does not guarantee additional capacity.

## 1-3. Create Standard v2 APIM

1. Open **API Management services > Create**.
2. Complete **Basics**:

| Field | Value |
| --- | --- |
| Subscription | Target subscription |
| Resource group | Target resource group |
| Region | Approved Standard v2 region |
| Resource name | `apim-ai-gateway-<unique-suffix>` |
| Organization name | Organization name |
| Administrator email | Administrator email |
| Pricing tier | **Standard v2** |
| Units | **1** |

3. On **Monitor + secure**, select only the monitoring services approved for this deployment.
4. On **Networking**, enable **Public network access**. Leave virtual network configuration at **None / not configured**. Do not add VNet integration or private endpoints.
5. Complete **Tags**, then select **Review + create > Create**.
6. Wait for deployment to finish and APIM to become Online.
7. Record the gateway URL: `https://<apim-name>.azure-api.net`.
8. Proceed directly to step 02 to create the APIs.

## Completion criteria

- [ ] Record both text and image endpoints, deployment names, resource IDs, and API versions.
- [ ] Confirm public access from APIM to the model accounts.
- [ ] Create an Online Standard v2 APIM with public access and no VNet/private endpoint configuration.

## Official documentation

- [Create APIM in the portal](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [APIM v2 tiers](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [Assign roles using the portal](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Model quotas and limits](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
