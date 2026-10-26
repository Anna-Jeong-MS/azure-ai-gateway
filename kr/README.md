# Azure AI Gateway

[English](../README.md) | 한국어

Azure API Management와 Azure OpenAI를 사용해 텍스트·이미지 모델 앞에 AI Gateway를 구성하는 한국어 실습 가이드입니다.

공식 문서 확인일: **2026-10-26**. 포털 언어와 업데이트에 따라 메뉴 이름이 달라질 수 있으므로 영문 메뉴를 함께 표기합니다.

## 단계별 구성

루트의 **5개 폴더**를 순서대로 진행합니다. 각 폴더 안에 관련 작업을 묶었으며 입력값·작업 순서·완료 기준·문제 해결·Microsoft 공식 문서 링크를 제공합니다.

| 단계 | 묶어서 진행할 작업 |
| --- | --- |
| [01. 기존 모델 확인과 APIM 준비](step-01-prepare-resources/README.md) | 기존 엔드포인트·배포 이름 기록 → 권한·공용 연결 확인 → Standard v2 APIM 생성 |
| [02. API 생성](step-02-create-apis/README.md) | APIM 생성 직후 텍스트 Language Model API·이미지 일반 HTTP API 생성 → 자동 텍스트 백엔드 기록 |
| [03. 관리 ID·백엔드·풀](step-03-backend-pools/README.md) | 관리 ID·계정 역할 → 자동 생성 Text Primary 재사용 → 백엔드 3개 추가·풀 구성 |
| [04. API 라우팅·정책](step-04-api-policies/README.md) | 기존 API 재사용·구독 생성 → 자동 텍스트 경로를 풀로 교체 → 선택적 제한·재시도 |
| [05. 검증과 운영 점검](step-05-validation/README.md) | 정상·오류·개별 백엔드·전환 테스트 → 모니터링·최종 체크리스트 |

각 작업의 **완료 기준을 충족한 뒤** 다음으로 이동합니다. 선택 기능은 기본 호출이 성공한 다음 적용합니다.

**API 생성은 APIM 생성 바로 다음인 2단계입니다.** 텍스트는 **Language Model API → Create OpenAI API**, 이미지는 **HTTP 일반 API**로 만듭니다. 텍스트 마법사가 만드는 백엔드 1개를 Primary로 재사용하고 Text Secondary·이미지 2개만 추가하여 **자동 1개 + 수동 3개 = 단일 백엔드 총 4개**로 구성합니다.

## 전체 구성

```text
클라이언트 -- 공용 HTTPS + APIM 구독 키 --> APIM Standard v2 (시스템 할당 관리 ID)
                               |
                               +-- /text  --> text-pool
                               |              +-- 자동 생성 Text Primary (리전 A)
                               |              +-- text-aoai-02 (리전 B)
                               |
                               +-- /image --> image-pool
                                              +-- image-aoai-01 (리전 A)
                                              +-- image-aoai-02 (리전 B)

APIM -- 공용 HTTPS + Entra 토큰 --> 각 Azure OpenAI 계정
```

## 범위와 원본 대응

로컬 원본 PDF의 관리 ID·토큰 제한·백엔드 풀 예시를 바탕으로, 로컬 요구사항의 **텍스트 모델 2개 + 이미지 모델 2개** 구성을 실제 작업 순서로 정리했습니다. 고객사명·계정명·리소스 식별자는 새 가이드에 옮기지 않았습니다.

| 원본 내용 | 가이드 위치 |
| --- | --- |
| PDF p.16: 보안·복원력·확장성·관측 개요 | 02~05 |
| PDF p.20~21: 팀별 2,000 TPM, 구독 ID 기준 분리, 키 없는 인증 | 03, 04의 선택적 토큰 제한, 05 |
| PDF p.22: PTU/PAYG 백엔드 풀·서킷 브레이커 | 03, 05의 전환 검증 |
| 요구사항의 Standard v2·기존 모델 정보·작업자 권한 | 01, 03 |
| 요구사항의 API·백엔드·풀·정책·점검 목록 | 02~05 |
| PDF p.8·23·29의 의미 기반 캐시, p.9·24의 Content Safety | 이번 필수 구성 밖의 후속 확장 |
| PDF의 MCP·A2A·API Center·Foundry Preview 소개 | 이번 요구사항의 실습 범위에 포함하지 않음 |

