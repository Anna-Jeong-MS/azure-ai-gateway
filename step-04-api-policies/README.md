# 04. Apply policies

English | [Korean](../kr/step-04-api-policies/README.md)

[Previous: identity and backends](../step-03-backend-pools/README.md) | [Contents](../README.md) | [Next: test the gateway](../step-05-validation/README.md)

## 4-1. Create API-scoped subscriptions

1. Open APIM **Subscriptions > + Add subscription**.
2. Create the following subscriptions with state **Active**:

| Name | Scope |
| --- | --- |
| `text-test` | API > Text API |
| `image-test` | API > Image API |

3. Confirm **Subscription required = On** in both APIs' **Settings**.
4. Retrieve each subscription key when testing. Clients send it in `Ocp-Apim-Subscription-Key`; they do not send a model account key or a managed identity token.

## 4-2. Apply the Text API policy

1. Open **APIs > APIs > Text API > Design > All operations > `</>`**.
2. Replace the API policy with the following and select **Save**. Keep the generated operation and request schema.
3. Select **Calculate effective policy** and confirm the final route is `text-pool`, including at the operation scope.

```xml
<policies>
  <inbound>
    <base />
    <set-header name="api-key" exists-action="delete" />
    <set-header name="Authorization" exists-action="delete" />
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
    <set-query-parameter name="subscription-key" exists-action="delete" />
    <authentication-managed-identity
      resource="https://cognitiveservices.azure.com"
      ignore-error="false" />
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

This replaces the automatic single-backend route with the text pool. APIM validates the client subscription key before inbound policy execution, strips client credentials, and obtains the model token using its system-assigned identity. Do not delete or overwrite Authorization after `authentication-managed-identity`.

## 4-3. Apply the Image API policy

1. Open **APIs > APIs > Image API > Design > All operations > `</>`**.
2. Apply the policy below and save.
3. Confirm the effective route is `image-pool`.

```xml
<policies>
  <inbound>
    <base />
    <set-header name="api-key" exists-action="delete" />
    <set-header name="Authorization" exists-action="delete" />
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
    <set-query-parameter name="subscription-key" exists-action="delete" />
    <authentication-managed-identity
      resource="https://cognitiveservices.azure.com"
      ignore-error="false" />
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

The timeout waits for response headers; values above 240 seconds might not be honored by the network. Image generation is not automatically retried because uncertain completion can cause duplicate generation and charges.

## 4-4. Optional usage limits

After basic calls succeed in step 05, add each selected policy immediately after `<base />` in the API's inbound section.

### Text: 2,000 tokens per minute per subscription

```xml
<llm-token-limit
  counter-key="@(&quot;text:&quot; + context.Subscription.Id)"
  tokens-per-minute="2000"
  estimate-prompt-tokens="false"
  retry-after-header-name="Retry-After"
  remaining-tokens-header-name="x-ratelimit-remaining-tokens"
  tokens-consumed-header-name="x-tokens-consumed" />
```

Use a separate APIM subscription per team. With prompt estimation disabled, consumption is recorded from response `usage`; concurrent requests can exceed the limit before subsequent requests are blocked.

### Images: five requests per minute per subscription

```xml
<rate-limit-by-key
  calls="5"
  renewal-period="60"
  counter-key="@(&quot;image:&quot; + context.Subscription.Id)"
  retry-after-header-name="Retry-After"
  remaining-calls-header-name="x-ratelimit-remaining-requests" />
```

These are example limits, not guaranteed spending caps. Rate limiting is approximate across distributed gateways.

## 4-5. Optional text retry on backend 429

For one text retry, replace only the Text API's `<backend>` section with:

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

This permits at most **two backend attempts** per request. A different backend is selected only when the pool's circuit state and availability allow it. APIM inbound-limit 429 responses do not enter this retry. Do not apply it to images, 5xx, timeouts, or a stream that has already started.

## Completion criteria

- [ ] Both APIs require API-scoped subscription keys.
- [ ] Each API uses one effective inbound Managed Identity authentication policy.
- [ ] Effective routes point to `text-pool` and `image-pool`.
- [ ] Optional limits and retry counts are recorded and tested.

## Official documentation

- [Subscriptions and keys](https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions)
- [Edit policies](https://learn.microsoft.com/en-us/azure/api-management/set-edit-policies)
- [Managed Identity authentication](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
- [forward-request](https://learn.microsoft.com/en-us/azure/api-management/forward-request-policy)
- [Token limits](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [Request rate limits](https://learn.microsoft.com/en-us/azure/api-management/rate-limit-by-key-policy)
- [Retries](https://learn.microsoft.com/en-us/azure/api-management/retry-policy)
