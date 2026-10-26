# 03. Identity, backends, and pools

English | [Korean](../kr/step-03-backend-pools/README.md)

[Previous: create APIs](../step-02-create-apis/README.md) | [Contents](../README.md) | [Next: API routing and policies](../step-04-api-policies/README.md)

## 3-A. Enable the APIM system-assigned identity

### Objective and prerequisites

Allow APIM to authenticate to model accounts with Microsoft Entra tokens instead of model keys. APIM must be Online, and the operator must have permission to modify it.

### 3-A-1. Enable the identity in the portal

1. Open the APIM instance.
2. Select **Security > Managed identities**, or the **Managed identities** menu.
3. Open **System assigned**.
4. Set **Status > On > Save**. If already enabled, do not disable or recreate it.
5. Copy the displayed **Object (principal) ID** into local working notes.
6. Confirm the APIM name, resource ID, and principal ID all refer to the intended instance.

The system-assigned service principal follows the APIM resource lifecycle. Disabling and re-enabling it, or recreating APIM, can change the identity; do not assume existing assignments still apply.

If user-assigned identities are already attached, preserve them. Enable the system-assigned identity through its own portal tab without removing existing identities. Refresh the page and verify that its status and principal ID remain visible.

### 3-A-2. Understand the authentication boundaries

| Connection | Credential |
| --- | --- |
| Client to APIM | APIM subscription key created in step 04 |
| APIM to Azure OpenAI | Entra token obtained with the APIM managed identity |

Enabling the identity does not grant access to model accounts. Assign a role on **each AI account** next. Obtaining a token does not bypass network restrictions.

### Completion criteria

- [ ] System-assigned identity is On.
- [ ] Record a nonempty principal ID.
- [ ] Do not confuse it with another APIM identity or the operator's object ID.
- [ ] Preserve any existing user-assigned identities.

### Troubleshooting

- **Cannot edit identity:** Check APIM management permission and PIM activation.
- **No principal ID displayed:** Save and refresh the resource. Do not substitute another identity.

### Official documentation

- [Create and use APIM managed identities](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity)
- [Managed identity authentication policy](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)

---

## 3-B. Assign access to each AI account

### Objective and prerequisites

Assign `Cognitive Services OpenAI User` to the APIM identity at the **individual account scope** for Text A/B and Image A/B.

Use the APIM principal ID from section 3-A and the four AI account resource IDs from step 01. The operator needs `Microsoft.Authorization/roleAssignments/write` at the applicable scope.

### 3-B-1. Choose the role and scope

| Setting | Value |
| --- | --- |
| Principal receiving access | APIM system-assigned managed identity |
| Role | Cognitive Services OpenAI User |
| Scope | Each individual Text A/B and Image A/B account resource |
| Built-in role ID | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` |

This role allows Entra-based inference and some resource/deployment reads. It does not allow model deployment creation/modification or account key access, making it suitable for this calling scenario. Broader subscription or resource-group assignments are technically possible but are not used here.

### 3-B-2. Repeat in the portal for each account

1. Open the **AI account**, not the APIM IAM page.
2. Select **Access control (IAM) > Add > Add role assignment**.
3. Under **Role**, select `Cognitive Services OpenAI User`.
4. Under **Members > Assign access to**, select **Managed identity**.
5. In **Select members**, choose the APIM subscription and **API Management service**.
6. Select the intended APIM service and verify the principal matches section 3-A.
7. Select **Review + assign**.
8. Check the role, principal, and scope under **Role assignments**.
9. Repeat for the remaining three accounts.

If the same principal/role/scope assignment already exists, do not create a duplicate. Assigning the role to the operator instead of APIM does not complete this task.

To verify in the portal, open each account's **Access control (IAM) > Role assignments**, filter by the APIM identity, and inspect its role and scope. If accounts are in different resource groups or subscriptions, verify each actual account rather than assuming one assignment covers all four.

### 3-B-3. Record verification

| AI account | Role | APIM principal matches | Account scope matches |
| --- | --- | --- | --- |
| Text A | OpenAI User | Verified | Verified |
| Text B | OpenAI User | Verified | Verified |
| Image A | OpenAI User | Verified | Verified |
| Image B | OpenAI User | Verified | Verified |

RBAC propagation can take time. If an immediate call fails, verify the assignment and allow for documented propagation behavior. Do not promise success after a fixed number of minutes.

### Completion criteria

- [ ] Verify the APIM identity's role on each of the four accounts.
- [ ] Avoid unnecessary subscription-wide or resource-group-wide grants.
- [ ] Distinguish operator permissions from APIM inference permissions.

### Troubleshooting

- **Add role assignment disabled:** Check whether the operator has only Contributor; request the role-assignment owner.
- **401/403 from calls:** Check principal, scope, token audience, and network restrictions. A 403 does not always mean RBAC.
- **Failure after identity recreation:** Compare the current principal ID with the assignment's principal.

### Official documentation

- [Azure OpenAI role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [Role assignment procedure and operator permissions](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)

---

## 3-C. Register four backends and circuit breakers

### Objective and prerequisites

Reuse the **Language Model API and its automatically created Primary backend from step 02**, then manually add only three backends. Identity and role assignment above must be complete, and APIM must reach the existing accounts through public HTTPS.

### 3-C-1. Confirm runtime URLs

Replace the account placeholders with the actual names recorded in step 01.

| Backend ID | Runtime URL | Deployment |
| --- | --- | --- |
| `<generated-text-backend-id>` (automatic; actual ID) | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55` | `gpt-55` |
| `text-aoai-02` (manual) | `https://<text-account-b>.openai.azure.com/openai/deployments/gpt-55` | `gpt-55` |
| `image-aoai-01` | `https://<image-account-a>.openai.azure.com/openai` | `gpt-image-25-flare` |
| `image-aoai-02` | `https://<image-account-b>.openai.azure.com/openai` | `gpt-image-25-flare` |

