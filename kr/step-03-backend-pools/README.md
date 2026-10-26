# 03. 백엔드와 부하 분산 풀

[English](../../step-03-backend-pools/README.md) | 한국어

[이전: 02. 관리 ID와 접근 권한](../step-02-identity-access/README.md) | [전체 목차](../README.md) | [다음: 04. API 구성과 정책 적용](../step-04-api-policies/README.md)

## 3-A. 백엔드 4개와 서킷 브레이커


### 목표와 시작 조건

모델이 이미 배포된 기존 계정 네 개를 APIM 백엔드로 등록합니다. 관리 ID와 역할 할당을 완료하고, APIM에서 각 계정의 공용 HTTPS 엔드포인트로 접근할 수 있어야 합니다.

### 3-A-1. 런타임 URL 확정

이번 가이드의 기본 경로는 다음과 같습니다. `<account>`에는 1단계에서 기록한 실제 계정명을 넣습니다.

| 백엔드 ID | Runtime URL | 연결할 배포 |
| --- | --- | --- |
| `text-aoai-01` | `https://<text-account-a>.openai.azure.com/openai` | `gpt-55` |
| `text-aoai-02` | `https://<text-account-b>.openai.azure.com/openai` | `gpt-55` |
| `image-aoai-01` | `https://<image-account-a>.openai.azure.com/openai` | `gpt-image-25-flare` |
| `image-aoai-02` | `https://<image-account-b>.openai.azure.com/openai` | `gpt-image-25-flare` |

**중요:** 이 방식에서는 백엔드 URL에 `/deployments/<name>`이나 작업 경로, `api-version`을 넣지 않습니다. 4단계의 작업 경로에 배포 이름이 포함됩니다. 배포 경로가 포함된 기존 로컬 정책·템플릿과 혼합하면 경로가 중복될 수 있습니다.

### 3-A-2. 백엔드 생성

1. APIM에서 **APIs → Backends**를 엽니다.
2. **+ Create new backend**를 선택합니다.
3. **Name**에 위 표의 백엔드 ID를 입력합니다. 이미 있으면 새로 만들지 말고 설정을 비교합니다.
4. 유형은 단일 백엔드, 프로토콜은 HTTP 계열을 선택하고 **Runtime URL은 HTTPS** 주소로 입력합니다.
5. **Authorization credentials → Managed identity**에서 **Enable**을 선택합니다.
6. **Client identity → System assigned identity**를 선택합니다.
7. **Resource ID**에 정확히 **`https://cognitiveservices.azure.com`**을 입력합니다. 계정 Resource ID나 백엔드 URL을 입력하는 칸이 아닙니다.
8. 정적 `api-key` 또는 오래된 Authorization 자격이 등록되어 있으면 충돌하지 않도록 해당 백엔드 설정을 정리합니다. 다른 API가 재사용하는 백엔드라면 영향도를 먼저 확인합니다.
9. 생성하고 나머지 세 백엔드에 반복합니다.

본 가이드의 기본 인증 위치는 **개별 백엔드의 Managed identity 설정**입니다. 풀 자체에는 계정 인증을 설정하지 않습니다. 4단계의 API 정책에 같은 토큰 발급을 중복해서 추가할 필요가 없습니다.

### 3-A-3. 서킷 브레이커 추가

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

### 3-A-4. 동작의 의미

- 실패 횟수·시간 범위가 충족되면 해당 백엔드의 회로가 열리고 일정 시간 호출을 중단합니다.
- `Retry-After`를 수용하므로 실제 제외 시간은 설정한 1분보다 길 수 있습니다. Azure OpenAI는 긴 대기 시간을 반환할 수 있습니다.
- 서킷 브레이커와 부하 분산은 분산 게이트웨이에서 근사적으로 동작합니다. 모든 요청과 모든 노드가 동시에 동일 상태가 된다고 가정하지 않습니다.
- **현재 실패한 요청 자체가 자동 재실행되는 것은 아닙니다.** 다음 요청의 다른 백엔드 선택과 현재 요청 재시도는 별도입니다.
- 인증 오류 401/403은 이 실습의 차단 조건이 아닙니다. 인증 오류를 억지로 발생시켜 전환 테스트를 하지 않습니다.

### 완료 기준

- [ ] 단일 백엔드 4개의 ID와 실제 계정 URL이 일치한다.
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

---

## 3-B. 텍스트·이미지 백엔드 풀 생성


### 목표와 시작 조건

등록된 단일 백엔드를 `text-pool`과 `image-pool`로 묶습니다. 단일 백엔드 네 개의 인증과 회로 차단 규칙이 저장되어 있어야 합니다.

### 3-B-1. 분산 방식을 먼저 선택

| 목적 | Primary / Secondary 설정 | 해석 |
| --- | --- | --- |
| 두 계정에 평상시 분산 | 우선순위 둘 다 1, 가중치 둘 다 100 | 같은 우선순위 그룹 안에서 대략 균등 분산 |
| 비율에 따라 분산 | 우선순위 둘 다 1, 예: 가중치 3 / 1 | 장기적으로 상대 가중치에 가까운 분산, 정확한 요청 순서 보장 아님 |
| 주·대기 또는 PTU → PAYG | 우선순위 1 / 2, 가중치 각각 100 | 높은 우선순위 그룹이 모두 회로 차단으로 사용 불가일 때 낮은 그룹 사용 |

본 실습은 **우선순위 1 / 2**를 기준으로 진행합니다. 숫자가 작을수록 높은 우선순위입니다. 동시 분산이 요구된다면 두 우선순위를 1로 바꾸고 5단계의 기대 결과도 균등 분산으로 바꿉니다.

서로 다른 우선순위 그룹에서는 가중치가 평상시 분산 비율을 만들지 않습니다. 예를 들어 1/2 우선순위에 같은 가중치를 넣어도 평상시 50:50이 되지 않습니다.

### 3-B-2. 텍스트 풀 생성

1. APIM **APIs → Backends → Load balancer** 탭을 엽니다.
2. **+ Create new pool**을 선택합니다.
3. **Name**을 `text-pool`로 입력합니다.
4. **Add backends to pool**에서 `text-aoai-01`, `text-aoai-02`를 추가합니다.
5. **Customize weight and priority**를 선택해 다음 값을 넣습니다.

| 풀 | 백엔드 | Priority | Weight |
| --- | --- | --- | --- |
| `text-pool` | `text-aoai-01` | 1 | 100 |
| `text-pool` | `text-aoai-02` | 2 | 100 |

6. Session awareness / session affinity는 이번 무상태 단일 호출 실습에서 사용하지 않습니다.
7. **Create / Save**를 선택합니다.

### 3-B-3. 이미지 풀 생성

같은 방법으로 다음 풀을 만듭니다.

| 풀 | 백엔드 | Priority | Weight |
| --- | --- | --- | --- |
| `image-pool` | `image-aoai-01` | 1 | 100 |
| `image-pool` | `image-aoai-02` | 2 | 100 |

텍스트와 이미지 백엔드를 한 풀에 섞지 않습니다. 같은 풀의 두 계정에는 동일한 배포 이름과 호환 API가 있어야 합니다.

### 3-B-4. 저장 후 확인

1. 두 풀을 각각 열어 백엔드 ID·우선순위·가중치를 대조합니다.
2. 풀에 포함된 백엔드가 다른 풀의 이름이 아니라 3단계의 단일 백엔드인지 확인합니다.
3. 아직 API 정책이 풀을 참조하지 않았으므로 이 단계만으로 클라이언트 라우팅이 바뀐 것은 아닙니다.

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
