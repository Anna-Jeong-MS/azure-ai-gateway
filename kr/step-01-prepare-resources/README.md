# 01. APIM 생성

[English](../../step-01-prepare-resources/README.md) | 한국어

[전체 목차](../README.md) | [다음: API 생성](../step-02-create-apis/README.md)

## 1-1. 작업자 권한 확인

1. [Azure Portal](https://portal.azure.com)에 로그인합니다.
2. 디렉터리·구독·대상 리소스 그룹을 확인합니다.
3. **Access control (IAM) → View my access**에서 다음 권한을 확인합니다.

| 작업 | 필요한 권한 |
| --- | --- |
| APIM 생성 | 대상 리소스 그룹의 Contributor 또는 동등 권한 |
| APIM 설정 | APIM의 API Management Service Contributor 또는 동등 권한 |
| 모델 계정 역할 할당 | 각 AI 계정 범위의 Role Based Access Control Administrator, User Access Administrator, Owner 또는 동등한 역할 할당 권한 |

Contributor만으로는 역할을 할당할 수 없습니다.

## 1-2. 배포된 모델 정보 기록

모델은 이미 배포되어 있습니다. 모델을 생성하거나 변경하지 않고 연결 정보만 기록합니다.

1. 각 Azure OpenAI 계정의 **Overview / Keys and Endpoint**에서 **Resource ID**와 엔드포인트를 기록합니다.
2. Foundry의 **Models + endpoints / Deployments**에서 배포를 엽니다.
3. 배포 이름·모델/버전·리전·배포 유형·프로비저닝 상태를 기록합니다.
4. **View code / Consume**에서 지원하는 날짜형 `api-version`과 요청 스키마를 확인합니다. 모델 키는 복사하지 않습니다.
5. 계정의 공용 네트워크 접근 규칙이 APIM 호출을 허용하는지 확인합니다.

| 별칭 | 모델 | 가이드의 배포 이름 예시 |
| --- | --- | --- |
| Text A / Text B | `gpt-5.5` | `gpt-55` |
| Image A / Image B | `gpt-image-2.5-flare` | `gpt-image-25-flare` |

이후 URL에는 실제 배포 이름을 사용합니다. 이번 구성은 이미지 작업 경로를 공유하므로 두 이미지 계정의 배포 이름이 같은 것을 사용합니다. 텍스트는 각 백엔드 기본 URL에 해당 배포 이름을 지정합니다.

모델의 가용 쿼터와 데이터 처리 위치 요구사항을 기록합니다. 계정·리전 간 쿼터 풀이 공유될 수 있으므로 리전 분리만으로 용량이 늘어난다고 계산하지 않습니다.

## 1-3. Standard v2 APIM 생성

1. **API Management services → Create**를 선택합니다.
2. **Basics**를 입력합니다.

| 항목 | 입력값 |
| --- | --- |
| Subscription | 대상 구독 |
| Resource group | 대상 리소스 그룹 |
| Region | 승인된 Standard v2 지원 리전 |
| Resource name | `apim-ai-gateway-<unique-suffix>` |
| Organization name | 조직명 |
| Administrator email | 관리자 이메일 |
| Pricing tier | **Standard v2** |
| Units | **1** |

3. **Monitor + secure**에서 이번 배포에 승인된 모니터링 서비스만 선택합니다.
4. **Networking**에서 **Public network access를 활성화**합니다. 가상 네트워크는 **None / 미설정**으로 두고 VNet Integration·Private Endpoint는 추가하지 않습니다.
5. **Tags**를 입력하고 **Review + create → Create**를 선택합니다.
6. 배포가 완료되고 APIM이 Online이 될 때까지 기다립니다.
7. 게이트웨이 URL `https://<apim-name>.azure-api.net`을 기록합니다.
8. 바로 2단계로 이동하여 API를 생성합니다.

## 완료 기준

- [ ] 텍스트·이미지 엔드포인트, 배포 이름, Resource ID, API 버전을 기록했다.
- [ ] APIM에서 모델 계정으로 공용 접근할 수 있다.
- [ ] Standard v2 APIM이 Online이며 공용 접근·VNet/Private Endpoint 미설정 상태다.

## 공식 문서

- [포털에서 APIM 생성](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance)
- [APIM v2 계층](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [포털에서 역할 할당](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
- [모델 쿼터와 제한](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
