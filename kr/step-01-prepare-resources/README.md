# 01. 기존 모델 확인과 APIM 준비

[English](../../step-01-prepare-resources/README.md) | 한국어

[전체 목차](../README.md) | [다음: 02. 관리 ID와 접근 권한](../step-02-identity-access/README.md)

## 1-A. 사전 준비와 입력값 확정


### 목표

텍스트·이미지 모델은 모두 배포된 것으로 가정합니다. 기존 연결 정보를 기록한 뒤 Standard v2 APIM을 공용 연결로 준비합니다. 기존 리소스 그룹을 사용하고 AI 계정이나 모델 배포를 새로 만들지 않습니다.

### 1-A-1. 작업자 권한 확인

1. [Azure Portal](https://portal.azure.com)에 로그인하고 우측 상단의 디렉터리와 구독을 확인합니다.
2. 기존 리소스 그룹을 엽니다.
3. **Access control (IAM) → View my access**에서 본인의 역할과 범위를 확인합니다.
4. 아래 작업의 담당자를 정합니다. PIM을 사용하는 조직은 필요한 역할을 활성화하고, 역할 할당 조건·Deny Assignment·Azure Policy도 확인합니다.

| 작업 | 일반적인 역할 예시 | 범위·주의 |
| --- | --- | --- |
| APIM 신규 생성 | Contributor | 대상 리소스 그룹. 새 리소스가 아직 없으므로 기존 APIM 리소스만의 권한으로는 신규 생성 불가 |
| 기존 APIM의 API·백엔드·관리 ID 관리 | API Management Service Contributor 또는 Contributor | 대상 APIM. 사용자 할당 ID 연결은 별도 권한이 필요할 수 있으나 이번 실습은 시스템 할당 사용 |
| APIM 관리 ID에 역할 부여 | Role Based Access Control Administrator, User Access Administrator 또는 Owner | 역할을 부여할 AI 계정 또는 상위 범위에서 `Microsoft.Authorization/roleAssignments/write` 필요 |
| 선택적 Playground 기준 호출 | Cognitive Services OpenAI User | 기존 AI 계정. APIM 테스트의 백엔드 호출은 작업자 대신 APIM 관리 ID를 사용 |

위 표는 기본 제공 역할의 실습용 예시입니다. 조직의 사용자 지정 역할과 조건이 있으면 해당 권한으로 대체합니다. **Contributor만으로 역할 할당을 할 수 없습니다.**

### 1-A-2. 입력값 기록

아래 표를 복사해 로컬 작업 기록에 실제 값을 채웁니다. 비밀 값은 표나 Git에 적지 않습니다.

| 항목 | 예시 또는 입력 기준 |
| --- | --- |
| Tenant ID / Azure Subscription ID | 실제 대상 값 |
| 기존 리소스 그룹 | `<existing-resource-group>` |
| APIM 이름 | `apim-ai-gateway-<unique-suffix>` |
| APIM SKU | **Standard v2** |
| APIM 리전 | Standard v2 지원 리전에서 선택 |
| APIM 네트워크 | 공용 네트워크 접근 활성화, VNet Injection·Integration·Private Endpoint 미사용 |
| Publisher name / email | 승인된 일반 조직명 / 관리자 이메일 |
| 리전 A / 리전 B | 예: UAE North / East US 2, 모델·정책 가용성 확인 후 확정 |
| 텍스트 모델 | 기존 `gpt-5.5` 배포의 버전·배포 유형 기록 |
| 이미지 모델 | 기존 `gpt-image-2.5-flare` 배포의 버전·배포 유형 기록 |
| 기존 텍스트 공통 배포 이름 | 예시 `gpt-55`, 실제 배포 이름 사용 |
| 기존 이미지 공통 배포 이름 | 예시 `gpt-image-25-flare`, 실제 배포 이름 사용 |
| 텍스트 / 이미지 API 버전 | 각 배포의 공식 샘플에서 확인한 날짜형 `api-version`; 서로 달라도 됨 |
| 백엔드 분산 방식 | 실습 기본: 우선순위 1 / 2, 가중치 각각 100 |
| 모델 네트워크 경로 | APIM 접근이 허용된 공용 HTTPS 엔드포인트 |

**계정명, 모델명, 배포 이름은 다른 값입니다.** 예를 들어 `aoai-text-a-demo` 계정 안에 모델 `gpt-5.5`를 배포하면서 배포 이름을 `gpt-55`로 지정할 수 있습니다.

### 1-A-3. 기존 계정 네 개의 구성 확인

| 용도 | 로컬 별칭 | 예시 계정명 | 리전 | 배포 이름 |
| --- | --- | --- | --- | --- |
| 텍스트 Primary | Text A | `aoai-text-a-<suffix>` | A | `gpt-55` |
| 텍스트 Secondary | Text B | `aoai-text-b-<suffix>` | B | `gpt-55` |
| 이미지 Primary | Image A | `aoai-image-a-<suffix>` | A | `gpt-image-25-flare` |
| 이미지 Secondary | Image B | `aoai-image-b-<suffix>` | B | `gpt-image-25-flare` |

위 표는 기존 리소스를 구분하기 위한 별칭과 예시이며 생성할 이름이 아닙니다. 텍스트와 이미지가 같은 계정을 사용하면 실제 연결 관계를 기록하고 표에 맞추려고 계정을 추가하지 않습니다.

이후 API 작업 경로의 배포 이름도 실제 기존 이름으로 바꿉니다. 같은 풀의 두 배포 이름이 다르면 백엔드별 경로 매핑이나 API 분리를 먼저 합의합니다. 가이드에 맞추려고 모델 이름을 바꾸거나 재배포하지 않습니다.

### 1-A-4. 모델·쿼터·데이터 처리 위치 확인

1. Foundry 모델 카탈로그에서 목표 모델과 버전을 확인합니다.
2. 각 기존 배포의 상세 화면에서 모델·버전·리전·배포 유형·프로비저닝 성공 상태를 확인합니다. 배포를 새로 만들거나 변경하지 않습니다.
3. Foundry의 Quota 화면에서 구독, 모델, 버전, 배포 유형, 쿼터 풀의 범위와 가용량을 기록합니다.
4. Global Standard는 여러 리전에서 추론을 처리할 수 있습니다. 리소스를 특정 리전에 만들었다고 그 리전에서만 데이터가 처리된다고 가정하지 않습니다.
5. 데이터 주권 요구사항이 있으면 Data Zone/Regional 등 실제 지원 유형과 처리 범위를 보안 담당자와 확인합니다.

**중요:** 2026년 공식 문서는 일부 모델부터 구독 수준 쿼터 관리로 전환하고 있으며 Global Standard는 같은 모델·버전의 여러 리전이 같은 쿼터 풀을 공유할 수 있다고 설명합니다. 반대로 기존 리전별 쿼터가 적용되는 모델도 있을 수 있습니다. 계정이나 리전을 늘리는 것만으로 용량이 배가된다고 계산하지 않습니다.

### 1-A-5. 네트워크·비용 확인

1. 클라이언트 → APIM과 APIM → AI 계정 모두 공용 HTTPS 경로를 사용합니다.
2. APIM의 공용 네트워크 접근을 활성화합니다. 이번 실습을 위한 VNet·서브넷·Private Endpoint·Private DNS를 만들지 않고 아웃바운드 VNet Integration도 설정하지 않습니다.
3. AI 계정의 공용 엔드포인트와 승인된 접근 규칙이 APIM 호출을 허용하는지 확인합니다. APIM 구독 검증과 관리 ID·RBAC 인증은 그대로 필요합니다.
4. 기존 AI 계정이 사설 전용이거나 조직 정책이 필요한 공용 접근을 금지하면 중지하고 별도 설계를 확정합니다. 승인 없이 방화벽을 해제하거나 기존 사설 연결을 변경하지 않습니다.
5. APIM 고정 비용, 모델 추론/프로비저닝 비용, 모니터링·네트워크 비용을 확인합니다. PDF의 무료·Preview 설명을 현재 가격으로 사용하지 않습니다.

### 완료 기준

- [ ] 기존 텍스트·이미지 계정과 배포 이름을 새 리소스 생성 없이 기록했다.
- [ ] APIM 생성·역할 할당·포털 테스트 담당자와 권한을 확인했다. 이번 실습에 모델 관리 권한은 필요하지 않다.
- [ ] 모델별 리전·버전·배포 유형·쿼터 풀이 확인되었다.
- [ ] Standard v2와 VNet·Private Endpoint 없는 공용 HTTPS 접근을 확인하고 비용 승인을 받았다.

### 공식 문서

- [Azure Portal에서 역할 할당](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Azure OpenAI 역할별 권한](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [모델 카탈로그와 가용성](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Azure OpenAI 쿼터와 제한](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- [배포 유형과 데이터 처리 범위](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types)
- [APIM v2 계층과 네트워크 옵션](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)

---

## 1-B. 기존 모델 연결 정보 확인


### 목표와 시작 조건

모델은 모두 배포되어 있습니다. 이 절차는 포털에서 기존 계정·엔드포인트·배포 이름·API 버전을 확인하는 읽기 전용 작업입니다. **Create**, **Deploy model**, 모델 재배포를 선택하거나 기존 로컬 배포 스크립트를 실행하지 않습니다.

### 1-B-1. 기존 계정 찾기

아래 절차를 Text A, Text B, Image A, Image B에 반복합니다.

1. Azure Portal에서 **Azure OpenAI**를 검색합니다.
2. 기존 계정이 있으면 열어 구독·리소스 그룹·리전을 기록합니다.
3. 계정의 **Keys and Endpoint** 또는 개요에서 엔드포인트와 Resource ID를 확인합니다. **키는 복사하거나 문서에 기록하지 않습니다.**
4. 계정별로 엔드포인트가 `https://<account>.openai.azure.com/`인지 확인합니다.
5. 계정의 **Networking**에서 공용 엔드포인트와 접근 규칙이 APIM 호출을 허용하는지 확인합니다. Private Endpoint를 만들거나 기존 규칙을 승인 없이 변경하지 않습니다.

이 절차는 Azure OpenAI 계정에 대한 것입니다. Foundry 프로젝트 API·서버리스 파트너 모델·Azure AI Inference 주소를 동일한 백엔드라고 가정하지 않습니다. 포털이 새 Foundry UI로 연결되면 선택한 배포가 어느 계정의 Azure OpenAI 엔드포인트를 사용하는지 확인합니다.

### 1-B-2. 기존 텍스트 배포 확인

1. Text A 계정에서 **Go to Microsoft Foundry**를 엽니다.
2. 선택한 계정/프로젝트 연결을 확인하고 **Models + endpoints / Deployments**를 엽니다. Classic UI와 새 UI의 메뉴명은 다를 수 있습니다.
3. 기존 `gpt-5.5` 배포를 열어 배포 이름·버전·유형·상태를 기록합니다.
4. **View code / Consume**에서 엔드포인트·지원 API 버전·요청 형식을 확인합니다. 계정 키는 복사하지 않습니다.
5. Text B에서도 모델·버전·요청 호환성을 확인하고 공통 경로를 쓰는 풀의 배포 이름이 같은지 확인합니다.
6. 기존 PTU → PAYG 설계라면 요청 인터페이스가 호환되는 범위에서 배포 유형이 달라도 됩니다.

배포가 없거나 호환되지 않으면 담당자에게 사전 조건 해결을 요청합니다. APIM 구성 과정에서 모델을 생성·증설·이름 변경·교체하지 않습니다.

### 1-B-3. 기존 이미지 배포 확인

1. Image A의 기존 `gpt-image-2.5-flare` 배포를 엽니다.
2. 배포 이름·버전·리전·유형·프로비저닝 성공 상태를 기록합니다.
3. Image B에서도 배포 이름과 API 설정의 호환성을 확인합니다.
4. 모델 공식 문서와 **View code / Consume**에서 입력 필드·출력 형식·엔드포인트·API 버전을 확인합니다.

예상과 달리 모델이 없다면 중지하고 배포 담당자에게 확인합니다. 임시 URL은 기존 모델이 준비되었다는 사전 조건을 충족하지 않습니다.

### 1-B-4. API 경로와 선택적 포털 기준 호출 확인

1. 각 기존 배포의 포털 샘플을 확인하며 SDK나 명령줄 예제는 실행하지 않습니다. 작업자가 이미 접근할 수 있다면 Playground에서 짧은 요청·이미지 1개로 선택적 기준 호출을 수행할 수 있습니다.
2. 선택적 Playground 호출은 Microsoft Entra ID 인증과 작업자의 추론 역할을 확인합니다. 접근할 수 없으면 기준 호출 미실시로 기록하고 5단계에서 APIM을 통해 검증합니다.
3. 포털 샘플에서 실제 엔드포인트, **날짜형 `api-version`**, 배포 이름, 본문 필드, 반환 스키마를 기록하고 호출했다면 결과도 남깁니다.
4. 다음 예시 경로가 기존 배포에서 지원하는 API와 일치하는지 확인합니다.

```text
Text:
https://<text-account>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-api-version>

Image:
https://<image-account>.openai.azure.com/openai/deployments/gpt-image-25-flare/images/generations?api-version=<image-api-version>
```

5. 배포의 공식 샘플이 **`/openai/v1/...`와 본문의 `model`**을 사용하는 경우 위 주소에 날짜 버전만 붙여 변환하지 않습니다. 모델 문서에서 날짜형 배포 API 지원을 확인합니다. v1을 사용하면 4단계의 텍스트 전환 표를 따르고 이미지 모델의 공식 API도 별도로 검증합니다.
6. 선택적 Playground 실패는 APIM 오류와 구분해 기록하고, 확인된 모델 문제는 먼저 해결합니다.

### 기록표

| 계정 | 엔드포인트 | 모델·버전 | 배포 이름 | 배포 유형·쿼터 | API 버전 | 직접 호출 |
| --- | --- | --- | --- | --- | --- | --- |
| Text A | 실제 값 | 실제 값 | 실제 이름 (예: `gpt-55`) | 실제 값 | 실제 값 | 성공/실패/미실시 |
| Text B | 실제 값 | 실제 값 | 실제 이름 (예: `gpt-55`) | 실제 값 | 실제 값 | 성공/실패/미실시 |
| Image A | 실제 값 | 실제 값 | 실제 이름 (예: `gpt-image-25-flare`) | 실제 값 | 실제 값 | 성공/실패/미실시 |
| Image B | 실제 값 | 실제 값 | 실제 이름 (예: `gpt-image-25-flare`) | 실제 값 | 실제 값 | 성공/실패/미실시 |

### 완료 기준

- [ ] 계정 네 개의 Resource ID와 엔드포인트를 확보했다.
- [ ] 같은 풀에 들어갈 두 배포의 이름과 API 호환성을 확인했다.
- [ ] 기존 배포 상태와 API 호환성을 확인하고 선택적 Playground 결과를 기록했거나 호출 검증을 5단계로 넘겼다.
- [ ] 텍스트·이미지의 API 버전을 따로 기록했다.

### 문제 해결

- **모델이 보이지 않음:** 모델 카탈로그, 리전, 배포 유형, 구독 접근 조건을 확인합니다.
- **429:** 실제 쿼터 풀과 모델 배포 용량을 확인합니다. 계정을 추가하는 것만으로 해결된다고 가정하지 않습니다.
- **404:** 계정·배포 이름·API 경로·API 버전을 대조합니다.
- **403/연결 실패:** 테스트 작업자 RBAC와 공용 네트워크 접근 규칙·방화벽·공용 DNS를 분리해서 점검합니다.

### 공식 문서

- [모델 목록과 리전 가용성](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [이미지 생성 모델 사용 방법](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [API 버전 수명 주기와 v1 차이](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)

---

## 1-C. Standard v2 APIM을 공용 네트워크로 생성


### 목표

API·정책·백엔드 풀을 제공할 Standard v2 APIM을 공용 연결로 준비합니다. 기존 서비스는 이 구성과 작업자 권한을 확인한 뒤 재사용하며 SKU나 네트워크를 임의로 변경하지 않습니다.

### 1-C-1. 확정 구성 확인

이번 실습의 SKU와 네트워크는 다음 값으로 고정합니다.

| 항목 | 설정값 | 비고 |
| --- | --- | --- |
| APIM 가격 계층 | **Standard v2** | 초기 용량 1, 실제 부하는 별도 검증 |
| 인바운드 연결 | 공용 HTTPS | 공용 네트워크 접근 활성화, 구독 검증 유지 |
| VNet Injection | 미사용 | VNet·서브넷을 선택하지 않음 |
| 아웃바운드 VNet Integration | 비활성 / 미설정 | AI 계정의 공용 엔드포인트 호출 |
| Private Endpoint | 미설정 | 이 구성에는 Private DNS 준비가 필요하지 않음 |

**서로 다른 리전의 AI 백엔드 두 개를 호출하는 것**과 **APIM 게이트웨이 자체를 멀티 리전에 배포하는 것**은 별개입니다. Standard v2 APIM 한 개로도 여러 리전의 AI 백엔드를 사용할 수 있습니다.

VNet Injection과 아웃바운드 VNet Integration은 다른 기능입니다. Standard v2는 아웃바운드 Integration을 지원하지만 이번 구성에서는 둘 다 사용하지 않습니다. 사설 연결을 사전 조건으로 추가하지 않습니다.

### 1-C-2. 인스턴스 생성

1. Azure Portal에서 **API Management services → Create**를 선택합니다.
2. **Basics**에 다음 값을 입력합니다.

| 필드 | 입력값 |
| --- | --- |
| Subscription | 1단계에서 확인한 구독 |
| Resource group | 기존 리소스 그룹 |
| Region | 가용성과 지연 시간을 고려해 정한 APIM 리전 |
| Resource name | 고유한 `apim-ai-gateway-<unique-suffix>` |
| Organization name | 승인된 조직명 |
| Administrator email | 실제 관리자 이메일 |
| Pricing tier | **Standard v2** |
| Units | 초기 용량 1, 부하 검증 후 조정 |

3. **Monitor + secure**의 추가 서비스는 비용과 필요성을 확인하고 선택합니다.
4. **Networking**에서 공용 엔드포인트를 사용하고 **Public network access를 활성화**합니다. 가상 네트워크 항목이 표시되면 **None / 미설정**으로 두고, VNet Integration을 켜거나 Private Endpoint를 추가하지 않습니다.
5. **Managed identity** 탭에서 System assigned를 켤 수 있습니다. 여기서 켰다면 2단계는 확인만 수행합니다.
6. **Review + create**에서 요금·SKU·네트워크·기존 리소스 그룹을 다시 확인합니다.
7. **Create** 후 배포가 끝나고 서비스가 Online이 될 때까지 기다립니다. 고정된 완료 시간을 가정하지 않습니다.
8. 개요에서 게이트웨이 URL `https://<apim-name>.azure-api.net`을 기록합니다.

### 1-C-3. 네트워크 확인

- APIM의 **Networking**에서 공용 네트워크 접근 활성화, VNet Integration 미설정, 이번 실습용 Private Endpoint 미추가를 확인합니다.
- APIM과 두 리전의 AI 엔드포인트에 대해 공용 DNS·HTTPS 도달성을 확인합니다.
- AI 계정 접근 규칙이 APIM 호출을 허용하는지 확인합니다. 공용 엔드포인트 활성화가 모든 호출 허용이나 APIM의 고정 아웃바운드 IP를 의미한다고 가정하지 않습니다.
- APIM 구독 키 검증과 AI 계정 관리 ID 인증을 유지합니다. 공용 접근은 네트워크 선택이며 익명 접근이 아닙니다.
- 기존 사설 전용 계정을 승인 없이 바꾸지 말고, 구성 불일치를 해결한 뒤 진행합니다.

### 완료 기준

- [ ] 배포된 가격 계층이 **Standard v2**임을 확인했다.
- [ ] APIM이 Online이며 게이트웨이 URL이 확인되었다.
- [ ] 공용 네트워크 접근이 활성화되어 있고 이번 실습에 VNet Injection·Integration·Private Endpoint가 구성되지 않았다.
- [ ] 클라이언트 → APIM, APIM → AI 계정의 공용 HTTPS 접근 규칙을 확인했다.

### 문제 해결

- **선택한 리전에서 Standard v2 사용 불가:** 가용성을 확인해 승인된 Standard v2 지원 리전으로 조정하며 다른 SKU로 임의 변경하지 않습니다.
- **생성 권한 없음:** 기존 APIM에만 부여된 권한인지, 리소스 그룹에 생성 권한이 있는지 확인합니다.
- **공용 백엔드 연결 실패:** 관리 ID와 별개로 공용 네트워크 접근·계정 접근 규칙·공용 DNS·TLS를 확인합니다.

### 공식 문서

- [Portal에서 APIM 만들기](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [SKU별 기능 비교](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- [v2 계층과 네트워크 차이](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
