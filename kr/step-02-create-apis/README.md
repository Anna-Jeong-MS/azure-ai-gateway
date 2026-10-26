# 02. 텍스트·이미지 API 생성

[English](../../step-02-create-apis/README.md) | 한국어

[이전: 기존 모델 확인과 APIM 준비](../step-01-prepare-resources/README.md) | [전체 목차](../README.md) | [다음: 관리 ID·백엔드·풀](../step-03-backend-pools/README.md)

## 2-A. 텍스트 Language Model API 생성

### 시작 조건과 확정 기준

1단계에서 **Standard v2 APIM을 공용 접근으로 준비**하고 기존 배포 모델 정보를 기록했습니다. 바로 API를 생성하고 3단계에서 관리 ID·역할을, 4단계에서 API 정책 인증을 설정합니다. 인증이 준비되지 않은 백엔드는 아직 테스트하지 않습니다.

| API | 포털 생성 타일 | 백엔드 처리 |
| --- | --- | --- |
| Text API | **Language Model API → Create OpenAI API** | 자동 생성 백엔드 1개를 Text Primary로 재사용 |
| Image API | **HTTP** (일반 API) | 3단계에서 단일 백엔드 2개를 수동 생성 |

예시 `gpt-55`, `gpt-image-25-flare` 대신 실제 기존 배포 이름을 사용합니다. APIM API를 만드는 작업이며 모델을 배포하지 않습니다.

### 2-A-1. Language Model API 마법사 열기

1. 1단계를 마친 APIM 인스턴스를 엽니다.
2. **APIs → APIs → + Add API**를 선택합니다.
3. **Define a new API → Language Model API**를 선택합니다. **텍스트는 HTTP를 사용하지 않습니다.**
4. **Configure API**에서 다음 값을 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Display name | `Text API` |
| API 식별자, 편집 가능한 경우 | `text-api` |
| URL | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55` |
| Path | `text` |
| API 유형 | **Create OpenAI API**, passthrough 미사용 |
| 정적 API 키 | 이번 관리 ID 구성에서는 입력하지 않음 |

URL은 기존 Text A 배포의 기본 주소입니다. `/chat/completions`나 `?api-version=...`는 붙이지 않습니다. 생성되는 작업이 `/chat/completions`를 제공합니다.

5. 정적 모델 키는 입력하지 않습니다. 관리 ID 선택이 제공되고 이미 활성화했다면 생성되는 인증 설정을 기록합니다. 그렇지 않으면 정적 인증을 비워 둡니다. 테스트 전 3단계의 관리 ID·역할과 4단계의 전체 API 정책 인증을 완성하며 백엔드 Managed identity 탭은 필요하지 않습니다.
6. **Next**를 선택하여 **Manage token consumption**, **Apply semantic caching**, **AI content safety**를 검토합니다. 기본 호출 검증 전에는 선택 기능을 끄고 준비되지 않은 리소스에 의존하는 옵션을 활성화하지 않습니다.
7. **Review → Create**를 선택합니다.

### 2-A-2. 생성된 API와 백엔드 기록

1. **Text API → Settings**에서 suffix `text`, HTTPS, **Subscription required = On**을 확인합니다.
2. **Design**에서 생성된 **POST `/chat/completions`** 작업을 찾습니다. 표시 이름은 다를 수 있습니다. 수동 텍스트 작업을 중복 추가하지 않습니다.
3. 작업의 Query parameters에 기존 배포가 지원하는 날짜형 `api-version`을 추가하거나 확인합니다.
4. 정책 편집기에서 자동 생성 `set-backend-service`가 참조하는 ID를 기록합니다.
5. **APIs → Backends**에서 같은 단일 백엔드를 찾아 실제 ID·런타임 URL·인증 설정을 기록합니다.
6. 이 백엔드를 Text Primary로 사용합니다. 이후 문서의 **`<generated-text-backend-id>`는 기록한 실제 ID**이며 그대로 입력할 이름이 아닙니다.

**`text-aoai-01`을 별도 추가하지 않으며 백엔드를 만들기 위해 Text B를 다른 API로 가져오지도 않습니다.** 3단계에서는 Text Secondary와 이미지 백엔드 두 개만 추가합니다.

기준 URL 구성:

```text
자동 생성 Text Primary 백엔드:
https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55

생성된 텍스트 작업:
POST /chat/completions

클라이언트 URL:
https://<apim-name>.azure-api.net/text/chat/completions?api-version=<text-version>
```

생성된 설정이 다르면 백엔드 URL과 작업을 함께 확인한 뒤 진행합니다. 최종 업스트림 URL에 `/openai/deployments/<실제 이름>/chat/completions`가 한 번만 있어야 합니다. 날짜형 구성과 v1 엔드포인트를 혼합하지 않습니다.

---

## 2-B. 이미지 일반 HTTP API 생성

### 2-B-1. API 생성

1. **APIs → APIs → + Add API → HTTP**를 선택합니다. **이미지는 Language Model API를 선택하지 않습니다.**
2. 다음 값을 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Scheme | HTTPS |
| Subscription required | On |

3. **Create**를 선택하고 **Settings**에서 저장된 값을 확인합니다.

### 2-B-2. 이미지 작업 추가

1. **Design → + Add operation**을 선택합니다.
2. **Display name / Name**을 `Generate image` / `generate-image`로 지정합니다.
3. **Method**는 `POST`로 지정합니다.
4. **URL**에 `/deployments/gpt-image-25-flare/images/generations`를 입력하되 배포 이름은 실제 기존 값으로 바꿉니다.
5. 이미지 배포 포털 샘플의 Query parameter `api-version`을 추가하거나 확인합니다.
6. 요청 content type을 `application/json`으로 지정하고 저장합니다.

```text
이미지 백엔드 기본 URL:
https://<image-account-a>.openai.azure.com/openai

이미지 작업:
POST /deployments/gpt-image-25-flare/images/generations

클라이언트 URL:
https://<apim-name>.azure-api.net/image/deployments/gpt-image-25-flare/images/generations?api-version=<image-version>
```

이미지는 작업을 명시적으로 추가하는 일반 API입니다. 텍스트 마법사가 이미지 백엔드 인증이나 풀까지 만들었다고 가정하지 않습니다. 3단계에서 이미지 백엔드를 만들고 4단계에서 초기 Primary URL 대신 `image-pool`로 라우팅합니다.

### 완료 기준

- [ ] 텍스트는 **Language Model API**로 생성했고 chat completions 작업이 있다.
- [ ] 자동 생성 Text Primary 백엔드의 실제 ID를 기록했으며 중복 생성하지 않았다.
- [ ] 이미지는 **HTTP** 타일로 만들고 이미지 생성 POST 작업을 명시적으로 추가했다.
- [ ] suffix·작업 경로·배포 이름·텍스트/이미지 API 버전을 기록했다.
- [ ] 두 API 모두 구독을 요구하며 인증·라우팅·테스트 구독 준비 전에는 최종 호출을 하지 않는다.

### 공식 문서

- [Language Model API 가져오기: 자동 백엔드와 라우팅](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)
- [일반 HTTP API와 작업 수동 추가](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [관리 ID 인증 정책](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [이미지 생성 API 예시](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
