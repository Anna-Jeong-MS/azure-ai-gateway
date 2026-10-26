# 01. 사전 준비와 리소스 생성

[English](../../step-01-prepare-resources/README.md) | 한국어

[전체 목차](../README.md) | [다음: 02. 관리 ID와 접근 권한](../step-02-identity-access/README.md)

## 1-A. 사전 준비와 입력값 확정


### 목표

리소스를 만들기 전에 구독·권한·모델·네트워크·비용을 확인합니다. 기존 리소스 그룹을 그대로 사용하며 이 단계에서는 리소스를 변경하지 않습니다.

### 1-A-1. 작업자 권한 확인

1. [Azure Portal](https://portal.azure.com)에 로그인하고 우측 상단의 디렉터리와 구독을 확인합니다.
2. 기존 리소스 그룹을 엽니다.
3. **Access control (IAM) → View my access**에서 본인의 역할과 범위를 확인합니다.
4. 아래 작업의 담당자를 정합니다. PIM을 사용하는 조직은 필요한 역할을 활성화하고, 역할 할당 조건·Deny Assignment·Azure Policy도 확인합니다.

| 작업 | 일반적인 역할 예시 | 범위·주의 |
| --- | --- | --- |
| APIM과 AI 계정 신규 생성 | Contributor | 대상 리소스 그룹. 새 리소스가 아직 없으므로 기존 APIM 리소스만의 권한으로는 신규 생성 불가 |
| 기존 APIM의 API·백엔드·관리 ID 관리 | API Management Service Contributor 또는 Contributor | 대상 APIM. 사용자 할당 ID 연결은 별도 권한이 필요할 수 있으나 이번 실습은 시스템 할당 사용 |
| 모델 배포 관리 | Cognitive Services OpenAI Contributor | 이미 있는 Azure OpenAI 계정. 계정 신규 생성 권한과는 별개 |
| APIM 관리 ID에 역할 부여 | Role Based Access Control Administrator, User Access Administrator 또는 Owner | 역할을 부여할 AI 계정 또는 상위 범위에서 `Microsoft.Authorization/roleAssignments/write` 필요 |
| 직접 추론 테스트 | Cognitive Services OpenAI User | 호출할 AI 계정. Contributor라는 이름만으로 데이터 평면 추론 권한을 가정하지 않음 |

위 표는 기본 제공 역할의 실습용 예시입니다. 조직의 사용자 지정 역할과 조건이 있으면 해당 권한으로 대체합니다. **Contributor만으로 역할 할당을 할 수 없습니다.**

### 1-A-2. 입력값 기록

아래 표를 복사해 로컬 작업 기록에 실제 값을 채웁니다. 비밀 값은 표나 Git에 적지 않습니다.

| 항목 | 예시 또는 입력 기준 |
| --- | --- |
| Tenant ID / Azure Subscription ID | 실제 대상 값 |
| 기존 리소스 그룹 | `<existing-resource-group>` |
| APIM 이름 | `apim-ai-gateway-<unique-suffix>` |
| APIM 리전 | Standard v2 지원 리전에서 선택 |
| Publisher name / email | 승인된 일반 조직명 / 관리자 이메일 |
| 리전 A / 리전 B | 예: UAE North / East US 2, 모델·정책 가용성 확인 후 확정 |
| 텍스트 모델 | 목표 `gpt-5.5`, 정확한 버전·배포 유형 기록 |
| 이미지 모델 | 목표 `gpt-image-2.5-flare`, 정확한 버전·배포 유형 기록 |
| 텍스트 공통 배포 이름 | `gpt-55` |
| 이미지 공통 배포 이름 | `gpt-image-25-flare` |
| 텍스트 / 이미지 API 버전 | 각 배포의 공식 샘플에서 확인한 날짜형 `api-version`; 서로 달라도 됨 |
| 백엔드 분산 방식 | 실습 기본: 우선순위 1 / 2, 가중치 각각 100 |
| 모델 네트워크 경로 | 승인된 공용 경로 또는 사설 경로 |

**계정명, 모델명, 배포 이름은 다른 값입니다.** 예를 들어 `aoai-text-a-demo` 계정 안에 모델 `gpt-5.5`를 배포하면서 배포 이름을 `gpt-55`로 지정할 수 있습니다.

### 1-A-3. 계정 네 개의 배치 계획

| 용도 | 로컬 별칭 | 예시 계정명 | 리전 | 배포 이름 |
| --- | --- | --- | --- | --- |
| 텍스트 Primary | Text A | `aoai-text-a-<suffix>` | A | `gpt-55` |
| 텍스트 Secondary | Text B | `aoai-text-b-<suffix>` | B | `gpt-55` |
| 이미지 Primary | Image A | `aoai-image-a-<suffix>` | A | `gpt-image-25-flare` |
| 이미지 Secondary | Image B | `aoai-image-b-<suffix>` | B | `gpt-image-25-flare` |

텍스트와 이미지는 한 계정에 함께 배포할 수도 있지만, 이번 요구사항을 따라 계정 네 개로 설명합니다. 이미 준비된 계정이 있으면 새로 만들지 말고 재사용합니다.

### 1-A-4. 모델·쿼터·데이터 처리 위치 확인

1. Foundry 모델 카탈로그에서 목표 모델과 버전을 확인합니다.
2. **각 모델**이 리전 A와 B에서 선택한 배포 유형으로 배포 가능한지 확인합니다. 하나라도 불가능하면 리전을 바꾸거나 승인된 대안을 정한 뒤 진행합니다.
3. Foundry의 Quota 화면에서 구독, 모델, 버전, 배포 유형, 쿼터 풀의 범위와 가용량을 기록합니다.
4. Global Standard는 여러 리전에서 추론을 처리할 수 있습니다. 리소스를 특정 리전에 만들었다고 그 리전에서만 데이터가 처리된다고 가정하지 않습니다.
5. 데이터 주권 요구사항이 있으면 Data Zone/Regional 등 실제 지원 유형과 처리 범위를 보안 담당자와 확인합니다.

**중요:** 2026년 공식 문서는 일부 모델부터 구독 수준 쿼터 관리로 전환하고 있으며 Global Standard는 같은 모델·버전의 여러 리전이 같은 쿼터 풀을 공유할 수 있다고 설명합니다. 반대로 기존 리전별 쿼터가 적용되는 모델도 있을 수 있습니다. 계정이나 리전을 늘리는 것만으로 용량이 배가된다고 계산하지 않습니다.

### 1-A-5. 네트워크·비용 확인

1. 클라이언트 → APIM과 APIM → AI 계정의 네트워크를 각각 확인합니다.
2. 사설 AI 계정이라면 APIM 아웃바운드 VNet Integration, 연결된 네트워크, Private Endpoint 승인, Private DNS를 먼저 준비합니다.
3. APIM 인바운드를 사설로 제한하면 테스트 PC도 해당 네트워크에 접근할 수 있어야 합니다. Portal 테스트 버튼이 네트워크 제한을 자동 우회하지는 않습니다.
4. 공용 테스트가 조직 정책상 허용되지 않으면 임의로 방화벽을 해제하지 않습니다.
5. APIM 고정 비용, 모델 추론/프로비저닝 비용, 모니터링·네트워크 비용을 확인합니다. PDF의 무료·Preview 설명을 현재 가격으로 사용하지 않습니다.

### 선택: CLI 세션 준비

Azure CLI가 설치된 PowerShell에서만 실행합니다. 포털만 사용할 경우 생략해도 됩니다.

```powershell
az login
$SubscriptionId = "<subscription-id>"
$ResourceGroup = "<existing-resource-group>"
$ApimName = "<apim-name>"
az account set --subscription $SubscriptionId
az account show --query "{subscription:id, tenant:tenantId, name:name}" --output table
```

새 PowerShell 창에서는 변수와 로그인 컨텍스트를 다시 확인합니다.

### 완료 기준

- [ ] 계정 4개의 실제 값과 기존 리소스 재사용 여부를 기록했다.
- [ ] 생성·모델 배포·역할 할당·테스트 담당자와 권한을 확인했다.
- [ ] 모델별 리전·버전·배포 유형·쿼터 풀이 확인되었다.
- [ ] 네트워크와 비용 승인을 받았다.

### 공식 문서

- [Azure Portal에서 역할 할당](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [Azure OpenAI 역할별 권한](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [모델 카탈로그와 가용성](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Azure OpenAI 쿼터와 제한](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- [배포 유형과 데이터 처리 범위](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types)
- [APIM Private Endpoint](https://learn.microsoft.com/en-us/azure/api-management/private-endpoint)

---

## 1-B. AI 계정 생성과 모델 배포


### 목표와 시작 조건

1단계에서 확정한 계정 네 개와 모델 배포 네 개를 준비합니다. **기존 계정·배포가 있으면 확인만 하고 재사용**합니다. 원본 초안과 다른 텍스트 모델이 들어 있는 로컬 배포 스크립트를 실행하지 않습니다.

### 1-B-1. 계정 생성 또는 기존 계정 확인

아래 절차를 Text A, Text B, Image A, Image B에 반복합니다.

1. Azure Portal에서 **Azure OpenAI**를 검색합니다.
2. 기존 계정이 있으면 열어 구독·리소스 그룹·리전을 기록합니다.
3. 새 계정이 필요한 경우 **Create**를 선택합니다.
4. 기존 리소스 그룹, 확정한 리전, 전역에서 고유한 계정 이름을 입력합니다.
5. 제공되는 가격 계층과 조직이 승인한 네트워크 설정을 선택합니다.
6. **Review + create → Create**를 선택하고 배포 완료를 기다립니다.
7. 계정의 **Keys and Endpoint** 또는 개요에서 엔드포인트와 Resource ID를 확인합니다. **키는 복사하거나 문서에 기록하지 않습니다.**
8. 계정별로 엔드포인트가 `https://<account>.openai.azure.com/`인지 확인합니다.

이 절차는 Azure OpenAI 계정에 대한 것입니다. Foundry 프로젝트 API·서버리스 파트너 모델·Azure AI Inference 주소를 동일한 백엔드라고 가정하지 않습니다. 포털이 새 Foundry UI로 연결되면 선택한 배포가 어느 계정의 Azure OpenAI 엔드포인트를 사용하는지 확인합니다.

### 1-B-2. 텍스트 모델 배포

1. Text A 계정에서 **Go to Microsoft Foundry**를 엽니다.
2. 선택한 계정/프로젝트 연결을 확인하고 **Models + endpoints / Deployments**에서 **Deploy model**을 선택합니다. Classic UI와 새 UI의 메뉴명은 다를 수 있습니다.
3. 카탈로그에서 `gpt-5.5`를 찾습니다.
4. 승인한 모델 버전과 배포 유형을 선택합니다.
5. 배포 이름을 **`gpt-55`**로 지정합니다.
6. 할당 가능한 쿼터 내에서 용량을 설정하고 배포합니다.
7. Text B에서도 **같은 배포 이름·모델·버전·호출 스키마**로 반복합니다.
8. PTU → PAYG 전환을 의도한 경우에는 배포 유형을 다르게 할 수 있지만, 모델·버전·요청 호환성은 같아야 합니다.

배포가 목록에 없거나 승인·쿼터 오류가 나면 여기서 중지합니다. 다른 모델로 조용히 바꾸지 말고 1단계의 입력값을 갱신하고 승인을 받습니다.

### 1-B-3. 이미지 모델 배포

1. Image A의 모델 카탈로그에서 `gpt-image-2.5-flare`를 찾습니다.
2. 실제 구독에 허용된 버전·배포 유형·리전을 확인합니다.
3. 배포 이름을 **`gpt-image-25-flare`**로 지정하고 배포합니다.
4. Image B에서도 같은 이름과 호환 설정으로 반복합니다.
5. 이미지 생성 API가 지원하는 입력 필드와 출력 형식을 해당 모델의 공식 문서 및 배포의 **View code / Consume**에서 확인합니다.

이미지 모델이 아직 배포되지 않았다면 이미지 분기는 미완료입니다. 임시 URL만 넣고 이미지 API까지 성공한 것으로 처리하지 않습니다.

### 1-B-4. APIM을 거치지 않은 기준 호출

1. 각 배포의 Playground 또는 공식 샘플에서 텍스트/이미지 생성 요청을 한 번씩 실행합니다. 비용이 발생하므로 짧은 요청과 이미지 1개만 사용합니다.
2. 가능하면 Microsoft Entra ID 인증을 사용합니다. 테스트 작업자에게도 계정 범위의 추론 역할이 있어야 합니다.
3. 각 호출에서 실제 엔드포인트, **날짜형 `api-version`**, 배포 이름, 본문 필드, 성공 상태 코드와 반환 스키마를 기록합니다.
4. 본 실습에서 사용할 경로가 다음과 일치하는지 확인합니다.

```text
Text:
https://<text-account>.openai.azure.com/openai/deployments/gpt-55/chat/completions?api-version=<text-api-version>

Image:
https://<image-account>.openai.azure.com/openai/deployments/gpt-image-25-flare/images/generations?api-version=<image-api-version>
```

5. 배포의 공식 샘플이 **`/openai/v1/...`와 본문의 `model`**을 사용하는 경우 위 주소에 날짜 버전만 붙여 변환하지 않습니다. 날짜형 배포 API 지원을 해당 모델 문서에서 확인하고 기준 호출이 성공한 후 진행합니다. v1만 사용하기로 결정하면 4단계의 v1 전환 표대로 텍스트 경로를 별도 구성하고, 이미지도 해당 모델의 공식 API에 맞춰 별도 검증합니다.
6. 직접 호출이 실패하면 APIM 설정을 시작하기 전에 모델·권한·네트워크 문제를 해결합니다.

### 기록표

| 계정 | 엔드포인트 | 모델·버전 | 배포 이름 | 배포 유형·쿼터 | API 버전 | 직접 호출 |
| --- | --- | --- | --- | --- | --- | --- |
| Text A | 실제 값 | 실제 값 | `gpt-55` | 실제 값 | 실제 값 | 성공/실패 |
| Text B | 실제 값 | 실제 값 | `gpt-55` | 실제 값 | 실제 값 | 성공/실패 |
| Image A | 실제 값 | 실제 값 | `gpt-image-25-flare` | 실제 값 | 실제 값 | 성공/실패 |
| Image B | 실제 값 | 실제 값 | `gpt-image-25-flare` | 실제 값 | 실제 값 | 성공/실패 |

### 완료 기준

- [ ] 계정 네 개의 Resource ID와 엔드포인트를 확보했다.
- [ ] 같은 풀에 들어갈 두 배포의 이름과 API 호환성을 확인했다.
- [ ] 모델 네 개 모두 실제 생성 호출이 성공했다.
- [ ] 텍스트·이미지의 API 버전을 따로 기록했다.

### 문제 해결

- **모델이 보이지 않음:** 모델 카탈로그, 리전, 배포 유형, 구독 접근 조건을 확인합니다.
- **429:** 실제 쿼터 풀과 모델 배포 용량을 확인합니다. 계정을 추가하는 것만으로 해결된다고 가정하지 않습니다.
- **404:** 계정·배포 이름·API 경로·API 버전을 대조합니다.
- **403/연결 실패:** 테스트 작업자 RBAC와 방화벽·사설 DNS를 분리해서 점검합니다.

### 공식 문서

- [Azure OpenAI 계정 생성과 배포: Classic 포털 기준](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/create-resource)
- [모델 목록과 리전 가용성](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [이미지 생성 모델 사용 방법](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/dall-e)
- [API 버전 수명 주기와 v1 차이](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)

---

## 1-C. APIM SKU 선택과 생성


### 목표

이번 요구사항의 API·정책·백엔드 풀을 제공할 APIM을 준비합니다. APIM이 이미 있으면 SKU·리전·네트워크·접근 권한을 확인하고 생성 절차는 생략합니다.

### 1-C-1. SKU 선택

아래는 **이번 실습의 설계 제안**이며 모든 운영 환경에 대한 일괄 권장은 아닙니다. 실제 비용·처리량·네트워크 요구사항으로 확정합니다.

| SKU | 이번 실습에서의 판단 | 공식 기능상 주의 |
| --- | --- | --- |
| Standard v2 | 운영 후보이자 본 가이드 기준 | SLA, 아웃바운드 VNet Integration, 게이트웨이 인바운드 Private Endpoint 지원 |
| Basic v2 | 네트워크 격리가 필요 없는 개발·검증 후보 | SLA가 있지만 Standard v2와 동일한 사설 연결 기능은 아님 |
| Developer | 비운영 개발·평가 전용 | SLA 없음 |
| Premium (classic) | APIM 자체의 멀티 리전 배포가 필요한 경우 검토 | Premium v2와 같은 상품으로 취급하지 않음 |
| Premium v2 | VNet Injection·가용 영역·대규모 용량이 필요할 때 검토 | 현재 기능 비교표상 APIM 멀티 리전 배포는 지원하지 않음 |
| Consumption | 이번 실습에서는 제외 | 백엔드 서킷 브레이커 미지원. 토큰 제한 등 정책 지원 범위도 다름 |

**서로 다른 리전의 AI 백엔드 두 개를 호출하는 것**과 **APIM 게이트웨이 자체를 멀티 리전에 배포하는 것**은 별개입니다. Standard v2 APIM 한 개로도 여러 리전의 AI 백엔드를 사용할 수 있습니다.

Standard v2에 인바운드 Private Endpoint를 구성할 수 있으므로 “Private Endpoint가 필요하면 무조건 Premium”이라고 판단하지 않습니다.

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
| Pricing tier | 확정한 SKU, 가이드 기준 Standard v2 |
| Units | 초기 용량 1, 부하 검증 후 조정 |

3. **Monitor + secure**의 추가 서비스는 비용과 필요성을 확인하고 선택합니다.
4. **Networking**에서 승인된 구성을 선택합니다.
5. **Managed identity** 탭에서 System assigned를 켤 수 있습니다. 여기서 켰다면 2단계는 확인만 수행합니다.
6. **Review + create**에서 요금·SKU·네트워크·기존 리소스 그룹을 다시 확인합니다.
7. **Create** 후 배포가 끝나고 서비스가 Online이 될 때까지 기다립니다. 고정된 완료 시간을 가정하지 않습니다.
8. 개요에서 게이트웨이 URL `https://<apim-name>.azure-api.net`을 기록합니다.

### 1-C-3. 네트워크 확인

- AI 계정이 공용 엔드포인트를 사용하더라도 해당 계정 방화벽이 APIM 접근을 허용하는지 확인합니다.
- AI 계정이 사설이라면 APIM의 아웃바운드 경로와 이름 해석을 구성합니다. 리전 B까지의 네트워크 도달성도 필요합니다.
- APIM에 인바운드 Private Endpoint를 사용하면 승인 상태·Private DNS·클라이언트 네트워크를 확인한 뒤 공용 접근 제한을 적용합니다.
- Standard v2의 VNet Integration은 APIM과 같은 리전·구독의 VNet을 사용합니다. 원격 AI 계정으로의 라우팅은 연결된 네트워크 설계로 별도 확보합니다.

### 완료 기준

- [ ] SKU를 선택한 근거를 기록했다.
- [ ] APIM이 Online이며 게이트웨이 URL이 확인되었다.
- [ ] 클라이언트 → APIM, APIM → AI 계정의 네트워크 계획이 확인되었다.

### 문제 해결

- **SKU/리전 선택 불가:** 현재 지역 가용성을 확인하고 승인된 리전으로 조정합니다.
- **생성 권한 없음:** 기존 APIM에만 부여된 권한인지, 리소스 그룹에 생성 권한이 있는지 확인합니다.
- **사설 백엔드 연결 실패:** 관리 ID 단계와 무관하게 DNS·VNet·방화벽을 먼저 확인합니다.

### 공식 문서

- [Portal에서 APIM 만들기](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [SKU별 기능 비교](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- [v2 계층과 네트워크 차이](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [인바운드 Private Endpoint](https://learn.microsoft.com/en-us/azure/api-management/private-endpoint)
