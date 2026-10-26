# 03. Backends and pools

English | [Korean](../kr/step-03-backend-pools/README.md)

[Previous: identity and access](../step-02-identity-access/README.md) | [Contents](../README.md) | [Next: APIs and policies](../step-04-api-policies/README.md)

## 3-A. Register four backends and circuit breakers

### Objective and prerequisites

Register the four model-hosting accounts as APIM backends. Complete managed identity and role assignment, and ensure APIM can reach every account.

### 3-A-1. Confirm runtime URLs

Replace the account placeholders with the actual names recorded in step 01.

| Backend ID | Runtime URL | Deployment |
| --- | --- | --- |
| `text-aoai-01` | `https://<text-account-a>.openai.azure.com/openai` | `gpt-55` |
| `text-aoai-02` | `https://<text-account-b>.openai.azure.com/openai` | `gpt-55` |
| `image-aoai-01` | `https://<image-account-a>.openai.azure.com/openai` | `gpt-image-25-flare` |
| `image-aoai-02` | `https://<image-account-b>.openai.azure.com/openai` | `gpt-image-25-flare` |

**Important:** Do not include `/deployments/<name>`, operation paths, or `api-version` in these backend URLs. Step 04's operation paths include the deployment name. Mixing this layout with existing local templates that already include deployment paths can duplicate URL segments.

### 3-A-2. Create each backend

1. In APIM, open **APIs > Backends**.
2. Select **+ Create new backend**.
3. Enter the backend ID from the table as **Name**. If it exists, compare its settings instead of duplicating it.
4. Choose a single backend and the HTTP protocol option, but enter an **HTTPS runtime URL**.
5. Under **Authorization credentials > Managed identity**, select **Enable**.
6. Set **Client identity > System assigned identity**.
7. Set **Resource ID** to exactly **`https://cognitiveservices.azure.com`**. This is the token audience, not the AI account's resource ID or backend URL.
8. Remove conflicting static `api-key` or stale Authorization credentials from this backend after assessing any APIs that reuse it.
9. Save and repeat for the other three backends.

The default authentication location is **the managed identity credentials on each individual backend**. Do not configure account authentication on the pool itself. Step 04 does not need to request the same token again in the API policy.

### 3-A-3. Add a circuit breaker

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
4. If the portal cannot edit multiple ranges in one rule, do not create two rules. Start with `429-429`; add the 5xx range through the official Backend REST API schema and organizational change process. Do not mark 5xx failover as verified if only 429 was configured.

### 3-A-4. Understand the behavior

- When the failure threshold is met within the interval, the circuit opens and calls to that backend stop temporarily.
- Accepting `Retry-After` can keep the backend unavailable longer than the configured minute. Azure OpenAI can return a long wait time.
- Circuit breakers and load balancing are approximate across distributed gateway instances. Do not assume every request and every node changes state simultaneously.
- **The request that encountered the error is not automatically replayed.** Selecting another backend for a later request and retrying the current request are separate behaviors.
- Authentication failures 401/403 are not part of this exercise's trip rule. Do not break authentication to simulate failover.

### Completion criteria

- [ ] Confirm all four backend IDs match the intended account URLs.
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

---

## 3-B. Create the text and image pools

### Objective and prerequisites

Group the four single backends into `text-pool` and `image-pool`. Save backend authentication and circuit-breaker settings first.

### 3-B-1. Choose the distribution strategy

| Goal | Primary / secondary settings | Meaning |
| --- | --- | --- |
| Distribute normal traffic across both accounts | Both priority 1; weights 100 / 100 | Approximately equal distribution within one priority group |
| Distribute proportionally | Both priority 1; for example weights 3 / 1 | Long-run relative weighting, not an exact per-request sequence |
| Primary/standby or PTU-to-PAYG | Priorities 1 / 2; weights 100 / 100 | Use the lower-priority group when all higher-priority backends are unavailable because their circuit breakers have tripped |

This exercise uses **priorities 1 / 2**. Smaller numbers mean higher priority. If simultaneous distribution is required, set both priorities to 1 and change step 05's expected result accordingly.

Weights do not produce normal traffic sharing between different priority groups. Equal weights with priorities 1 and 2 do not create a 50:50 split.

### 3-B-2. Create the text pool

1. Open **APIs > Backends > Load balancer**.
2. Select **+ Create new pool**.
3. Enter `text-pool` as **Name**.
4. Under **Add backends to pool**, add `text-aoai-01` and `text-aoai-02`.
5. Select **Customize weight and priority**:

| Pool | Backend | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `text-aoai-01` | 1 | 100 |
| `text-pool` | `text-aoai-02` | 2 | 100 |

6. Leave session awareness/session affinity disabled for this stateless single-call exercise.
7. Select **Create / Save**.

### 3-B-3. Create the image pool

Repeat with:

| Pool | Backend | Priority | Weight |
| --- | --- | --- | --- |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 2 | 100 |

Do not mix text and image backends in a pool. The accounts in each pool must expose the same deployment name and compatible API.

### 3-B-4. Verify saved settings

1. Reopen both pools and compare backend IDs, priorities, and weights.
2. Confirm members are the single backends created above, not other pool names.
3. API routing has not changed yet; step 04 must reference the pools.

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
