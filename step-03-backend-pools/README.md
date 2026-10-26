# 03. Configure identity and backends

English | [Korean](../kr/step-03-backend-pools/README.md)

[Previous: create APIs](../step-02-create-apis/README.md) | [Contents](../README.md) | [Next: apply policies](../step-04-api-policies/README.md)

## 3-1. Enable APIM's system-assigned identity

1. Open APIM **Security > Managed identities**.
2. On **System assigned**, set **Status = On** and select **Save**.
3. Record the **Object (principal) ID**.

## 3-2. Assign model-account access

Repeat for every model-hosting account:

1. Open the Azure OpenAI account's **Access control (IAM)**.
2. Select **Add > Add role assignment**.
3. Select **Cognitive Services OpenAI User**.
4. Under **Members > Assign access to**, select **Managed identity**.
5. Select **API Management service** and the APIM instance created in step 01.
6. Verify its principal ID, then select **Review + assign**.
7. Check **Role assignments** for the APIM identity at this account's resource scope.

If text and image deployments share an account, one assignment for that account covers both. Allow for RBAC propagation before testing.

## 3-3. Reuse Text A and add three backends

1. Open **APIs > Backends** and select the generated Text A from step 02.
2. Confirm its actual ID and URL against the table.
3. Select **+ Create new backend** for each of the three manual entries.
4. Choose a single backend, the HTTP protocol option, and the HTTPS runtime URL below.
5. Leave static model keys and Authorization credentials unset. Step 04 applies Managed Identity in each API's inbound policy.
6. Save each backend.

| Backend | Creation | Runtime URL |
| --- | --- | --- |
| `<generated-text-backend-id>` | Automatic, reused | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| `text-aoai-02` | Manual | `https://<text-account-b>.openai.azure.com/openai/deployments/<text-deployment-b>` |
| `image-aoai-01` | Manual | `https://<image-account-a>.openai.azure.com/openai` |
| `image-aoai-02` | Manual | `https://<image-account-b>.openai.azure.com/openai` |

There are **four single backends: one automatic and three manual**. Text bases include their deployment paths; image bases end at `/openai`.

## 3-4. Configure circuit breakers

For each single backend, open **Settings > Circuit breaker settings > Add new** and save one rule:

| Setting | Initial value |
| --- | --- |
| Rule name | `ai-backend-errors` |
| Failure count | `1` |
| Failure interval | 1 minute (`PT1M`) |
| Failure status code ranges | `429-429`, `500-599` in the same rule |
| Trip duration | 1 minute (`PT1M`) |
| Check Retry-After header | True / Accept |

These are exercise settings. Accepting `Retry-After` can keep a backend excluded longer than one minute. Circuit state is approximate across gateway instances.

## 3-5. Create the backend pools

1. Open **APIs > Backends > Load balancer > + Create new pool**.
2. Name the pool `text-pool`.
3. Add the actual generated Text A ID and `text-aoai-02`.
4. Select **Customize weight and priority** and enter:

| Pool | Backend | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `<generated-text-backend-id>` | 1 | 100 |
| `text-pool` | `text-aoai-02` | 1 | 100 |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 1 | 100 |

5. Leave session affinity disabled and save.
6. Create `image-pool` using the image rows above.

Both backends in each pool serve normal traffic at equal priority and weight. Requests are approximately evenly distributed. A tripped circuit temporarily excludes that backend; it rejoins distribution after recovery. The failing request is not automatically retried.

## Completion criteria

- [ ] APIM's system-assigned identity is enabled.
- [ ] The identity has OpenAI User access at every model account's resource scope.
- [ ] Four single backends have the correct HTTPS URLs and circuit-breaker rules.
- [ ] Each pool has two backends, both at priority 1 and weight 100.

## Official documentation

- [APIM managed identities](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity)
- [Azure OpenAI role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [Assign roles in the portal](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Backends, circuit breakers, and pools](https://learn.microsoft.com/en-us/azure/api-management/backends)
