# 02. API 생성

[English](../../step-02-create-apis/README.md) | 한국어

[이전: APIM 생성](../step-01-prepare-resources/README.md) | [전체 목차](../README.md) | [다음: 관리 ID·백엔드](../step-03-backend-pools/README.md)

## 2-1. 텍스트 Language Model API 생성

1. APIM **APIs → APIs → + Add API → Language Model API**를 선택합니다.
2. **Configure API**를 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Display name | `Text API` |
| API 식별자, 편집 가능한 경우 | `text-api` |
| URL | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| Path | `text` |
| API 유형 | **Create OpenAI API** |

3. 정적 모델 키 인증은 비워 둡니다. 3단계에서 관리 ID·역할을 준비한 뒤 4단계에서 Managed Identity 인증 정책을 적용합니다.
4. **Manage token consumption**의 선택적 제한·메트릭은 초기 테스트 전에는 끕니다.
5. **Apply semantic caching**, **AI content safety**도 끕니다.
6. **Review → Create**를 선택합니다.
7. **Text API → Settings**에서 HTTPS, suffix `text`, **Subscription required = On**을 확인합니다.
8. **Design**에서 자동 생성된 **POST `/chat/completions`** 작업을 선택합니다.
9. Query parameter `api-version`에 1단계의 텍스트 API 버전을, 요청 content type에 `application/json`을 추가하거나 확인합니다.

입력 URL은 배포 기본 주소입니다. `/chat/completions`나 버전 쿼리를 뒤에 붙이지 않습니다.

## 2-2. 자동 생성 텍스트 백엔드 기록

1. Text API 정책 편집기에서 자동 생성된 `set-backend-service`를 찾습니다.
2. 해당 `backend-id`를 기록합니다.
3. **APIs → Backends**에서 같은 백엔드를 엽니다.
4. 실제 ID와 런타임 URL을 기록합니다.

이 백엔드가 **Text A**입니다. 문서의 `<generated-text-backend-id>`에는 실제 ID를 사용합니다. 3단계에서는 Text B와 이미지 백엔드 두 개만 추가합니다.

| 항목 | 텍스트 설정값 |
| --- | --- |
| Text A 백엔드 기본 URL | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| 자동 생성 작업 | `POST /chat/completions` |
| 클라이언트 경로 | `/text/chat/completions?api-version=<text-version>` |

백엔드 기본 URL과 작업을 연결했을 때 모델이 지원하는 URL이 되고 배포 경로가 한 번만 포함되는지 확인합니다.

## 2-3. 이미지 일반 HTTP API 생성

1. **APIs → APIs → + Add API → HTTP**를 선택합니다.
2. 다음을 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Scheme | HTTPS |
| Subscription required | On |

3. **Create**를 선택합니다.
4. **Design → + Add operation**에서 다음을 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Display name / Name | `Generate image` / `generate-image` |
| Method | `POST` |
| URL | `/deployments/<image-deployment>/images/generations` |
| Query parameter | `api-version`, 1단계의 이미지 API 버전 |
| Request content type | `application/json` |

5. 작업을 저장합니다.

이미지 백엔드 기본 URL은 `/openai`에서 끝나며 작업에 배포 경로가 포함됩니다. 두 이미지 계정의 배포 이름은 같은 값을 사용합니다.

## 완료 기준

- [ ] 텍스트는 Language Model API와 자동 생성 chat completions 작업을 사용한다.
- [ ] 자동 생성 Text A 백엔드 ID를 기록했다.
- [ ] 이미지는 일반 HTTP API와 수동 추가한 이미지 생성 작업을 사용한다.
- [ ] 두 API 모두 APIM 구독을 요구한다. 테스트 전 3단계로 진행한다.

## 공식 문서

- [Language Model API 가져오기](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)
- [HTTP API와 작업 생성](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [이미지 생성 API](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
