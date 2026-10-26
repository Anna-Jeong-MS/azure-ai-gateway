# 03. 관리 ID·백엔드·풀 구성

[English](../../step-03-backend-pools/README.md) | 한국어

[이전: API 생성](../step-02-create-apis/README.md) | [전체 목차](../README.md) | [다음: API 라우팅·정책](../step-04-api-policies/README.md)

## 3-A. APIM 시스템 할당 관리 ID 활성화


### 목표와 시작 조건

APIM이 모델 키 대신 Microsoft Entra 토큰으로 각 AI 계정을 호출하게 합니다. Online 상태의 APIM과 해당 리소스를 수정할 작업자 권한이 필요합니다.

### 3-A-1. Portal에서 활성화

1. APIM 인스턴스를 엽니다.
2. **Security → Managed identities** 또는 **Managed identities** 메뉴를 엽니다.
3. **System assigned** 탭을 선택합니다.
4. **Status → On → Save**를 선택합니다. 이미 켜져 있다면 끄거나 재생성하지 않습니다.
5. 저장 후 표시되는 **Object (principal) ID**를 로컬 작업 기록에 복사합니다.
6. APIM 이름, Resource ID, Principal ID가 같은 인스턴스의 값인지 대조합니다.

시스템 할당 ID는 APIM 수명 주기에 연결된 서비스 주체입니다. ID를 끄고 다시 켜거나 APIM을 재생성하면 기존 역할 할당을 그대로 사용할 수 있다고 가정하지 않습니다.

기존 사용자 할당 ID가 연결되어 있으면 그대로 보존합니다. 포털의 시스템 할당 탭에서 해당 ID만 켜고 기존 ID를 제거하지 않습니다. 화면을 새로 고쳐 상태와 Principal ID가 유지되는지 확인합니다.

### 3-A-2. 인증 경계 이해

| 구간 | 사용하는 자격 |
| --- | --- |
| 클라이언트 → APIM | 4단계에서 발급할 APIM 구독 키 |
| APIM → Azure OpenAI | 지금 활성화한 APIM 관리 ID의 Entra 토큰 |

관리 ID를 켜는 것만으로 AI 계정 권한이 생기지 않습니다. 3단계에서 **각 AI 계정**에 역할을 부여해야 합니다. 토큰을 받는 것과 네트워크를 통과하는 것도 별개입니다.

### 완료 기준

- [ ] System assigned 상태가 On이다.
- [ ] 비어 있지 않은 Principal ID를 기록했다.
- [ ] 다른 APIM 또는 작업자 본인의 Object ID와 혼동하지 않았다.
- [ ] 기존 사용자 할당 ID가 있었다면 보존했다.

### 문제 해결

- **메뉴를 수정할 수 없음:** APIM 수정 권한·PIM 활성화를 확인합니다.
- **Principal ID 미표시:** 저장과 리소스 갱신 후 다시 확인합니다. 임의의 다른 ID를 대신 사용하지 않습니다.

### 공식 문서

- [APIM 관리 ID 생성과 사용](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity)
- [관리 ID 인증 정책](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)

---

## 3-B. 각 AI 계정에 APIM 관리 ID 역할 할당


### 목표와 시작 조건

APIM 관리 ID가 Text A/B, Image A/B를 호출할 수 있도록 **개별 AI 계정 범위**에 `Cognitive Services OpenAI User`를 부여합니다.

필요한 값은 3단계의 APIM Principal ID와 1단계의 AI 계정 Resource ID 네 개입니다. 작업자는 해당 범위에서 `Microsoft.Authorization/roleAssignments/write` 권한을 가져야 합니다.

### 3-B-1. 역할과 범위 선택

