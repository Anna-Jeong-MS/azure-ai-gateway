# 03. 관리 ID·백엔드 구성

[English](../../step-03-backend-pools/README.md) | 한국어

[이전: API 생성](../step-02-create-apis/README.md) | [전체 목차](../README.md) | [다음: 정책 적용](../step-04-api-policies/README.md)

## 3-1. APIM 시스템 할당 ID 활성화

1. APIM **Security → Managed identities**를 엽니다.
2. **System assigned**에서 **Status = On → Save**를 선택합니다.
3. **Object (principal) ID**를 기록합니다.

## 3-2. 모델 계정 접근 역할 할당

모델이 배포된 각 계정에서 반복합니다.

1. Azure OpenAI 계정의 **Access control (IAM)**을 엽니다.
2. **Add → Add role assignment**를 선택합니다.
3. **Cognitive Services OpenAI User**를 선택합니다.
4. **Members → Assign access to → Managed identity**를 선택합니다.
5. **API Management service**에서 1단계에 생성한 APIM을 선택합니다.
6. Principal ID를 확인하고 **Review + assign**을 선택합니다.
7. **Role assignments**에서 APIM 관리 ID에 계정 리소스 범위의 역할이 있는지 확인합니다.

텍스트·이미지 배포가 같은 계정을 사용하면 해당 계정의 역할 할당 한 번으로 둘 다 접근합니다. 테스트 전 RBAC 전파 시간을 고려합니다.

## 3-3. Text Primary 재사용·백엔드 3개 추가

1. **APIs → Backends**에서 2단계의 자동 생성 Text Primary를 엽니다.
2. 실제 ID와 URL을 아래 표와 대조합니다.
3. 수동 항목 세 개에 대해 각각 **+ Create new backend**를 선택합니다.
4. 단일 백엔드 유형, HTTP 계열 프로토콜, 아래 HTTPS 런타임 URL을 사용합니다.
5. 정적 모델 키·Authorization 자격은 비워 둡니다. 4단계에서 각 API inbound에 Managed Identity 인증을 적용합니다.
6. 각 백엔드를 저장합니다.

| 백엔드 | 생성 방식 | Runtime URL |
| --- | --- | --- |
| `<generated-text-backend-id>` | 자동 생성 후 재사용 | `https://<text-account-a>.openai.azure.com/openai/deployments/<text-deployment-a>` |
| `text-aoai-02` | 수동 | `https://<text-account-b>.openai.azure.com/openai/deployments/<text-deployment-b>` |
| `image-aoai-01` | 수동 | `https://<image-account-a>.openai.azure.com/openai` |
| `image-aoai-02` | 수동 | `https://<image-account-b>.openai.azure.com/openai` |

단일 백엔드는 **자동 1개 + 수동 3개 = 총 4개**입니다. 텍스트 기본 URL에는 배포 경로가 포함되고 이미지 기본 URL은 `/openai`에서 끝납니다.

## 3-4. 서킷 브레이커 설정

각 단일 백엔드의 **Settings → Circuit breaker settings → Add new**에서 규칙 하나를 저장합니다.

| 항목 | 초기값 |
| --- | --- |
| Rule name | `ai-backend-errors` |
| Failure count | `1` |
| Failure interval | 1분 (`PT1M`) |
| Failure status code ranges | 하나의 규칙에 `429-429`, `500-599` |
| Trip duration | 1분 (`PT1M`) |
| Check Retry-After header | True / Accept |

실습용 설정값입니다. `Retry-After`를 수용하므로 백엔드 제외 시간이 1분보다 길 수 있습니다. 게이트웨이 인스턴스 간 회로 상태는 근사적으로 동작합니다.

## 3-5. 백엔드 풀 생성

1. **APIs → Backends → Load balancer → + Create new pool**을 선택합니다.
2. 이름을 `text-pool`로 입력합니다.
3. 자동 생성 Text Primary의 실제 ID와 `text-aoai-02`를 추가합니다.
4. **Customize weight and priority**에서 다음을 입력합니다.

| 풀 | 백엔드 | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `<generated-text-backend-id>` | 1 | 100 |
| `text-pool` | `text-aoai-02` | 2 | 100 |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 2 | 100 |

5. Session affinity는 끄고 저장합니다.
6. 이미지 항목을 사용해 `image-pool`도 생성합니다.

평상시 Priority 1이 호출됩니다. 상위 우선순위의 모든 백엔드가 회로 차단으로 사용 불가일 때 Priority 2를 사용하며 실패한 요청이 자동 재시도되지는 않습니다. 평상시 두 계정에 분산하려면 우선순위를 모두 1로 하고 가중치를 같게 설정합니다.

## 완료 기준

- [ ] APIM 시스템 할당 ID가 활성화되어 있다.
- [ ] 모든 모델 계정의 리소스 범위에 APIM 관리 ID의 OpenAI User 역할이 있다.
- [ ] 단일 백엔드 네 개의 HTTPS URL·서킷 브레이커가 설정되어 있다.
- [ ] `text-pool`, `image-pool`의 구성원·우선순위가 맞다.

## 공식 문서

- [APIM 관리 ID](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity)
- [Azure OpenAI 역할별 권한](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [포털에서 역할 할당](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [백엔드·서킷 브레이커·풀](https://learn.microsoft.com/en-us/azure/api-management/backends)
