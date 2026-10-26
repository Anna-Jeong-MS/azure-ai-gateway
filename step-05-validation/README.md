# 05. Validation and operations

English | [Korean](../kr/step-05-validation/README.md)

[Previous: APIs and policies](../step-04-api-policies/README.md) | [Contents](../README.md)

## 5-A. Validate calls, errors, failover, and operations

### Objective and prerequisites

Verify not only successful calls but also the **actual selected backend**, access boundaries, limits, and failover. Tests incur Azure charges: use a non-production environment and the smallest practical number of calls.

Complete sections 5-A-1 through 5-A-3 with baseline policies first. If adding optional limits, run section 5-A-4 afterward. Obtain separate approval for circuit-breaker testing.

### 5-A-1. Successful calls in the portal

#### Text

1. Open **APIs > APIs > Text API > Test**.
2. Select **Create chat completion**.
3. Set `api-version` to the text version verified in step 01.
4. Confirm `Content-Type: application/json` and a subscription key that can access Text API.
5. Enter step 04's JSON request.
6. Select **Trace**, then inspect **Trace > Inbound / Backend / Outbound / On error** in the response.
7. Verify `/openai/deployments/gpt-55/chat/completions` occurs only once in the final backend path.
8. Check the expected `choices` and `usage` structure, not just HTTP 200.

#### Images

1. Repeat with Image API's **Generate image** operation.
2. Use the image API version, image-scoped key, and image request body.
3. Verify the final path is `/openai/deployments/gpt-image-25-flare/images/generations`.
4. Check HTTP 200 and actual image data in the expected `data` response structure. Output format, such as base64, depends on the selected model.

Traces and responses can contain tokens, prompts, images, and personal information. Do not upload them to GitHub; sanitize before external sharing. Do not use the obsolete `Ocp-Apim-Trace` header.

### 5-A-2. Record portal test evidence

Use the API **Test** and response **Trace** tabs only; no local client or command-line tool is needed.

1. For each API, record the HTTP status, selected backend hostname, final path, API version, and elapsed time in local working notes.
2. For text, inspect `choices`, `usage`, and `finish_reason` in the response body. For reasoning models with empty visible text, check the output-token cap and adjust only within approved limits.
3. For images, confirm that `data` contains actual image output in the model's supported format, not just a successful status.
4. When a call fails, record the actual status, error body, and failing Trace stage. Do not replace it with a success result.
5. Keep keys, tokens, prompts, generated images, and unredacted traces out of GitHub. Saving generated files is not part of this walkthrough.

### 5-A-3. Verify access and path boundaries

Run each test once and record the result.

| Test | Expected result | Evidence |
| --- | --- | --- |
| Correct Text key and Text API | 200 | Selected Text A/B host and correct deployment path |
| Correct Image key and Image API | 200 | Selected Image A/B host and actual image response |
| Missing/invalid subscription key | Rejected by APIM, normally 401 | No model-backend request |
| Text API-scoped key against Image API | Rejected | Do not use an all-APIs or administrator key |
| Unexposed operation path | APIM 404 | No wildcard exposure of arbitrary deployments |

Do not delete production RBAC assignments or block production networks to test permissions. For 401/403, first determine whether the error originated in APIM or the model account.

### 5-A-4. Validate optional limits

#### Per-team text token limits

1. Create another Active Text API-scoped subscription, `text-team-b`, as in step 04.
2. Confirm the teams use different APIM subscription IDs and keys.
3. In non-production, temporarily lower the token limit and make a small number of calls. Do not exhaust model quota as a test method.
4. Observe Team A's usage and verify that subsequent requests are blocked by an APIM 429 after the limit is exceeded.
5. With `estimate-prompt-tokens="false"`, consumption updates after responses. Do not require the first overshooting or concurrent request to stop exactly at the limit.
6. Confirm Team B can call with its separate counter.
7. Inspect `x-tokens-consumed`, `x-ratelimit-remaining-tokens`, `Retry-After`, and the policy stage shown in Trace.
8. Restore the approved limit.

A model-quota 429, an APIM token-limit 429, and a circuit-related 503 are different results.

#### Image request limits

1. Temporarily lower the request limit in non-production.
2. Inspect the remaining-calls header and APIM rate-limit 429.
3. Generate only the necessary few images. Do not require rejection on exactly the sixth request because distributed counters are approximate.
4. Restore the approved value.

### 5-A-5. Verify each individual backend

Normal primary-only traffic can hide secondary configuration failures.

