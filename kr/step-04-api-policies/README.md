# 04. 정책 적용

[English](../../step-04-api-policies/README.md) | 한국어

[이전: 관리 ID·백엔드](../step-03-backend-pools/README.md) | [전체 목차](../README.md) | [다음: 게이트웨이 테스트](../step-05-validation/README.md)

## 4-1. API 범위 구독 생성

1. APIM **Subscriptions → + Add subscription**을 선택합니다.
2. 다음 구독을 **Active** 상태로 생성합니다.

| 이름 | 범위 |
| --- | --- |
| `text-test` | API → Text API |
| `image-test` | API → Image API |

3. 두 API의 **Settings**에서 **Subscription required = On**을 확인합니다.
4. 테스트할 때 각 구독 키를 확인합니다. 클라이언트는 `Ocp-Apim-Subscription-Key`로 해당 키를 전달하며 모델 계정 키나 관리 ID 토큰은 보내지 않습니다.

## 4-2. Text API 정책 적용

1. **APIs → APIs → Text API → Design → All operations → `</>`**를 엽니다.
2. API 정책을 다음으로 교체하고 **Save**를 선택합니다. 자동 생성된 작업과 요청 스키마는 유지합니다.
3. **Calculate effective policy**에서 작업 범위까지 포함한 최종 경로가 `text-pool`인지 확인합니다.

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

자동 생성된 단일 백엔드 경로를 텍스트 풀로 바꾸는 정책입니다. APIM이 inbound 처리 전에 클라이언트 구독 키를 검증하고 클라이언트 자격을 제거한 뒤 시스템 할당 ID로 모델 토큰을 얻습니다. `authentication-managed-identity` 뒤에서 Authorization을 삭제하거나 덮어쓰지 않습니다.

## 4-3. Image API 정책 적용

1. **APIs → APIs → Image API → Design → All operations → `</>`**를 엽니다.
2. 아래 정책을 적용하고 저장합니다.
3. 유효 경로가 `image-pool`인지 확인합니다.

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

timeout은 응답 헤더 대기 시간이며 네트워크에서 240초를 넘는 값이 보장되지 않을 수 있습니다. 이미지는 완료 여부가 불명확할 때 중복 생성·과금이 발생할 수 있으므로 자동 재시도하지 않습니다.

## 4-4. 선택적 사용량 제한

5단계의 기본 호출이 성공한 뒤 필요한 정책을 해당 API inbound의 `<base />` 바로 다음에 추가합니다.

### 텍스트: 구독당 분당 2,000토큰

```xml
<llm-token-limit
  counter-key="@(&quot;text:&quot; + context.Subscription.Id)"
  tokens-per-minute="2000"
  estimate-prompt-tokens="false"
  retry-after-header-name="Retry-After"
  remaining-tokens-header-name="x-ratelimit-remaining-tokens"
  tokens-consumed-header-name="x-tokens-consumed" />
```

팀마다 별도 APIM 구독을 사용합니다. 프롬프트 추정을 끈 상태에서는 응답 `usage`로 사용량을 반영하므로 동시 요청이 한도를 초과한 뒤 후속 요청부터 차단될 수 있습니다.

### 이미지: 구독당 분당 5회

```xml
<rate-limit-by-key
  calls="5"
  renewal-period="60"
  counter-key="@(&quot;image:&quot; + context.Subscription.Id)"
  retry-after-header-name="Retry-After"
  remaining-calls-header-name="x-ratelimit-remaining-requests" />
```

예시 제한값이며 비용 상한을 보장하지 않습니다. 분산 게이트웨이의 요청 제한은 근사적으로 동작합니다.

## 4-5. 선택적 텍스트 백엔드 429 재시도

텍스트를 한 번 재시도하려면 Text API의 `<backend>`만 다음으로 교체합니다.

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

요청당 백엔드 호출은 최대 **2회**입니다. 다른 백엔드 선택은 풀의 회로 상태·가용성이 허용할 때만 이루어집니다. APIM inbound 제한의 429는 재시도 대상이 아닙니다. 이미지·5xx·타임아웃·이미 전송을 시작한 스트림에는 적용하지 않습니다.

## 완료 기준

- [ ] 두 API 모두 API 범위 구독 키를 요구한다.
- [ ] 각 API의 유효 inbound에 Managed Identity 인증이 한 번 적용된다.
- [ ] 유효 경로가 각각 `text-pool`, `image-pool`을 참조한다.
- [ ] 선택적 제한·재시도 횟수를 기록하고 검증했다.

## 공식 문서

- [구독과 키](https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions)
- [정책 편집](https://learn.microsoft.com/en-us/azure/api-management/set-edit-policies)
- [Managed Identity 인증](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
- [forward-request](https://learn.microsoft.com/en-us/azure/api-management/forward-request-policy)
- [토큰 제한](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [요청 수 제한](https://learn.microsoft.com/en-us/azure/api-management/rate-limit-by-key-policy)
- [재시도](https://learn.microsoft.com/en-us/azure/api-management/retry-policy)