| 항목 | 설정 |
| --- | --- |
| 역할을 받는 주체 | APIM 시스템 할당 관리 ID |
| 역할 | Cognitive Services OpenAI User |
| 역할 범위 | Text A/B, Image A/B 각각의 계정 리소스 |
| 기본 역할 ID | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` |

이 역할은 Entra 기반 추론과 일부 리소스·배포 읽기를 허용합니다. 모델 배포 생성·변경이나 키 조회 권한을 주지 않아 이번 호출 목적에 적합합니다. 더 넓은 구독/리소스 그룹 범위 할당이 기술적으로 가능하더라도 이 실습에서는 사용하지 않습니다.

### 3-B-2. Portal에서 계정마다 반복

1. **AI 계정 자체**를 엽니다. APIM의 IAM 화면이 아닙니다.
2. **Access control (IAM) → Add → Add role assignment**를 선택합니다.
3. **Role**에서 `Cognitive Services OpenAI User`를 선택합니다.
4. **Members → Assign access to → Managed identity**를 선택합니다.
5. **Select members**에서 APIM이 속한 구독과 **API Management service**를 선택합니다.
6. 해당 APIM을 선택하고 표시되는 주체가 3단계의 ID와 같은지 확인합니다.
7. **Review + assign**으로 저장합니다.
8. IAM의 Role assignments에서 역할·주체·범위를 확인합니다.
9. 나머지 세 계정에서도 반복합니다.

동일한 주체·역할·범위의 할당이 이미 있으면 추가 생성할 필요가 없습니다. 작업자 본인에게 역할을 부여하고 완료로 처리하지 않습니다.

포털에서 각 계정의 **Access control (IAM) → Role assignments**를 열고 APIM 관리 ID로 필터링하여 역할과 범위를 확인합니다. 계정이 서로 다른 리소스 그룹·구독에 있다면 각각의 실제 계정을 확인하며 한 번의 할당으로 네 계정이 모두 포함된다고 가정하지 않습니다.

### 3-B-3. 확인 기록

| AI 계정 | 역할 | APIM Principal ID 일치 | 계정 범위 일치 |
| --- | --- | --- | --- |
| Text A | OpenAI User | 확인 | 확인 |
| Text B | OpenAI User | 확인 | 확인 |
| Image A | OpenAI User | 확인 | 확인 |
| Image B | OpenAI User | 확인 | 확인 |

RBAC 전파에 시간이 걸릴 수 있습니다. 할당 직후 호출이 실패하면 실제 할당을 확인하고 공식 전파 시간을 고려해 재시도합니다. 고정된 몇 분 뒤에는 반드시 성공한다고 가정하지 않습니다.

### 완료 기준

- [ ] APIM 관리 ID에 계정 네 개 각각의 역할이 확인된다.
- [ ] 불필요한 구독 전체·리소스 그룹 전체 권한을 추가하지 않았다.
- [ ] 작업자 권한과 APIM 호출 권한을 구분했다.

### 문제 해결

- **Add role assignment 비활성화:** Contributor만 보유했는지 확인하고 역할 할당 담당자에게 요청합니다.
- **호출 401/403:** Principal ID·리소스 범위·토큰 audience와 네트워크 차단을 함께 점검합니다. 403이 항상 RBAC라는 뜻은 아닙니다.
- **ID 재생성 후 실패:** 현재 Principal ID와 기존 역할 할당의 주체를 비교합니다.

### 공식 문서

- [Azure OpenAI의 역할별 권한](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [역할 할당 절차와 작업자 권한](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)

---

## 3-C. 백엔드 4개와 서킷 브레이커


### 목표와 시작 조건

**2단계에서 만든 Language Model API와 자동 생성 Primary 백엔드**를 재사용하고 나머지 세 개만 수동 추가합니다. 위 관리 ID·역할 할당을 완료하고 기존 계정의 공용 HTTPS 엔드포인트에 접근할 수 있어야 합니다.

### 3-C-1. 런타임 URL 확정

이번 가이드의 기본 경로는 다음과 같습니다. `<account>`에는 1단계에서 기록한 실제 계정명을 넣습니다.

| 백엔드 ID | Runtime URL | 연결할 배포 |
| --- | --- | --- |
| `<generated-text-backend-id>` (자동 생성된 실제 ID) | `https://<text-account-a>.openai.azure.com/openai/deployments/gpt-55` | `gpt-55` |
| `text-aoai-02` (수동) | `https://<text-account-b>.openai.azure.com/openai/deployments/gpt-55` | `gpt-55` |
| `image-aoai-01` | `https://<image-account-a>.openai.azure.com/openai` | `gpt-image-25-flare` |
| `image-aoai-02` | `https://<image-account-b>.openai.azure.com/openai` | `gpt-image-25-flare` |