PDF는 기능 소개 자료이므로 무료 호출량·가격·GA/Preview·지원 리전 표시는 현재 조건으로 재사용하지 않습니다. 캐시와 Content Safety에는 별도 리소스·권한·정책·검증이 필요하며 이번 실습 완료만으로 구성되지 않습니다.

## 공식 문서에 따라 보완한 점

- **확정 구성:** **Standard v2 + 공용 네트워크 접근 활성화**를 사용합니다. 이번 실습에서는 VNet Injection, 아웃바운드 VNet Integration, Private Endpoint를 구성하지 않습니다. 서로 다른 리전의 AI 계정을 호출하는 것과 APIM 자체의 멀티 리전 배포는 별개입니다. [SKU 비교](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- **쿼터:** 리전 분리가 용량 증가를 보장하지 않습니다. 최신 구독 수준 공유 풀 적용 여부를 해당 모델·버전·배포 유형별로 확인합니다. [쿼터와 제한](https://learn.microsoft.com/en-us/azure/foundry/openai/quotas-limits)
- **API 분리:** 경로가 다르다고 API 분리가 기술적으로 필수인 것은 아닙니다. 이 실습은 텍스트·이미지의 정책과 운영을 분리하려고 API 두 개를 사용합니다.
- **전환과 재시도:** 회로 차단·풀 선택·현재 요청 재시도는 별개입니다. 텍스트의 백엔드 429만 선택적으로 한 번 재시도하며 이미지 생성 POST는 기본 자동 재시도하지 않습니다.
- **인증:** 클라이언트의 APIM 구독 키와 APIM의 모델 호출용 관리 ID는 별개입니다. `Cognitive Services OpenAI User`는 추론 외 일부 읽기도 허용하는 역할입니다. [역할별 권한](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)

## 사용 전 확인

- 텍스트 `gpt-5.5`와 이미지 `gpt-image-2.5-flare`는 **이미 배포된 상태**입니다. 실제 엔드포인트·배포 이름·버전·유형만 확인하며 AI 계정 생성이나 모델 배포·이름 변경·증설은 수행하지 않습니다.
- 기본 호출은 Azure OpenAI와 날짜형 `api-version`을 사용합니다. 텍스트는 배포 경로가 포함된 백엔드 기본 URL에 자동 생성 `/chat/completions` 작업을 연결하고, 이미지는 `/openai` 기본 URL에 배포 경로가 있는 수동 작업을 연결합니다. 두 구성이나 v1 경로를 섞지 않으며 텍스트 v1 대안은 04단계에 구분했습니다.
- `<...>`는 사용자가 채울 값입니다. 실제 고객 환경 값과 비밀은 로컬 기록에만 보관합니다.
- 리소스 설정과 테스트는 정책 편집기·API 테스트 콘솔을 포함해 **Azure Portal에서만** 진행합니다. CLI·PowerShell·Cloud Shell 실행 단계는 없습니다.
- 공용 연결이 익명 접근을 의미하지는 않습니다. APIM 구독 검증과 모델 계정의 관리 ID·RBAC 인증은 유지합니다.
- 기존 로컬 PDF·요구사항·이미지·배포 코드·정책은 유지하고 `.gitignore`로 GitHub 업로드에서 제외합니다. 새 문서는 기존 스크립트나 정책 파일을 덮어쓰지 않습니다.
- 문서 작성 중 Azure 생성·변경·추론 호출은 실행하지 않았습니다. 실제 동작은 05단계에서 검증해야 하며 수행 시 Azure 비용이 발생합니다.

[01. 기존 모델 확인과 APIM 준비로 시작](step-01-prepare-resources/README.md)