**Text:** Both text backend bases include `/openai/deployments/<actual-text-deployment>` and use the imported `/chat/completions` operation. **Images:** Both image bases end at `/openai`; the manually created image operation in step 04 contains `/deployments/<actual-image-deployment>/images/generations`. Do not mix these two layouts or put `api-version` in a backend base URL.

### 3-C-2. Reuse one generated backend and create three manually

1. Open **APIs > Backends** and select the generated Text Primary backend. Reuse its actual ID; inspect its deployment-specific URL instead of creating a duplicate.
2. For the remaining backends only, select **+ Create new backend** and create `text-aoai-02`, `image-aoai-01`, and `image-aoai-02` using the table. If any already exists, inspect and reuse it.
3. Choose a single backend and the HTTP protocol option for manual backends, but enter an **HTTPS runtime URL**.
4. Apply the following authentication checks to all four backends, including the automatic one.
5. Under **Authorization credentials > Managed identity**, select **Enable**.
6. Set **Client identity > System assigned identity**.
7. Set **Resource ID** to exactly **`https://cognitiveservices.azure.com`**. This is the token audience, not the AI account's resource ID or backend URL.
8. Remove conflicting static `api-key` or stale Authorization credentials from this backend after assessing any APIs that reuse it.
9. Save and verify all four single backends: **one automatic + three manual**, not five. The image regular HTTP API was already created in step 02; do not use Language Model API for images.

The default authentication location is **the managed identity credentials on each individual backend**. Do not configure account authentication on the pool itself. Step 04 does not need to request the same token again in the API policy.

### 3-C-3. Add a circuit breaker

For each backend, select **Settings > Circuit breaker settings > Add new**.

These are **exercise starting values for observing failover**, not fixed Microsoft recommendations. Tune production settings to actual error rates, quota, and recovery behavior.

| Setting | Exercise value |
| --- | --- |
| Rule name | `ai-backend-errors` |
| Failure count | `1` |
| Failure interval | 1 minute (`PT1M`) |
| Failure status code ranges | `429-429`, `500-599` |
| Trip duration | 1 minute (`PT1M`) |
| Check Retry-After header | True / Accept |

1. Put both status-code ranges in **one rule**. Currently only one circuit-breaker rule per backend is supported.
2. Save, reopen the backend, and check the persisted values.
3. Repeat on the other backends.
4. If the portal cannot edit multiple ranges in one rule, do not create two rules. Use `429-429` for this portal-only exercise and record 5xx coverage as not configured. Do not mark 5xx failover as verified in that case.

### 3-C-4. Understand the behavior

- When the failure threshold is met within the interval, the circuit opens and calls to that backend stop temporarily.
- Accepting `Retry-After` can keep the backend unavailable longer than the configured minute. Azure OpenAI can return a long wait time.
- Circuit breakers and load balancing are approximate across distributed gateway instances. Do not assume every request and every node changes state simultaneously.
- **The request that encountered the error is not automatically replayed.** Selecting another backend for a later request and retrying the current request are separate behaviors.
- Authentication failures 401/403 are not part of this exercise's trip rule. Do not break authentication to simulate failover.

