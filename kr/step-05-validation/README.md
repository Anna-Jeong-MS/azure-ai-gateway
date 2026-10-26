# 05. 게이트웨이 테스트

[English](../../step-05-validation/README.md) | 한국어

[이전: 정책 적용](../step-04-api-policies/README.md) | [전체 목차](../README.md)

## 5-1. Text API 테스트

1. **APIs → APIs → Text API → Test**를 엽니다.
2. 자동 생성된 **POST `/chat/completions`** 작업을 선택합니다.
3. 1단계의 텍스트 `api-version`을 입력합니다.
4. 포털 기본 all-access 구독 키를 **Text API 범위의 `text-test` 키**로 바꿉니다.
5. 아래 헤더·본문을 입력하고 **Trace**를 선택합니다.

```http
POST /text/chat/completions?api-version=<text-version> HTTP/1.1
Host: <apim-name>.azure-api.net
Ocp-Apim-Subscription-Key: <text-api-subscription-key>
Content-Type: application/json

{
  "messages": [{"role": "user", "content": "Reply with OK only."}],
  "max_completion_tokens": 1024,
  "stream": false
}
```

6. HTTP 200, 응답 `choices`·`usage`를 확인합니다. 표시할 본문이 비어 있으면 `finish_reason`을 확인합니다.
7. **Trace → Inbound / Backend**에서 Managed Identity 인증과 선택된 백엔드를 확인합니다.
8. 최종 모델 URL이 `https://<text-account>.openai.azure.com/openai/deployments/<text-deployment>/chat/completions?api-version=<text-version>`이며 배포 경로가 한 번만 있는지 확인합니다.

## 5-2. Image API 테스트

1. **Image API → Test → Generate image**를 엽니다.
2. 이미지 API 버전, **Image API 범위의 `image-test` 키**, 아래 요청을 입력합니다.
3. **Trace**를 선택합니다.

```http
POST /image/deployments/<image-deployment>/images/generations?api-version=<image-version> HTTP/1.1
Host: <apim-name>.azure-api.net
Ocp-Apim-Subscription-Key: <image-api-subscription-key>
Content-Type: application/json

{
  "prompt": "A simple blue circle on a white background.",
  "n": 1,
  "size": "1024x1024"
}
```

4. HTTP 200과 `data`의 실제 이미지 출력을 확인합니다.
5. 선택된 이미지 백엔드, Managed Identity 인증, 최종 `/openai/deployments/<image-deployment>/images/generations` 경로를 확인합니다.

두 API 모두 클라이언트는 APIM 키만 전달합니다. 해당 키가 모델에 전달되지 않고 APIM이 모델 호출용 Authorization을 설정하는지 확인합니다. 토큰 값은 복사하거나 기록하지 않습니다.

## 5-3. 접근 제어 테스트

| 테스트 | 기대 결과 |
| --- | --- |
| 올바른 API 범위 구독 키 | 모델 응답 성공 |
| APIM 키 누락·오류 | APIM에서 거절, 보통 401, 모델 호출 없음 |
| Text API 범위 키로 Image API 호출 | 거절 |
| 노출하지 않은 작업 경로 | APIM 404 |

실패하면 Trace 구간과 오류 본문을 확인합니다. 게이트웨이 401은 APIM 키·범위, 모델 401/403은 관리 ID·계정 역할·audience, 연결 실패는 공용 접근·계정 접근 규칙을 확인합니다.

## 5-4. 백엔드 네 개 검증

개별 백엔드 테스트에는 선택적 재시도를 넣지 않은 기본 정책을 사용합니다.

1. Text API의 `set-backend-service`를 자동 생성 Text Primary의 실제 ID로 잠시 바꿔 호출합니다.
2. `text-aoai-02`로 바꾸어 호출합니다.
3. `text-pool`로 복구합니다.
4. `image-aoai-01`, `image-aoai-02`도 각각 호출한 뒤 `image-pool`로 복구합니다.
5. 두 유효 정책이 풀을 참조하는지 확인합니다.

## 5-5. 선택적 제한·전환 테스트

- **텍스트 토큰 제한:** 다른 팀용 Text API 범위 구독을 하나 더 만듭니다. 낮은 테스트 한도와 소수의 요청으로 APIM 429·카운터 분리를 확인합니다. 추정을 끈 상태에서는 응답 후 사용량이 반영됩니다.
- **이미지 요청 제한:** 요청 한도를 잠시 낮추고 소수의 호출로 잔여 요청 헤더·APIM 429를 확인한 뒤 승인값으로 복구합니다.
- **전환:** 승인된 격리 환경에서 조직이 제어하는 엔드포인트를 사용합니다. Primary는 429와 `Retry-After: 60`, Secondary는 구분 가능한 성공을 반환하게 합니다. 모델 토큰 정책·자격이 없는 별도 테스트 백엔드·풀·API를 사용하고 전달 전 클라이언트 자격을 제거합니다. 회로 차단 후 후속 요청이 Secondary로 이동하고 복구 시간이 지나면 Primary로 돌아오는지 확인합니다. 운영 모델 쿼터를 소진하지 않습니다.
- **텍스트 재시도:** 활성화했다면 한 요청의 백엔드 호출이 최대 2회인지 확인합니다. 게이트웨이 제한의 429는 백엔드 재시도 테스트가 아닙니다.

제어 가능한 테스트 엔드포인트가 없으면 전환 미실시로 기록합니다. 설정 화면만으로 실제 전환 성공을 판정하지 않습니다.

## 5-6. 모니터링 설정

1. APIM **Application Insights → Add**에서 승인된 Application Insights 리소스를 연결합니다.
2. 각 API **Settings → Diagnostics**에서 로거·샘플링을 설정합니다.
3. 본문·비밀 헤더 수집은 끄고 지연 시간·오류율·429/503 응답을 모니터링합니다.

## 완료 기준

- [ ] 두 API 모두 APIM 구독 키로 호출되고 모델에는 Managed Identity로 인증한다.
- [ ] 개별 백엔드 네 개와 최종 풀 라우팅이 동작한다.
- [ ] 선택적 테스트 결과를 기록하고 제한값·풀 경로·재시도를 승인된 설정으로 복구했다.

## 공식 문서

- [포털 요청 추적](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector)
- [백엔드 풀·서킷 브레이커](https://learn.microsoft.com/en-us/azure/api-management/backends)
- [토큰 제한 동작](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy)
- [Application Insights 연결](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights)
