# 02. 관리 ID와 접근 권한

[English](../../step-02-identity-access/README.md) | 한국어

[이전: 01. 사전 준비와 리소스 생성](../step-01-prepare-resources/README.md) | [전체 목차](../README.md) | [다음: 03. 백엔드와 부하 분산 풀](../step-03-backend-pools/README.md)

## 2-A. APIM 시스템 할당 관리 ID 활성화


### 목표와 시작 조건

APIM이 모델 키 대신 Microsoft Entra 토큰으로 각 AI 계정을 호출하게 합니다. Online 상태의 APIM과 해당 리소스를 수정할 작업자 권한이 필요합니다.

### 2-A-1. Portal에서 활성화

1. APIM 인스턴스를 엽니다.
2. **Security → Managed identities** 또는 **Managed identities** 메뉴를 엽니다.
3. **System assigned** 탭을 선택합니다.
4. **Status → On → Save**를 선택합니다. 이미 켜져 있다면 끄거나 재생성하지 않습니다.
5. 저장 후 표시되는 **Object (principal) ID**를 로컬 작업 기록에 복사합니다.
6. APIM 이름, Resource ID, Principal ID가 같은 인스턴스의 값인지 대조합니다.

시스템 할당 ID는 APIM 수명 주기에 연결된 서비스 주체입니다. ID를 끄고 다시 켜거나 APIM을 재생성하면 기존 역할 할당을 그대로 사용할 수 있다고 가정하지 않습니다.

기존 사용자 할당 ID가 연결되어 있으면 그대로 보존합니다. 포털의 시스템 할당 탭에서 해당 ID만 켜고 기존 ID를 제거하지 않습니다. 화면을 새로 고쳐 상태와 Principal ID가 유지되는지 확인합니다.

### 2-A-2. 인증 경계 이해

| 구간 | 사용하는 자격 |
| --- | --- |
| 클라이언트 → APIM | 4단계에서 발급할 APIM 구독 키 |
| APIM → Azure OpenAI | 지금 활성화한 APIM 관리 ID의 Entra 토큰 |

관리 ID를 켜는 것만으로 AI 계정 권한이 생기지 않습니다. 2단계에서 **각 AI 계정**에 역할을 부여해야 합니다. 토큰을 받는 것과 네트워크를 통과하는 것도 별개입니다.

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

## 2-B. 각 AI 계정에 APIM 관리 ID 역할 할당


### 목표와 시작 조건

APIM 관리 ID가 Text A/B, Image A/B를 호출할 수 있도록 **개별 AI 계정 범위**에 `Cognitive Services OpenAI User`를 부여합니다.

필요한 값은 2단계의 APIM Principal ID와 1단계의 AI 계정 Resource ID 네 개입니다. 작업자는 해당 범위에서 `Microsoft.Authorization/roleAssignments/write` 권한을 가져야 합니다.

### 2-B-1. 역할과 범위 선택

| 항목 | 설정 |
| --- | --- |
| 역할을 받는 주체 | APIM 시스템 할당 관리 ID |
| 역할 | Cognitive Services OpenAI User |
| 역할 범위 | Text A/B, Image A/B 각각의 계정 리소스 |
| 기본 역할 ID | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` |

이 역할은 Entra 기반 추론과 일부 리소스·배포 읽기를 허용합니다. 모델 배포 생성·변경이나 키 조회 권한을 주지 않아 이번 호출 목적에 적합합니다. 더 넓은 구독/리소스 그룹 범위 할당이 기술적으로 가능하더라도 이 실습에서는 사용하지 않습니다.

### 2-B-2. Portal에서 계정마다 반복

1. **AI 계정 자체**를 엽니다. APIM의 IAM 화면이 아닙니다.
2. **Access control (IAM) → Add → Add role assignment**를 선택합니다.
3. **Role**에서 `Cognitive Services OpenAI User`를 선택합니다.
4. **Members → Assign access to → Managed identity**를 선택합니다.
5. **Select members**에서 APIM이 속한 구독과 **API Management service**를 선택합니다.
6. 해당 APIM을 선택하고 표시되는 주체가 2단계의 ID와 같은지 확인합니다.
7. **Review + assign**으로 저장합니다.
8. IAM의 Role assignments에서 역할·주체·범위를 확인합니다.
9. 나머지 세 계정에서도 반복합니다.

동일한 주체·역할·범위의 할당이 이미 있으면 추가 생성할 필요가 없습니다. 작업자 본인에게 역할을 부여하고 완료로 처리하지 않습니다.

포털에서 각 계정의 **Access control (IAM) → Role assignments**를 열고 APIM 관리 ID로 필터링하여 역할과 범위를 확인합니다. 계정이 서로 다른 리소스 그룹·구독에 있다면 각각의 실제 계정을 확인하며 한 번의 할당으로 네 계정이 모두 포함된다고 가정하지 않습니다.

### 2-B-3. 확인 기록

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