1. In an approved non-production API, record existing pool and policy settings.
2. Temporarily point Text API's `set-backend-service` at `text-aoai-01` and verify success.
3. Point it at `text-aoai-02` and verify the same request.
4. **Restore `text-pool`.** If the optional retry block also selects a backend, temporarily disable retries for the individual tests and restore the original policy afterward.
5. Repeat for `image-aoai-01` and `image-aoai-02`, then **restore `image-pool`**.
6. Inspect the final effective policy to ensure no individual backend override remains.

Do not change a shared production API this way. Use a test API revision or a separate non-production APIM instance.

### 5-A-6. Verify circuit breaking and failover

#### A. Safe configuration verification

1. Check pool priorities/weights and each single backend's circuit-breaker rule.
2. Confirm section 5-A-5 successfully called every actual account with the intended authentication, networking, and model.
3. Record this as **configuration and individual-call validation**, not proof of actual failover.

#### B. Behavior verification: approved isolated environment only

1. Prepare two organization-owned and controlled HTTPS test endpoints instead of exhausting production model quota. Do not send tokens or subscription keys to public test services.
2. Make the primary capable of returning a controlled 429 with `Retry-After: 60`; make the secondary return an identifiable success response.
3. Create separate test backends, pool, and API with the same priorities and trip conditions. Do not configure managed identity credentials on test backends. Strip client Authorization, api-key, and APIM keys from the test API before forwarding.
4. Confirm the primary is selected while healthy.
5. Switch the primary to 429 and use Trace to verify the error **came from the backend**.
6. After the circuit trips, verify later requests select the secondary using Trace and endpoint logs. Do not judge from one initial request because node-level behavior is approximate.
7. Without retry, the initial 429 can reach the client unchanged. With the optional single text retry, confirm at most two backend attempts per client request.
8. Restore primary health and verify it is selected again after the actual trip/Retry-After period.
9. If 5xx is included in the rule, separately test a controlled 503.
10. Clean up only the approved test policies, endpoints, and resources. Do not delete the shared resource group.

If controlled endpoints are unavailable, record **failover test not performed**. Configuration screenshots alone do not prove a successful transition.

### 5-A-7. Operational monitoring

1. If needed, connect an approved Application Insights instance through **Application Insights > Add** in APIM. Check the cost of new resources.
2. Under each API's **Settings > Diagnostics**, configure the logger and sampling.
3. Do not collect request/response bodies or secret headers by default. Explicitly check Authorization, APIM keys, prompts, and image data.
4. Monitor latency, status codes, backend failure rate, 429/503, and request volume. Per-team token cost visibility needs separate token-metric policies and cost aggregation; basic request logging does not implement it automatically.
5. Managed identity-based Application Insights ingestion needs the separate `Monitoring Metrics Publisher` role and authentication configuration described by its documentation. The model account's OpenAI User assignment does not replace it.

### Troubleshooting matrix

| Symptom | First checks |
| --- | --- |
| APIM 401 | Subscription key, Active state, API scope, Subscription required |
| Model 401 | Managed identity credentials, audience, later deletion/overwrite of Authorization |
| 403 | Error origin, account RBAC, network restrictions, optional token quota |
| 404 | APIM operation match, then final backend host, deployment name, duplicated path, API version |
| 429 | APIM limit versus model quota in Trace; Retry-After and actual quota pool |
| 503 | Available pool members and circuits versus a real model 503 |
| 500/policy error | Effective policy, expressions, Subscription required, failing stage |
| Connection failure/timeout | Public network access, account access rules, public DNS, TLS, model latency, portal/proxy limits |

### Final completion checklist

- [ ] Verify the four existing accounts/deployments and compatible names within each pool; do not create or redeploy models.
- [ ] Verify models, versions, deployment types, and actual quota scope in the target subscription.
- [ ] Confirm **Standard v2**, public network access enabled, and no VNet injection/integration or private endpoints configured for this walkthrough.
- [ ] Verify the system-assigned identity and OpenAI User role on every account.
- [ ] Save authentication and circuit-breaker settings on all four single backends.
- [ ] Confirm both pools' members, priorities, and weights.
- [ ] Create both APIs, their explicit operations, and scoped subscriptions.
- [ ] Successfully call every backend individually and through the final pools.
- [ ] Verify optional limits and maximum retry attempts.
- [ ] Record actual failover results or why the test was not performed.
- [ ] Restore approved policies, limits, and pool routing after testing.
- [ ] Keep secrets and customer-specific results out of GitHub.

### Official documentation

- [Portal Trace and current tracing behavior](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector)
- [Backend pools and circuit breakers](https://learn.microsoft.com/en-us/azure/api-management/backends)
- [Token-limit concurrency, counters, and streaming](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [Application Insights integration and API diagnostics](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights)
