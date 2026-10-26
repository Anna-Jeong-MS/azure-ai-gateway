# 02. Create the text and image APIs

English | [Korean](../kr/step-02-create-apis/README.md)

[Previous: existing models and APIM](../step-01-prepare-resources/README.md) | [Contents](../README.md) | [Next: identity, backends, and pools](../step-03-backend-pools/README.md)

## 2-A. Create the text Language Model API

### Prerequisites and fixed choices

Step 01 has prepared **Standard v2 APIM with public access** and recorded the already-deployed models. Create the APIs now; configure or verify identity, roles, and backend credentials in step 03. Do not test an unauthenticated backend yet.

| API | Portal creation tile | Backend handling |
| --- | --- | --- |
| Text API | **Language Model API > Create OpenAI API** | Reuse its one automatically generated backend as Text Primary |
| Image API | **HTTP** (regular API) | Manually create its two single backends in step 03 |

Use actual existing deployment names instead of the examples `gpt-55` and `gpt-image-25-flare`. These steps create APIM APIs, not model deployments.

### 2-A-1. Open the Language Model API wizard

1. Open the APIM instance immediately after completing step 01.
2. Select **APIs > APIs > + Add API**.
3. Under **Define a new API**, select **Language Model API**. **Do not use HTTP for text.**
4. On **Configure API**, enter:

| Field | Value |
| --- | --- |
| Display name | `Text API` |
| API identifier, if editable | `text-api` |
| URL | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55` |
| Path | `text` |
| API type | **Create OpenAI API**, not passthrough |
| Static API key | Do not supply one for this managed-identity design |

The URL is the existing Text A deployment base. Do not append `/chat/completions` or `?api-version=...` here. The generated operation supplies `/chat/completions`.

5. If the wizard offers managed identity and APIM already has it enabled, select the system-assigned identity. Otherwise leave static key authentication unset and complete managed identity configuration in step 03 before testing.
6. Select **Next** and review **Manage token consumption**, **Apply semantic caching**, and **AI content safety**. Leave optional features off for baseline testing; do not enable features needing unprepared resources.
7. Select **Review > Create**.

### 2-A-2. Record the generated API and backend

1. Open **Text API > Settings** and confirm suffix `text`, HTTPS, and **Subscription required = On**.
2. In **Design**, find the generated **POST `/chat/completions`** operation. Its display name can vary. Do not add a duplicate manual text operation.
3. In the operation's query parameters, add or confirm the date-based `api-version` supported by the existing deployment.
4. Open the policy editor and record the ID referenced by the generated `set-backend-service`.
5. Open **APIs > Backends**, find that same single backend, and record its actual ID, runtime URL, and authentication settings.
6. Use this generated backend as Text Primary. In subsequent documents, **`<generated-text-backend-id>` means the actual recorded ID**, not a name to type literally.

**Do not create an extra `text-aoai-01`, and do not import Text B as another API just to create a backend.** Step 03 adds only Text Secondary and the two image backends.

Reference URL layout:

```text
Generated Text Primary backend:
https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55

Generated text operation:
POST /chat/completions

Client URL:
https://<apim-name>.azure-api.net/text/chat/completions?api-version=<text-version>
```

If generated settings differ, inspect the backend URL and operation together before proceeding. The final upstream URL must contain `/openai/deployments/<actual-name>/chat/completions` exactly once. Do not mix this date-based layout with a v1 endpoint.

---

## 2-B. Create the image regular HTTP API

### 2-B-1. Create the API

1. Select **APIs > APIs > + Add API > HTTP**. **Do not select Language Model API for images.**
2. Enter:

| Field | Value |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Scheme | HTTPS |
| Subscription required | On |

3. Select **Create**, then confirm the settings under **Settings**.

### 2-B-2. Add the image operation

1. Select **Design > + Add operation**.
2. Set **Display name / Name** to `Generate image` / `generate-image`.
3. Set **Method** to `POST`.
4. Set **URL** to `/deployments/gpt-image-25-flare/images/generations`, replacing the deployment name with its actual existing value.
5. Add/confirm query parameter `api-version` from the image deployment's portal sample.
6. Set request content type to `application/json` and save.

```text
Image backend base:
https://<image-account-a>.openai.azure.com/openai

Image operation:
POST /deployments/gpt-image-25-flare/images/generations

Client URL:
https://<apim-name>.azure-api.net/image/deployments/gpt-image-25-flare/images/generations?api-version=<image-version>
```

The image API is a regular API with an explicitly added operation. Do not assume the text wizard created its backend credentials or pool. Step 03 creates the image backends; step 04 replaces the initial primary URL with `image-pool`.

### Completion criteria

- [ ] Text was created with **Language Model API**, and its generated chat-completions operation is present.
- [ ] Record the generated Text Primary backend's actual ID; do not create a duplicate.
- [ ] Image was created with the **HTTP** tile and an explicit image-generation POST operation.
- [ ] Record suffixes, operation paths, deployment names, and the two API versions.
- [ ] Both APIs require subscriptions; defer final calls until identity, routing, and test subscriptions are ready.

### Official documentation

- [Import Language Model API: generated backend and route](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)
- [Manually add a regular HTTP API and operations](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [Managed identity authentication policy](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [Image-generation API examples](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
