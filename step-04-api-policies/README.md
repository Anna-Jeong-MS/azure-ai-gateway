# 04. APIs and policies

English | [Korean](../kr/step-04-api-policies/README.md)

[Previous: backends and pools](../step-03-backend-pools/README.md) | [Contents](../README.md) | [Next: validation and operations](../step-05-validation/README.md)

## 4-A. Configure APIs and subscriptions

### Objective and prerequisites

Create a separate HTTP API for each pool and explicitly expose operations. Separate APIs are an operational and policy boundary for this exercise, not a technical requirement.

First verify the existing deployment details from step 01 and saved pools/backends from step 03. A direct Playground call is optional; actual APIM calls are validated in step 05.

`gpt-55` and `gpt-image-25-flare` are example existing deployment names. Substitute the actual names recorded in step 01 throughout operation paths and tests; do not create or rename deployments to match the examples.

### 4-A-1. Create the text HTTP API

1. Open **APIs > APIs > + Add API > HTTP**.
2. Enter:

| Field | Value |
| --- | --- |
| Display name | `Text API` |
| Name | `text-api` |
| Web service URL | `https://<text-account-a>.openai.azure.com/openai` |
| API URL suffix | `text` |
| URL scheme | HTTPS |
| Subscription required | On |

3. After creation, confirm **Subscription required** under **Settings**. The backend URL is an initial default; section 4-B overrides it with a pool.
4. Select **Design > + Add operation**.
5. Configure:

| Field | Value |
| --- | --- |
| Display name | `Create chat completion` |
| Name | `create-chat-completion` |
| Method | `POST` |
| URL | `/deployments/gpt-55/chat/completions` |
| Query parameter | `api-version`, using the text version verified in step 01 |
| Request content type | `application/json` |

6. Set the query parameter's example/default to the supported version. Clients should also send `api-version`.
7. Use this minimal request, retaining only fields supported by the existing deployment's portal sample:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "Reply with OK only."
    }
  ],
  "max_completion_tokens": 1024,
  "stream": false
}
```

This exercise uses a **fixed operation path containing the deployment name**. Do not create wildcard operations exposing arbitrary deployments.

### 4-A-2. Create the image HTTP API

Repeat API and operation creation with:

| Field | Value |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Subscription required | On |
| Operation display name / Name | `Generate image` / `generate-image` |
| Method | `POST` |
| URL | `/deployments/gpt-image-25-flare/images/generations` |
| Query parameter | `api-version`, using the image version verified in step 01 |
| Request content type | `application/json` |

Check this minimal request against the actual model's supported options:

```json
{
  "prompt": "A simple blue circle on a white background.",
  "n": 1,
  "size": "1024x1024"
}
```

### 4-A-3. Check URL composition

APIM uses the API suffix on the client-facing URL and appends the operation path to the selected backend base URL. Compare the resulting URL with the existing deployment's portal sample.

| Connection | Text example |
| --- | --- |
| Client to APIM | `https://<apim>.azure-api.net/text/deployments/gpt-55/chat/completions?api-version=<text-version>` |
| APIM to Text A | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-version>` |
| APIM to Text B | Same path and query, with the Text B hostname |

Image client URL:

```text
https://<apim>.azure-api.net/image/deployments/gpt-image-25-flare/images/generations?api-version=<image-version>
```

No extra `rewrite-uri` is needed. If inherited policies rewrite URLs or API versions, inspect **Calculate effective policy** and Trace to confirm the final path.

### 4-A-4. Create API-scoped test subscriptions

1. Open **Subscriptions > + Add subscription**.
2. Name it `text-test`; set **Scope > API > Text API**.
3. Confirm its state is **Active**.
4. Create `image-test` scoped to **Image API**.
5. Reveal keys in the portal only as needed. Keep them in a secret store or test-session memory.
6. Do not put keys in documents, commits, or screenshots.

An **APIM subscription is not an Azure subscription**. A product-scoped subscription can be used when publishing the APIs together, but this exercise uses API scopes to avoid confusion.

For per-team token-limit testing, step 05 creates another Text API subscription. Sharing one key across teams does not create separate team limits.

### Reference: switching the text API to v1

The default walkthrough uses date-based APIs. If selecting v1, change every text integration surface together and validate separately.

| Setting | Default deployment-path API | Text v1 alternative |
| --- | --- | --- |
| Runtime URLs on both text backends | `https://<account>.openai.azure.com/openai` | `https://<account>.openai.azure.com/openai/v1` |
| Text API Web service URL | Primary URL above | Primary v1 URL above |
| Operation URL | `/deployments/gpt-55/chat/completions` | `/chat/completions` |
| Deployment selection | `gpt-55` in the path | `"model": "gpt-55"` in the JSON body |
| Query | Date-based `api-version` required | Date-based version not required for v1 GA |
| APIM path | `/text/deployments/gpt-55/chat/completions` | `/text/chat/completions` |

