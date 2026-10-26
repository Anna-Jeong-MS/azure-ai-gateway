# Azure AI Gateway

[English](../README.md) | 한국어

이미 배포된 텍스트·이미지 모델을 연결할 Azure API Management를 Azure Portal에서 신규 생성합니다.

## 구성

| 항목 | 설정 |
| --- | --- |
| APIM SKU | **Standard v2**, 초기 용량 1 |
| 네트워크 | 공용 HTTPS, VNet Injection·Integration·Private Endpoint 미사용 |
| 모델 | 배포 완료된 `gpt-5.5`, `gpt-image-2.5-flare` |
| 텍스트 API | **Language Model API → Create OpenAI API** |
| 이미지 API | **HTTP** 일반 API에 이미지 생성 작업 추가 |
| 백엔드 분산 | 로드 밸런싱: 우선순위 **1 / 1**, 가중치 **100 / 100** |
| 클라이언트 → APIM | 헤더 `Ocp-Apim-Subscription-Key`의 APIM 구독 키 |
| APIM → 모델 | API inbound 정책에서 시스템 할당 Managed Identity 사용 |

텍스트 API가 자동 생성한 백엔드를 Text A로 사용합니다. Text B와 이미지 백엔드 두 개만 추가하여 **자동 1개 + 수동 3개 = 단일 백엔드 총 4개**를 구성합니다.

## 진행 순서

| 단계 | 작업 |
| --- | --- |
| [01. APIM 생성](step-01-prepare-resources/README.md) | 모델 연결 정보 기록, Standard v2 APIM 신규 생성 |
| [02. API 생성](step-02-create-apis/README.md) | APIM 생성 직후 텍스트 Language Model API·이미지 일반 HTTP API 생성 |
| [03. 관리 ID·백엔드 구성](step-03-backend-pools/README.md) | 관리 ID·역할, 백엔드·서킷 브레이커, 풀 생성 |
| [04. 정책 적용](step-04-api-policies/README.md) | 구독 생성, 인증·라우팅, 선택적 제한·재시도 적용 |
| [05. 게이트웨이 테스트](step-05-validation/README.md) | 호출·접근 제어·개별 백엔드·로드 밸런싱 검증 |

## 호출 경로

| API | 클라이언트 호출 경로 |
| --- | --- |
| 텍스트 | `/text/chat/completions?api-version=<text-version>` |
| 이미지 | `/image/deployments/<image-deployment>/images/generations?api-version=<image-version>` |

클라이언트는 모델 계정 키나 관리 ID 토큰이 아닌 APIM 구독 키를 전달합니다. APIM은 키를 검증하고 모델 전달 전에 제거한 뒤 자체 모델 접근 토큰을 얻습니다.

`<...>`는 실제 값으로 바꿉니다. 구독 키·토큰·프롬프트·이미지·비식별 처리하지 않은 Trace는 Git에 올리지 않습니다. 리소스 생성과 모델 호출에는 Azure 비용이 발생합니다.

[01단계 시작](step-01-prepare-resources/README.md)