**텍스트:** 두 백엔드의 기본 URL에 `/openai/deployments/<실제 텍스트 배포 이름>`이 포함되고 가져온 작업은 `/chat/completions`입니다. **이미지:** 두 백엔드의 기본 URL은 `/openai`에서 끝나고 4단계의 일반 HTTP API 작업에 `/deployments/<실제 이미지 배포 이름>/images/generations`를 넣습니다. 두 경로 구성을 섞거나 기본 URL에 `api-version`을 넣지 않습니다.

### 3-C-2. 자동 생성 백엔드 1개 재사용 + 수동 3개 추가

1. **APIs → Backends**에서 자동 생성된 Text Primary를 엽니다. 실제 ID를 재사용하고 배포 경로가 포함된 URL을 확인하며 중복 생성하지 않습니다.
2. 나머지만 **+ Create new backend**로 `text-aoai-02`, `image-aoai-01`, `image-aoai-02` 세 개를 위 표대로 만듭니다. 이미 있으면 확인 후 재사용합니다.
3. 수동 백엔드는 단일 유형과 HTTP 계열 프로토콜을 선택하되 **Runtime URL은 HTTPS**를 사용합니다.
4. 다음 인증 확인은 자동 생성된 백엔드까지 포함해 네 개 모두에 적용합니다.
5. **Authorization credentials → Managed identity**에서 **Enable**을 선택합니다.
6. **Client identity → System assigned identity**를 선택합니다.
7. **Resource ID**에 정확히 **`https://cognitiveservices.azure.com`**을 입력합니다. 계정 Resource ID나 백엔드 URL을 입력하는 칸이 아닙니다.
8. 정적 `api-key` 또는 오래된 Authorization 자격이 등록되어 있으면 충돌하지 않도록 해당 백엔드 설정을 정리합니다. 다른 API가 재사용하는 백엔드라면 영향도를 먼저 확인합니다.
9. 저장 후 관련 단일 백엔드가 **자동 1개 + 수동 3개 = 총 4개**인지 확인합니다. 다섯 개를 만들지 않습니다. 이미지 일반 HTTP API는 2단계에서 이미 만들었으며 Language Model API를 사용하지 않습니다.

본 가이드의 기본 인증 위치는 **개별 백엔드의 Managed identity 설정**입니다. 풀 자체에는 계정 인증을 설정하지 않습니다. 4단계의 API 정책에 같은 토큰 발급을 중복해서 추가할 필요가 없습니다.

### 3-C-3. 서킷 브레이커 추가

각 백엔드에서 **Settings → Circuit breaker settings → Add new**를 선택합니다.

아래 값은 Microsoft의 고정 권장값이 아니라 **전환 동작을 확인하기 위한 실습용 시작값**입니다. 실제 운영에서는 오류율·쿼터·복구 시간으로 조정합니다.

| 필드 | 실습 입력 |
| --- | --- |
| Rule name | `ai-backend-errors` |
| Failure count | `1` |
| Failure interval | 1분 (`PT1M`) |
| Failure status code ranges | `429–429`, `500–599` |
| Trip duration | 1분 (`PT1M`) |
| Check Retry-After header | True / Accept |