Keep the pool name and managed identity approach. This table does not establish image v1 support. Independently check the image model's official API and request schema before converting it.

### Completion criteria

- [ ] Save both APIs, each with its explicit POST operation.
- [ ] Confirm backend base URL plus operation path matches the existing deployment's supported URL.
- [ ] Create an Active subscription scoped to each API.
- [ ] Keep text/image API versions and subscription keys separate.

Calling now can still use the default primary URL. **Pool routing is complete only after section 4-B's policy is applied.**

### Official documentation

- [Manually create HTTP APIs and operations](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [APIM subscription scopes and keys](https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions)
- [Image-generation API examples](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [v1 versus date-based APIs](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)
- [v1 Chat API and authentication](https://learn.microsoft.com/en-us/rest/api/microsoft-foundry/azureopenai/chat?view=rest-microsoft-foundry-v1)

---

## 4-B. Apply routing, authentication, and optional limits

### Objective and prerequisites

Route each API to its pool, then add optional features incrementally after basic calls work. Use the examples here without changing the existing local policy files at the root.

**Default authentication is configured on each individual backend in step 03.** API **Subscription required** must be On.

### 4-B-1. Check policy scope and existing behavior

1. Select **APIs > APIs > Text API > Design > All operations**.
2. Open the **`</>`** policy code editor.
3. Keep an approved local copy of existing policies. Check global, product, API, and operation scopes for conflicting authentication, routing, or retries.
4. Apply the text baseline below and select **Save**.
5. Inspect **Calculate effective policy**. Assess and resolve any operation-level routing or authentication overrides.
6. Apply the separate image baseline to Image API.

`<base />` inherits parent policies. These examples define `forward-request` directly in `<backend>`, so do not add `<base />` alongside it. If global backend policies contain mandatory processing, assess the effect of overriding them and preserve required behavior.

### 4-B-2. Text API baseline

```xml
<policies>
  <inbound>
    <base />
    <set-header name="api-key" exists-action="delete" />
    <set-header name="Authorization" exists-action="delete" />
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
    <set-query-parameter name="subscription-key" exists-action="delete" />
    <set-backend-service backend-id="text-pool" />
  </inbound>
  <backend>
    <forward-request buffer-request-body="true"
                     buffer-response="false"
                     fail-on-error-status-code="false"
                     timeout="120" />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```

- Delete the **client's Authorization header** so it is not forwarded as the model credential. The selected single backend's managed identity credentials must supply the model-facing Authorization header.
- After APIM validates the subscription, the key does not need to reach the model account. Removing the header does not remove the already-resolved `context.Subscription`.
- `buffer-response="false"` avoids unnecessary buffering if SSE is enabled later. Initially test with `stream: false`.
- The 120-second value is an example response-header wait time, not a guarantee of end-to-end success.
- `fail-on-error-status-code="false"` preserves backend error responses for inspection. Do not mask failures with success-shaped responses.

### 4-B-3. Image API baseline

```xml
<policies>
  <inbound>
    <base />
    <set-header name="api-key" exists-action="delete" />
    <set-header name="Authorization" exists-action="delete" />
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
    <set-query-parameter name="subscription-key" exists-action="delete" />
    <set-backend-service backend-id="image-pool" />
  </inbound>
  <backend>
    <forward-request buffer-request-body="true"
                     fail-on-error-status-code="false"
                     timeout="240" />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```

Image generation can take time. `forward-request` timeout waits for response headers; documentation warns that values over 240 seconds might not be honored by the network. Check client/proxy limits separately instead of continually increasing the timeout.

**Do not automatically retry image-generation POST requests.** A timeout or 5xx can leave generation completion uncertain, creating duplicate images and charges. Check the client SDK's retry defaults as well.

### 4-B-4. Verify baseline calls first

Perform step 05's successful-call checks for both APIs before adding optional features. Add one feature at a time and repeat verification.

### Option A. Per-team text token limits

Use **2,000 TPM per APIM subscription** as the exercise starting point, matching the PDF's team example. This does not increase Azure OpenAI quota.

1. Insert the following immediately after `<base />` in the text API's `<inbound>`.
2. Confirm **Subscription required** is enabled and the test subscription is scoped to Text API.
3. Save and perform step 05's team-isolation tests.

```xml
<llm-token-limit
  counter-key="@(&quot;text:&quot; + context.Subscription.Id)"
  tokens-per-minute="2000"
  estimate-prompt-tokens="false"
  retry-after-header-name="Retry-After"
  remaining-tokens-header-name="x-ratelimit-remaining-tokens"
  tokens-consumed-header-name="x-tokens-consumed" />
```

- **Each team needs its own APIM subscription.** Do not use an arbitrary caller-controlled `x-pipeline-id` header as a trusted team boundary.
- The manually created HTTP API has no supplied request schema, so start with `estimate-prompt-tokens="false"` and actual response `usage`. To use the PDF's `true` setting, define/import a supported request schema and verify estimation.
- With `false`, consumption is updated after responses. In-flight calls can exceed the limit; this is not an exact pre-request spending cap.
- Streaming has different estimation behavior. Start with non-streaming requests.
- The same counter key can share a counter across policy scopes. The `text:` prefix separates its purpose; avoid duplicate limits across scopes.
- Exceeding TPM can return 429. A separately configured period token quota can return 403. Distinguish these from model-backend throttling.

### Option B. Image request-rate limits

Insert after `<base />` in Image API's `<inbound>`. **Five calls per minute is an exercise value**, not an exact measure of model tokens or cost.

```xml
<rate-limit-by-key
  calls="5"
  renewal-period="60"
  counter-key="@(&quot;image:&quot; + context.Subscription.Id)"
  retry-after-header-name="Retry-After"
  remaining-calls-header-name="x-ratelimit-remaining-requests" />
```

Distributed rate limits are approximate. Use a low test limit and a small number of calls rather than high concurrency.

### Option C. Retry backend text 429 once

First verify baseline calls and failover in step 05. Apply this only after approving combined client/gateway attempt counts and cost.

Replace **only the text API's `<backend>` block** with:

```xml
<backend>
  <retry condition="@(context.Response != null &amp;&amp; context.Response.StatusCode == 429)"
         count="1"
         interval="1"
         first-fast-retry="true">
    <set-backend-service backend-id="text-pool" />
    <forward-request buffer-request-body="true"
                     buffer-response="false"
                     fail-on-error-status-code="false"
                     timeout="120" />
  </retry>
</backend>
```

- Maximum backend attempts: **one initial attempt + one retry = two**.
- Re-select the pool inside every attempt. The primary's circuit must actually be open and the secondary available for a different backend to be selected.
- An APIM inbound token-limit 429 does not enter this backend retry block.
- This is not permission to ignore a backend's Retry-After and keep hitting it. It assumes circuit breaking and another available backend.
- Do not automatically retry 5xx or network timeouts; handle uncertain generation completion separately.
- Do not expect transparent retries after a streaming response has started reaching the client.
- Do not apply this block to image generation.

### Alternative: authenticate at API policy scope

Use this only if **explicitly choosing policy authentication instead of backend credentials**.

1. Disable managed identity credentials on both individual backends used by that API.
2. Insert the following **after** deleting Authorization and **before** `set-backend-service` in the API's inbound policy.
3. Account role assignments remain necessary. Verify Bearer-token forwarding in Trace without copying or logging the token itself.

```xml
<authentication-managed-identity
  resource="https://cognitiveservices.azure.com"
  ignore-error="false" />
```

Without `output-token-variable-name`, this policy sets Authorization. Deleting that header afterward removes the authentication.

**Choose one authentication location.** Do not change `ignore-error` to `true` to hide failures or hardcode a model key.

### Completion criteria

- [ ] Text API references `text-pool`; Image API references `image-pool`.
- [ ] Managed identity authentication is actually applied without conflicting duplication.
- [ ] Verify basic calls before testing each optional feature.
- [ ] Record configured limits, retry choice, and maximum attempts.
- [ ] Check inherited/operation policy conflicts and backend-scope override effects.

### Official documentation

- [Edit policies and choose scope](https://learn.microsoft.com/en-us/azure/api-management/set-edit-policies)
- [Backend managed identity credentials](https://learn.microsoft.com/en-us/azure/api-management/backends#configure-managed-identity-for-authorization-credentials)
- [authentication-managed-identity](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
- [forward-request and timeout limits](https://learn.microsoft.com/en-us/azure/api-management/forward-request-policy)
- [retry and execution counts](https://learn.microsoft.com/en-us/azure/api-management/retry-policy)
- [llm-token-limit support and estimation behavior](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [rate-limit-by-key](https://learn.microsoft.com/en-us/azure/api-management/rate-limit-by-key-policy)
