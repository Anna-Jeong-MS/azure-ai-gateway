# 04. API 구성과 정책 적용

[English](../../step-04-api-policies/README.md) | 한국어

[이전: 03. 백엔드와 부하 분산 풀](../step-03-backend-pools/README.md) | [전체 목차](../README.md) | [다음: 05. 검증과 운영 점검](../step-05-validation/README.md)

## 4-A. 텍스트·이미지 API와 APIM 구독 구성


### 목표와 시작 조건

풀마다 별도 HTTP API를 만들고 작업을 명시적으로 노출합니다. API 분리는 기술적 필수 사항이 아니라 이번 실습의 정책·운영 경계입니다.

1단계의 직접 호출 성공, 두 풀과 단일 백엔드의 저장 상태를 먼저 확인합니다.

### 4-A-1. 텍스트 HTTP API 생성

1. APIM **APIs → APIs → + Add API → HTTP**를 선택합니다.
2. 다음을 입력합니다.

| 필드 | 입력 |
| --- | --- |
| Display name | `Text API` |
| Name | `text-api` |
| Web service URL | `https://<text-account-a>.openai.azure.com/openai` |
| API URL suffix | `text` |
| URL scheme | HTTPS |
| Subscription required | On |

3. 생성 후 **Settings**에서 Subscription required가 켜져 있는지 확인합니다. 기본 Backend URL은 임시 기본값이며 4단계 정책에서 풀로 대체합니다.
4. **Design → + Add operation**을 선택합니다.
5. 다음 작업을 생성합니다.

| 필드 | 입력 |
| --- | --- |
| Display name | `Create chat completion` |
| Name | `create-chat-completion` |
| Method | `POST` |
| URL | `/deployments/gpt-55/chat/completions` |
| Query parameter | `api-version`, 1단계에서 확인한 텍스트 버전 |
| Request content type | `application/json` |

6. Query parameter의 예시/기본값을 실제 지원 버전으로 입력합니다. 클라이언트도 `api-version`을 보내도록 안내합니다.
7. 최소 요청 예시는 다음과 같습니다. 선택한 모델의 직접 호출에서 확인한 필드만 사용합니다.

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

이 실습은 배포 이름이 들어간 **고정 작업 경로**를 사용합니다. 임의의 배포를 노출하는 와일드카드 작업은 만들지 않습니다.

### 4-A-2. 이미지 HTTP API 생성

같은 방식으로 API와 작업을 생성합니다.

| 필드 | 입력 |
| --- | --- |
| Display name / Name | `Image API` / `image-api` |
| Web service URL | `https://<image-account-a>.openai.azure.com/openai` |
| API URL suffix | `image` |
| Subscription required | On |
| Operation display name / Name | `Generate image` / `generate-image` |
| Method | `POST` |
| URL | `/deployments/gpt-image-25-flare/images/generations` |
| Query parameter | `api-version`, 1단계에서 확인한 이미지 버전 |
| Request content type | `application/json` |

최소 요청 예시입니다. 실제 모델의 지원 옵션을 직접 호출 결과와 대조합니다.

```json
{
  "prompt": "A simple blue circle on a white background.",
  "n": 1,
  "size": "1024x1024"
}
```

### 4-A-3. 경로 조합 확인

APIM은 API suffix를 클라이언트 경로에 사용하고, 선택된 백엔드 base URL에 작업 경로를 연결합니다.