1. **하나의 규칙**에 두 상태 코드 범위를 추가합니다. 현재 백엔드당 서킷 브레이커 규칙은 하나만 지원합니다.
2. 저장 후 백엔드를 다시 선택해 실제 저장된 값을 확인합니다.
3. 같은 설정을 나머지 백엔드에 적용합니다.
4. 포털에서 여러 상태 코드 범위를 한 규칙에 편집할 수 없으면 임의로 규칙 두 개를 만들지 않습니다. 이번 포털 전용 실습에서는 `429–429`를 사용하고 5xx 범위는 미설정으로 기록합니다. 이 경우 5xx 전환 검증은 완료로 표시하지 않습니다.

### 3-C-4. 동작의 의미

- 실패 횟수·시간 범위가 충족되면 해당 백엔드의 회로가 열리고 일정 시간 호출을 중단합니다.
- `Retry-After`를 수용하므로 실제 제외 시간은 설정한 1분보다 길 수 있습니다. Azure OpenAI는 긴 대기 시간을 반환할 수 있습니다.
- 서킷 브레이커와 부하 분산은 분산 게이트웨이에서 근사적으로 동작합니다. 모든 요청과 모든 노드가 동시에 동일 상태가 된다고 가정하지 않습니다.
- **현재 실패한 요청 자체가 자동 재실행되는 것은 아닙니다.** 다음 요청의 다른 백엔드 선택과 현재 요청 재시도는 별도입니다.
- 인증 오류 401/403은 이 실습의 차단 조건이 아닙니다. 인증 오류를 억지로 발생시켜 전환 테스트를 하지 않습니다.

### 완료 기준

- [ ] 단일 백엔드 4개의 ID와 실제 계정 URL이 일치한다.
- [ ] 텍스트는 Language Model API로 가져왔고 자동 생성 백엔드를 Primary로 재사용했으며 추가 단일 백엔드는 세 개뿐이다.
- [ ] 모두 System assigned identity와 올바른 audience를 사용한다.
- [ ] 모두 429를 처리하고 Retry-After를 수용하는 규칙이 저장되어 있다.
- [ ] 5xx 포함 여부와 실제 실습값을 기록했다.
- [ ] URL에 배포 경로가 중복되지 않는다.

### 문제 해결

- **관리 ID 옵션 없음:** APIM의 ID 상태와 포털·SKU 지원을 확인합니다. 4단계의 API 수준 인증 대안도 가능하지만 두 방식을 섞지 않습니다.
- **BackendConnectionFailure:** DNS·방화벽·TLS·실제 계정 호스트명을 점검합니다.
- **전환이 너무 오래 유지:** 실제 `Retry-After`와 회로 차단 시간을 확인합니다.

### 공식 문서

