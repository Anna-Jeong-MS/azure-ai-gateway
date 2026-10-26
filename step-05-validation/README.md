# 05. Test the gateway

English | [Korean](../kr/step-05-validation/README.md)

[Previous: apply policies](../step-04-api-policies/README.md) | [Contents](../README.md)

## 5-1. Test Text API

1. Open **APIs > APIs > Text API > Test**.
2. Select the generated **POST `/chat/completions`** operation.
3. Set the text `api-version` from step 01.
4. Replace the portal's default all-access subscription key with the **Text API-scoped `text-test` key**.
5. Enter the headers and body below, then select **Trace**.

```http
POST /text/chat/completions?api-version=<text-version> HTTP/1.1
Host: <apim-name>.azure-api.net
Ocp-Apim-Subscription-Key: <text-api-subscription-key>
Content-Type: application/json

{
  "messages": [{"role": "user", "content": "Reply with OK only."}],
  "max_completion_tokens": 1024,
  "stream": false
}
```

6. Confirm HTTP 200 and response `choices` and `usage`. Check `finish_reason` if visible text is empty.
7. In **Trace > Inbound / Backend**, verify Managed Identity authentication and the selected backend.
8. Confirm the final model URL is `https://<text-account>.openai.azure.com/openai/deployments/<text-deployment>/chat/completions?api-version=<text-version>`, with the deployment path included once.

## 5-2. Test Image API

1. Open **Image API > Test > Generate image**.
2. Enter the image API version, **Image API-scoped `image-test` key**, and request below.
3. Select **Trace**.

```http
POST /image/deployments/<image-deployment>/images/generations?api-version=<image-version> HTTP/1.1
Host: <apim-name>.azure-api.net
Ocp-Apim-Subscription-Key: <image-api-subscription-key>
Content-Type: application/json

{
  "prompt": "A simple blue circle on a white background.",
  "n": 1,
  "size": "1024x1024"
}
```

4. Confirm HTTP 200 and actual image output in `data`.
5. Verify the selected image backend, Managed Identity authentication, and final `/openai/deployments/<image-deployment>/images/generations` path.

For both APIs, the client supplies only its APIM key. Verify the key is not forwarded to the model and APIM supplies the model-facing Authorization. Do not copy or log token values.

## 5-3. Test access controls

| Test | Expected result |
| --- | --- |
| Correct API-scoped key | Successful model response |
| Missing/invalid APIM key | Rejected by APIM, normally 401; no model call |
| Text API-scoped key against Image API | Rejected |
| Unexposed operation path | APIM 404 |

For failures, inspect the Trace stage and error body. Check APIM key/scope for gateway 401; identity, account roles, and audience for model 401/403; public network access and account rules for connectivity failures.

## 5-4. Verify all four backends

Use the baseline policies without the optional retry while testing individual backends.

1. Temporarily change Text API's `set-backend-service` to the actual generated Text Primary ID and test.
2. Change it to `text-aoai-02` and test.
3. Restore `text-pool`.
4. Repeat for `image-aoai-01` and `image-aoai-02`, then restore `image-pool`.
5. Verify both effective policies reference the pools.

## 5-5. Test optional limits and failover

- **Text token limit:** Create a second Text API-scoped subscription for another team. With a low test limit and a few requests, verify APIM's 429 and separate counters. With estimation off, usage is updated after responses.
- **Image rate limit:** Temporarily lower the request limit, use a small number of calls, and inspect remaining-request headers and APIM 429. Restore the approved value afterward.
- **Failover:** In an approved isolated test environment, use organization-controlled endpoints: Primary returns 429 with `Retry-After: 60`, Secondary returns an identifiable success. Use separate test backends/pool/API without model-token policies or credentials, and strip client credentials before forwarding. Verify subsequent requests move to Secondary after the circuit trips and return to Primary after recovery. Do not exhaust production model quota.
- **Text retry:** If enabled, confirm no more than two backend attempts for one request. A gateway-limit 429 is not a backend retry test.

Record failover as not performed if controlled test endpoints are unavailable. Do not treat a settings screen as proof of failover.

## 5-6. Configure monitoring

1. Connect the approved Application Insights resource through APIM **Application Insights > Add**.
2. Under each API's **Settings > Diagnostics**, configure the logger and sampling.
3. Keep body and secret-header collection disabled. Monitor latency, error rate, and 429/503 responses.

## Completion criteria

- [ ] Both APIs accept their APIM subscription keys and use Managed Identity for model access.
- [ ] All four individual backends and final pool routes work.
- [ ] Record optional test results and restore the approved limits, pool routes, and retry settings.

## Official documentation

- [Portal request tracing](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector)
- [Backend pools and circuit breakers](https://learn.microsoft.com/en-us/azure/api-management/backends)
- [Token-limit behavior](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [Application Insights integration](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights)