| 구간 | 텍스트 예 |
| --- | --- |
| 클라이언트 → APIM | `https://<apim>.azure-api.net/text/deployments/gpt-55/chat/completions?api-version=<text-version>` |
| APIM → Text A | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-version>` |
| APIM → Text B | 위와 같은 경로·쿼리, 호스트만 Text B |

이미지 클라이언트 URL:

```text
https://<apim>.azure-api.net/image/deployments/gpt-image-25-flare/images/generations?api-version=<image-version>
```

별도의 `rewrite-uri`는 필요하지 않습니다. 상위 정책에 URL 재작성이나 `api-version` 변경이 있다면 **Calculate effective policy**와 Trace로 최종 경로를 확인합니다.

### 4-A-4. API별 테스트 구독 생성

1. APIM **Subscriptions → + Add subscription**을 선택합니다.
2. 이름을 `text-test`로 지정하고 **Scope → API → Text API**를 선택합니다.
3. 상태가 **Active**인지 확인합니다.
4. `image-test`도 만들고 **Image API**로 범위를 지정합니다.
5. 각 구독의 키는 Portal에서 필요한 때만 확인하고 비밀 저장소 또는 테스트 세션 메모리에만 보관합니다.
6. 키를 문서·커밋·스크린샷에 남기지 않습니다.

여기서 말하는 구독은 Azure Subscription이 아니라 **APIM Subscription**입니다. 두 API를 한 제품으로 묶어 제공할 때는 Product 범위 구독을 사용할 수도 있지만, 이 실습은 API 범위 구독으로 혼동을 줄입니다.

팀별 토큰 분리를 검증할 때는 5단계에서 Text API 구독을 하나 더 만듭니다. 공유된 키 하나를 여러 팀이 사용하면 팀별 제한이 분리되지 않습니다.

### 참고: 텍스트 v1 API로 변경하는 경우

기본 절차는 날짜형 API입니다. 실제 배포에서 v1을 선택했다면 텍스트의 모든 연결 지점을 함께 변경하고 별도로 검증합니다.

| 항목 | 기본: 배포 경로 API | v1 텍스트 대안 |
| --- | --- | --- |
| 두 텍스트 백엔드 Runtime URL | `https://<account>.openai.azure.com/openai` | `https://<account>.openai.azure.com/openai/v1` |
| Text API Web service URL | 위 Primary URL | 위 v1 Primary URL |
| Operation URL | `/deployments/gpt-55/chat/completions` | `/chat/completions` |
| 배포 선택 | URL의 `gpt-55` | JSON 본문의 `"model": "gpt-55"` |
| Query | 날짜형 `api-version` 필수 | v1 GA에서 날짜형 버전 불필요 |
| APIM 호출 경로 | `/text/deployments/gpt-55/chat/completions` | `/text/chat/completions` |

풀 이름과 관리 ID 방식은 유지합니다. 이 전환 표를 이미지 API 지원의 근거로 사용하지 않습니다. 이미지도 v1로 바꾸려면 해당 이미지 모델의 공식 API·요청 스키마를 별도 확인해야 합니다.

### 완료 기준

- [ ] API 두 개가 있고 각각 POST 작업이 하나씩 저장되었다.
- [ ] 백엔드 URL + 작업 경로가 직접 호출 성공 URL과 일치한다.
- [ ] API별 Active 상태의 구독이 있다.
- [ ] 텍스트·이미지의 API 버전과 키를 혼동하지 않았다.

이 단계에서 API를 호출하면 기본 Primary URL로 갈 수 있습니다. **풀 라우팅 완료 판정은 4단계 정책 적용 이후**에 합니다.

### 공식 문서

