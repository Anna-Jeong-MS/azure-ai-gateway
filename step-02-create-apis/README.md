# 02. Create APIs

English | [Korean](../kr/step-02-create-apis/README.md)

[Previous: create APIM](../step-01-prepare-resources/README.md) | [Contents](../README.md) | [Next: identity and backends](../step-03-backend-pools/README.md)

## 2-1. Create the text Language Model API

1. Open APIM **APIs > APIs > + Add API > Language Model API**.
2. On **Configure API**, enter:

| Field | Value |
| --- | --- |
| Display name | `Text API` |
| API identifier, if editable | `text-api` |
| URL | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| Path | `text` |
| API type | **Create OpenAI API** |

3. Leave static model-key authentication unset. Managed Identity is applied in step 04 after enabling the identity and assigning roles in step 03.
4. On **Manage token consumption**, leave optional limits and metrics disabled for the initial test.
5. Leave **Apply semantic caching** and **AI content safety** disabled.
6. Select **Review > Create**.
7. Open **Text API > Settings** and confirm HTTPS, suffix `text`, and **Subscription required = On**.
8. In **Design**, select the generated **POST `/chat/completions`** operation.
9. Add/confirm query parameter `api-version` using the text API version from step 01, and request content type `application/json`.

The URL entered above is the deployment base: do not append `/chat/completions` or the version query to it.

## 2-2. Record the automatic text backend

1. Open the Text API policy editor and find the generated `set-backend-service`.
2. Record its `backend-id`.
3. Open **APIs > Backends** and select that backend.
4. Record its actual ID and runtime URL.

This is **Text Primary**. Use its actual ID wherever this guide shows `<generated-text-backend-id>`. Step 03 creates only Text Secondary and the two image backends.

| Item | Text value |
| --- | --- |
| Primary backend base | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| Generated operation | `POST /chat/completions` |
| Client path | `/text/chat/completions?api-version=<text-version>` |

Confirm that the backend base plus operation forms the model's supported URL, with the deployment path included only once.

## 2-3. Create the image regular HTTP API

1. Select **APIs > APIs > + Add API > HTTP**.
2. Enter:

| Field | Value |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Scheme | HTTPS |
| Subscription required | On |

3. Select **Create**.
4. Open **Design > + Add operation** and enter:

| Field | Value |
| --- | --- |
| Display name / Name | `Generate image` / `generate-image` |
| Method | `POST` |
| URL | `/deployments/<image-deployment>/images/generations` |
| Query parameter | `api-version`, using the image API version from step 01 |
| Request content type | `application/json` |

5. Save the operation.

The image backend base ends at `/openai`; the operation supplies the deployment path. Use the same image deployment name in both image accounts.

## Completion criteria

- [ ] Text uses Language Model API and its generated chat-completions operation.
- [ ] Record the automatically generated Text Primary backend ID.
- [ ] Image uses the regular HTTP API and the manually added image-generation operation.
- [ ] Both APIs require an APIM subscription. Continue to step 03 before testing.

## Official documentation

- [Import Language Model API](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)
- [Create an HTTP API and operations](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [Image-generation API](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
