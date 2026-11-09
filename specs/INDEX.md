# MPA 화면 명세 색인

- 출처: "MPA 앱 디자인" 캔버스 (Design 아티팩트).
- 폴더마다 `SCREEN_SPEC.md` 하나씩 있다. 화면을 구현하는 에이전트는 **해당 폴더의 SCREEN_SPEC.md만** 읽으면 된다.
- 공통 기준값이 필요하면 `DesignSystem/`을 추가로 읽는다.
- 여러 페이지를 합친 문서는 Part A/B/C로 나뉘어 있다. 맨 앞 YAML front matter의 `parts`에 각 Part가 무엇인지 적혀 있다.
- "폴더블 펼침" 페이지는 제외했다.

| 폴더 | 캔버스 페이지 | 내용 |
|---|---|---|
| Home/ | 홈 + AI 상태 · 다크 모드 | A: 오늘 탭(AI 조언, 글감, 원칙 버블, 주간 요약, 일기 앱 모드, 첫 실행, AI 경고) · B: 공통 AI 카드 상태 머신, 엔진 라벨, 다크 모드 규칙 |
| Journal/ | 기록 + 일기 상세 + 일기 에디터 | A: 리스트·캘린더·검색·스와이프 삭제·빈 상태 · B: 읽기 모드·키워드 시트·AI 한마디 · C: 새 일기·작성 후·날짜 선택 |
| Principle/ | 원칙 | 원칙 목록·지나간 원칙, 원칙 상세(정의, 추이 차트) |
| Settings/ | 설정 · AI 연결 | 설정 목록, API 키 연결, 외부 전송 동의, 연결됨 |
| Onboarding/ | 온보딩 · 앱 잠금 | 온보딩 3장, 생체 인증 잠금 화면 |
| DesignSystem/ | 토큰 · 컴포넌트 · 매핑 | 색·타이포·간격 토큰, 컴포넌트, iOS↔Android 매핑 |

- **AI 카드 상태 규칙**(생성 중, 실패, 오프라인, 키 오류, 민감 내용, 엔진 라벨)은 `Home/` Part B에 있다. Journal(AI 한마디)과 Principle(원칙 정의)도 이 규칙을 따른다.
- **값이 서로 다를 때 우선순위:** DesignSystem > Home Part B > 각 화면 문서.
- **데이터 모델 필드명**은 `Journal.swift` / `Journal.kt` 기준이다. 예: `displayTitle`, `previewText`, `visibleKeywords`, `analysisState`, `aiComment`, `AIEngine.sourceLabel`.