- [HTTP API와 작업 수동 생성](https://learn.microsoft.com/en-us/azure/api-management/add-api-manually)
- [APIM 구독의 범위와 키](https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions)
- [이미지 생성 API 예시](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [Azure OpenAI v1과 날짜형 API의 차이](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)
- [v1 Chat API와 인증](https://learn.microsoft.com/en-us/rest/api/microsoft-foundry/azureopenai/chat?view=rest-microsoft-foundry-v1)

---

## 4-B. 풀 라우팅·인증·제한 정책 적용


### 목표와 시작 조건

API를 올바른 풀로 보내고, 기본 호출 성공 후 선택 기능을 단계적으로 추가합니다. 이 문서의 XML을 사용하며 루트의 기존 로컬 정책 파일은 수정하지 않습니다.

**기본 인증은 3단계의 개별 백엔드 Managed identity 설정입니다.** API Subscription required는 On이어야 합니다.

### 4-B-1. 적용 위치와 기존 정책 확인

1. APIM **APIs → APIs → Text API → Design → All operations**를 선택합니다.
2. 정책 코드 편집기 **`</>`**를 엽니다.
3. 기존 정책은 승인된 로컬 기록에 보관하고, 상위/global/product/operation 정책과 충돌하는 인증·라우팅·재시도가 없는지 확인합니다.
4. 아래 Text API 기본 정책을 적용하고 **Save**를 선택합니다.
5. **Calculate effective policy**로 유효 정책을 확인합니다. 라우팅이나 인증을 덮어쓰는 작업별 정책이 있으면 영향도를 확인한 뒤 정리합니다.
6. Image API에도 별도의 기본 정책을 적용합니다.

`<base />`는 상위 정책 상속을 의미합니다. 아래 예시의 `<backend>`에는 직접 `forward-request`를 정의하므로 `<base />`를 함께 추가하지 않습니다. 전역 backend 정책에 필수 처리가 있다면 이를 생략하는 영향도를 검토하고 보존해야 합니다.

### 4-B-2. Text API 기본 정책

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

- `Authorization` 삭제는 **클라이언트가 보낸 토큰을 모델 계정으로 그대로 전달하지 않기 위한 것**입니다. 선택된 단일 백엔드의 Managed identity 자격이 모델 호출용 Authorization을 생성해야 합니다.
- APIM 구독 검증 후에는 구독 키를 모델 계정에 전달할 필요가 없습니다. 삭제하더라도 이미 확인된 `context.Subscription`은 정책에서 사용할 수 있습니다.
- `buffer-response="false"`는 추후 SSE 응답이 지연되지 않도록 지정한 값입니다. 초기 검증은 `stream: false`로 수행합니다.
- 120초는 예시 응답 헤더 대기 시간이며 요청 전체의 성공을 보장하지 않습니다.
- 백엔드 4xx/5xx를 원래 오류로 확인하도록 `fail-on-error-status-code="false"`를 사용합니다. 성공 응답으로 바꾸거나 오류를 숨기지 않습니다.

### 4-B-3. Image API 기본 정책

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

이미지 생성은 느릴 수 있습니다. `forward-request` timeout은 응답 헤더 대기 시간이며, 공식 문서는 240초를 넘는 값이 네트워크에서 보장되지 않는다고 안내합니다. 클라이언트/프록시 제한도 별도 확인하고 타임아웃을 단순히 무한히 늘리지 않습니다.

**이미지 생성 POST는 자동 재시도하지 않습니다.** 타임아웃이나 5xx 뒤에 실제 생성이 완료되었는지 불명확할 수 있어 중복 생성·과금 위험이 있습니다. 클라이언트 SDK의 기본 재시도도 함께 확인합니다.

### 4-B-4. 기본 호출 먼저 검증

5단계의 정상 호출 절차만 먼저 수행해 텍스트·이미지 각각 성공을 확인합니다. 다음 선택 기능은 한 번에 하나씩 추가하고 호출 결과를 다시 확인합니다.

### 선택 A. 팀별 텍스트 토큰 제한

PDF의 팀별 제한 예시와 맞춰 실습 시작값을 **구독당 2,000 TPM**으로 둡니다. Azure OpenAI 모델 쿼터를 늘리는 설정은 아닙니다.

1. Text API 기본 정책의 `<inbound>`에서 `<base />` 다음에 아래 조각을 넣습니다.
2. APIM Subscription required가 켜져 있고 테스트 구독이 Text API 범위인지 확인합니다.
3. 저장하고 5단계의 팀별 제한 검증을 수행합니다.

```xml
<llm-token-limit
  counter-key="@(&quot;text:&quot; + context.Subscription.Id)"
  tokens-per-minute="2000"
  estimate-prompt-tokens="false"
  retry-after-header-name="Retry-After"
  remaining-tokens-header-name="x-ratelimit-remaining-tokens"
  tokens-consumed-header-name="x-tokens-consumed" />
```

- `context.Subscription.Id`를 기준으로 나누므로 **팀별 별도 구독**이 필요합니다. 임의로 변경 가능한 `x-pipeline-id` 헤더를 신뢰 경계로 사용하지 않습니다.
- 수동 HTTP API에 요청 스키마를 넣지 않았으므로 초기 실습은 `estimate-prompt-tokens="false"`로 실제 응답의 `usage`를 사용합니다. PDF 예시의 `true`를 사용하려면 지원되는 요청 스키마를 정의/가져오고 추정 결과를 검증합니다.
- `false`에서는 응답 후 사용량이 반영되며 이미 진행 중인 호출이 한도를 초과할 수 있습니다. 정확한 사전 차단이나 비용 상한 보장으로 해석하지 않습니다.
- 스트리밍은 토큰 추정 특성이 다릅니다. 먼저 비스트리밍으로 검증합니다.
- 같은 counter-key는 여러 정책 범위에서 카운터를 공유할 수 있습니다. `text:` 접두사로 용도를 구분하고 여러 범위에 중복 제한을 넣지 않습니다.
- TPM 초과는 429, 별도로 설정한 기간별 token quota 초과는 403일 수 있습니다. 모델 백엔드의 429와 구분합니다.

### 선택 B. 이미지 요청 수 제한

Image API `<inbound>`에서 `<base />` 다음에 넣습니다. **분당 5회는 실습 예시**이며 이미지 모델의 토큰 수나 실제 비용을 정확히 나타내지 않습니다.

```xml
<rate-limit-by-key
  calls="5"
  renewal-period="60"
  counter-key="@(&quot;image:&quot; + context.Subscription.Id)"
  retry-after-header-name="Retry-After"
  remaining-calls-header-name="x-ratelimit-remaining-requests" />
```

APIM의 분산 rate limit은 완벽히 정확한 횟수를 보장하지 않습니다. 과도한 동시 요청으로 한도를 시험하지 말고 낮은 테스트 한도로 소량 검증합니다.

### 선택 C. 텍스트의 백엔드 429에 한해 한 번 재시도

먼저 기본 요청과 5단계 전환 검증이 성공해야 합니다. 클라이언트 재시도와 합쳐진 최대 호출 횟수·비용을 승인받은 경우에만 사용합니다.

Text API의 **`<backend>` 전체만** 다음 블록으로 교체합니다. Image API에는 적용하지 않습니다.

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

- 최대 백엔드 시도 횟수는 **최초 1회 + 재시도 1회 = 2회**입니다.
- 매 시도 안에서 풀을 다시 선택합니다. Primary의 회로가 실제로 열렸고 Secondary가 사용 가능해야 다른 백엔드로 갈 수 있습니다.
- APIM inbound의 토큰 제한 429는 이 backend 재시도의 대상이 아닙니다.
- 같은 백엔드의 `Retry-After`를 무시하고 계속 두드리기 위한 설정이 아닙니다. 회로 차단과 다른 사용 가능한 백엔드가 전제입니다.
- 5xx·네트워크 타임아웃은 자동 재시도하지 않습니다. 생성 완료 여부가 불명확한 경우를 운영 정책으로 따로 처리합니다.
- 스트리밍 응답이 클라이언트로 시작된 이후에는 투명한 재시도를 기대하지 않습니다.

### 대안. API 정책에서 관리 ID 인증하는 방식

백엔드 자격 대신 정책 인증을 사용하기로 **명시적으로 선택한 경우만** 적용합니다.

1. 해당 API의 두 단일 백엔드에서 Managed identity 자격을 비활성화합니다.
2. 기본 정책의 `Authorization` 삭제 **다음**, `set-backend-service` **이전**에 다음을 넣습니다.
3. 관리 ID 역할은 그대로 필요합니다. 최종 Trace에서 모델 계정으로 Bearer 토큰이 전달되는지만 확인하고 토큰 자체는 복사·기록하지 않습니다.

```xml
<authentication-managed-identity
  resource="https://cognitiveservices.azure.com"
  ignore-error="false" />
```

`output-token-variable-name`을 지정하지 않으면 이 정책이 Authorization 헤더를 설정합니다. 뒤에서 Authorization을 다시 삭제하면 인증이 사라집니다.

**두 방식 중 하나만 선택합니다.** 실패를 감추려고 `ignore-error="true"`로 바꾸거나 정적 모델 키를 하드코딩하지 않습니다.

### 완료 기준

- [ ] Text API는 `text-pool`, Image API는 `image-pool`을 참조한다.
- [ ] 관리 ID 토큰이 실제로 적용되며 인증 방식이 중복되지 않는다.
- [ ] 기본 호출 성공 후 선택 기능을 개별 검증했다.
- [ ] 제한 수치·재시도 여부·최대 시도 횟수를 기록했다.
- [ ] 유효 정책에서 상위/작업별 충돌과 backend 상속 영향을 확인했다.

### 공식 문서

- [정책 편집과 범위](https://learn.microsoft.com/en-us/azure/api-management/set-edit-policies)
- [백엔드 관리 ID 자격](https://learn.microsoft.com/en-us/azure/api-management/backends#configure-managed-identity-for-authorization-credentials)
- [authentication-managed-identity](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
- [forward-request와 timeout 제한](https://learn.microsoft.com/en-us/azure/api-management/forward-request-policy)
- [retry와 실행 횟수](https://learn.microsoft.com/en-us/azure/api-management/retry-policy)
- [llm-token-limit의 지원 API와 추정 특성](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [rate-limit-by-key](https://learn.microsoft.com/en-us/azure/api-management/rate-limit-by-key-policy)