- [백엔드 생성과 관리 ID 자격 설정](https://learn.microsoft.com/en-us/azure/api-management/backends)
- [서킷 브레이커의 동작과 제한](https://learn.microsoft.com/en-us/azure/api-management/backends#circuit-breaker)
- [관리 ID 토큰 정책의 audience와 동작](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)
- [Language Model API 가져오기와 백엔드 자동 생성](https://learn.microsoft.com/en-us/azure/api-management/openai-compatible-llm-api)

---

## 3-D. 텍스트·이미지 백엔드 풀 생성


### 목표와 시작 조건

등록된 단일 백엔드를 `text-pool`과 `image-pool`로 묶습니다. 단일 백엔드 네 개의 인증과 회로 차단 규칙이 저장되어 있어야 합니다.

### 3-D-1. 분산 방식을 먼저 선택

| 목적 | Primary / Secondary 설정 | 해석 |
| --- | --- | --- |
| 두 계정에 평상시 분산 | 우선순위 둘 다 1, 가중치 둘 다 100 | 같은 우선순위 그룹 안에서 대략 균등 분산 |
| 비율에 따라 분산 | 우선순위 둘 다 1, 예: 가중치 3 / 1 | 장기적으로 상대 가중치에 가까운 분산, 정확한 요청 순서 보장 아님 |
| 주·대기 또는 PTU → PAYG | 우선순위 1 / 2, 가중치 각각 100 | 높은 우선순위 그룹이 모두 회로 차단으로 사용 불가일 때 낮은 그룹 사용 |

본 실습은 **우선순위 1 / 2**를 기준으로 진행합니다. 숫자가 작을수록 높은 우선순위입니다. 동시 분산이 요구된다면 두 우선순위를 1로 바꾸고 5단계의 기대 결과도 균등 분산으로 바꿉니다.

서로 다른 우선순위 그룹에서는 가중치가 평상시 분산 비율을 만들지 않습니다. 예를 들어 1/2 우선순위에 같은 가중치를 넣어도 평상시 50:50이 되지 않습니다.

### 3-D-2. 텍스트 풀 생성

1. APIM **APIs → Backends → Load balancer** 탭을 엽니다.
2. **+ Create new pool**을 선택합니다.
3. **Name**을 `text-pool`로 입력합니다.
4. **Add backends to pool**에서 앞서 기록한 **자동 생성 Text Primary의 실제 ID**와 `text-aoai-02`를 추가합니다.
5. **Customize weight and priority**를 선택해 다음 값을 넣습니다.

| 풀 | 백엔드 | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `<generated-text-backend-id>` (실제 ID) | 1 | 100 |
| `text-pool` | `text-aoai-02` | 2 | 100 |

6. Session awareness / session affinity는 이번 무상태 단일 호출 실습에서 사용하지 않습니다.
7. **Create / Save**를 선택합니다.

### 3-D-3. 이미지 풀 생성

같은 방법으로 다음 풀을 만듭니다.

| 풀 | 백엔드 | Priority | Weight |
| --- | --- | --- | --- |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 2 | 100 |

텍스트와 이미지 백엔드를 한 풀에 섞지 않습니다. 같은 풀의 두 계정에는 동일한 배포 이름과 호환 API가 있어야 합니다.

### 3-D-4. 저장 후 확인

1. 두 풀을 각각 열어 백엔드 ID·우선순위·가중치를 대조합니다.
2. 풀에 포함된 백엔드가 다른 풀의 이름이 아니라 3단계의 단일 백엔드인지 확인합니다.
3. 가져온 Text API는 아직 자동 생성 단일 백엔드를 참조합니다. 4단계에서 이 경로를 `text-pool`로 바꾸고 기존 이미지 API의 초기 Primary URL도 `image-pool`로 바꿉니다.

공식 문서 기준으로 풀당 최대 30개 백엔드를 넣을 수 있습니다. 부하 분산과 회로 상태는 근사적으로 동작하므로 짧은 샘플로 정확한 비율이나 즉시 전환을 보장하지 않습니다.

### 완료 기준

- [ ] 풀 ID가 `text-pool`, `image-pool`과 정확히 일치한다.
- [ ] 각 풀에 맞는 단일 백엔드 두 개만 포함되어 있다.
- [ ] 우선순위 기반인지 동시 분산인지 선택을 기록했다.
- [ ] 두 계정이 같은 쿼터 풀을 공유하는지 확인했으며 용량 증가를 가정하지 않았다.

### 문제 해결

- **항상 Primary로만 감:** 1/2 우선순위에서는 정상입니다. 균등 분산을 의도했다면 우선순위를 둘 다 1로 설정합니다.
- **모든 호출 503:** 사용 가능한 백엔드가 있는지, 서킷 브레이커·Retry-After·풀 구성과 실제 응답 원인을 확인합니다.
- **Secondary로 전환되지 않음:** Primary의 실제 오류가 차단 규칙에 포함되는지 확인합니다. 회로를 열지 않은 401/403은 전환 테스트가 아닙니다.

### 공식 문서

- [백엔드 풀, 우선순위·가중치, Portal 생성 순서](https://learn.microsoft.com/en-us/azure/api-management/backends#load-balanced-pool)
- [풀을 참조하는 set-backend-service](https://learn.microsoft.com/en-us/azure/api-management/set-backend-service-policy)