### Completion criteria

- [ ] Confirm all four backend IDs match the intended account URLs.
- [ ] Text API was imported with Language Model API; its generated backend is reused as Primary, with only three additional single backends.
- [ ] Verify system-assigned identity credentials and the correct audience on each.
- [ ] Save a 429-handling circuit-breaker rule accepting Retry-After on each backend.
- [ ] Record whether 5xx was included and the actual settings used.
- [ ] Verify deployment paths are not duplicated.

### Troubleshooting

- **Managed identity option missing:** Check identity enablement and portal/tier support. Step 04 includes an API-level alternative; do not mix the two approaches.
- **BackendConnectionFailure:** Check DNS, firewalls, TLS, and actual account hostnames.
- **Failover persists too long:** Inspect the actual Retry-After value and trip duration.

### Official documentation

- [Backends and managed identity credentials](https://learn.microsoft.com/en-us/azure/api-management/backends)
- [Circuit-breaker behavior and limitations](https://learn.microsoft.com/en-us/azure/api-management/backends#circuit-breaker)
- [Managed identity token policy](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [Import Language Model API and automatic backend creation](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)

---

## 3-D. Create the text and image pools

### Objective and prerequisites

Group the four single backends into `text-pool` and `image-pool`. Save backend authentication and circuit-breaker settings first.

### 3-D-1. Choose the distribution strategy

| Goal | Primary / secondary settings | Meaning |
| --- | --- | --- |
| Distribute normal traffic across both accounts | Both priority 1; weights 100 / 100 | Approximately equal distribution within one priority group |
| Distribute proportionally | Both priority 1; for example weights 3 / 1 | Long-run relative weighting, not an exact per-request sequence |
| Primary/standby or PTU-to-PAYG | Priorities 1 / 2; weights 100 / 100 | Use the lower-priority group when all higher-priority backends are unavailable because their circuit breakers have tripped |

This exercise uses **priorities 1 / 2**. Smaller numbers mean higher priority. If simultaneous distribution is required, set both priorities to 1 and change step 05's expected result accordingly.

Weights do not produce normal traffic sharing between different priority groups. Equal weights with priorities 1 and 2 do not create a 50:50 split.

### 3-D-2. Create the text pool

1. Open **APIs > Backends > Load balancer**.
2. Select **+ Create new pool**.
3. Enter `text-pool` as **Name**.
4. Under **Add backends to pool**, add the **actual generated Text Primary backend ID** recorded above and `text-aoai-02`.
5. Select **Customize weight and priority**:

| Pool | Backend | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `<generated-text-backend-id>` (actual ID) | 1 | 100 |
| `text-pool` | `text-aoai-02` | 2 | 100 |

6. Leave session awareness/session affinity disabled for this stateless single-call exercise.
7. Select **Create / Save**.

### 3-D-3. Create the image pool

Repeat with:

| Pool | Backend | Priority | Weight |
| --- | --- | --- | --- |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 2 | 100 |

Do not mix text and image backends in a pool. The accounts in each pool must expose the same deployment name and compatible API.

### 3-D-4. Verify saved settings

1. Reopen both pools and compare backend IDs, priorities, and weights.
2. Confirm members are the single backends created above, not other pool names.
3. The imported Text API still references its generated single backend. In step 04, replace that route with `text-pool` and the existing image API's initial primary URL with `image-pool`.

Official documentation allows up to 30 backends per pool. Because load balancing and circuit state are approximate, a short sample does not prove an exact ratio or instantaneous failover.

### Completion criteria

- [ ] Pool IDs are exactly `text-pool` and `image-pool`.
- [ ] Each includes only its two intended single backends.
- [ ] Record whether the design uses priority failover or simultaneous distribution.
- [ ] Check shared quota-pool behavior; do not assume extra capacity.

### Troubleshooting

- **Only primary receives traffic:** Expected with priorities 1 / 2. Set both to 1 only if equal-priority distribution is intended.
- **Every call returns 503:** Check available members, circuit state, Retry-After, pool configuration, and the actual error source.
- **No secondary failover:** Check whether the primary error matches the trip rule. A 401/403 that does not trip the circuit is not a failover test.

### Official documentation

- [Pools, priorities, weights, and portal setup](https://learn.microsoft.com/en-us/azure/api-management/backends#load-balanced-pool)
- [Reference a pool with set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
