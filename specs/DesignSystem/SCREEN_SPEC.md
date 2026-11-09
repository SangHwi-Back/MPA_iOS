---
screen: 토큰 · 컴포넌트 · 매핑 (디자인 시스템)
id: system
platforms: [iOS 26 (Liquid Glass), Android (Material 3 Expressive)]
source: "MPA 앱 디자인" 캔버스 › 페이지 "토큰 · 컴포넌트 · 매핑"
artboards: [디자인 토큰 (Light / Dark), 컴포넌트 시트, iOS ↔ Android 매핑표]
code: [MPAColors.swift (extension String), MPAColors.kt (object)]
note: 화면이 아니라 모든 화면이 참조하는 기준값. 공용 디자인 시스템 모듈(예: DesignSystem/) 루트에 둔다. 값이 다른 문서와 충돌하면 이 문서가 우선.
---

# 디자인 시스템 — 토큰 · 컴포넌트 · iOS↔Android 매핑

## 1. 색 토큰 (semantic, iOS/Android 공유)
| 토큰 | 용도 | Light | Dark |
|---|---|---|---|
| bg/canvas | 화면 배경 | #FAF8F5 | #141312 |
| bg/surface | 카드(사용자 글) | #FFFFFF | #1E1C1B |
| bg/sunken | 설정 배경, 목록 단, 입력 필드 | #F3F0EB | #1A1817 |
| bg/container | Android Nav Bar·메뉴·시트 | #F2EEE8 | #262321 |
| border/hairline | 구분선, 카드 외곽선 | #ECE7E0 | #2E2B28 |
| text/primary | 본문·사용자 글 (최고 대비) | #1C1B1A | #F2EFEA |
| text/secondary | 메타·날짜·라벨 (≥ 4.5:1) | #6B6660 | #A39D96 |
| text/tertiary | 16px 이상 글자·장식 숫자만 (3:1) | #8A837B | #7E7871 |
| brand/primary | 주요 버튼, 링크, 선택 | #2E3A6E | #AEB8F0 |
| brand/on-primary | primary 위 글자 | #FFFFFF | #1A2150 |
| brand/container | FAB, 활성 인디케이터, 선택 행 | #DCE0F4 | #2F3864 |
| brand/on-container | container 위 글자·아이콘 | #1E2754 | #DCE0F4 |
| ai/tint | AI 카드 배경 (보조색 약 5%) | #F1EFF9 | #221F2E |
| ai/accent | ✦ 아이콘, AI 섹션 라벨 | #5B4DBA | #B3A8F0 |
| status/warning | AI 경고 버튼 배경 · 경고 글자 | #D97A1E · #B35F0F | #E8973F |
| feedback/danger | 삭제, 연결 해제 | #C4342A | #F0857A |
| highlight/search | 검색 일치 하이라이트 | #F6E2B4 | #5A4A22 |
| scrim | 모달 뒤 딤 | #141312 · 32% | #000000 · 50% |

**아이콘 고정색** (토큰 시트에는 없지만 아이콘 팩에 들어간 값)
- 비선택 아이콘·중립 아이콘: #4A4540
- 탭 바: 선택 #2E3A6E, 비선택 #4A4540

### 1.1 원칙 버블 — 최근성 5단계
- 색은 **최근성 한 가지 의미**만 나타낸다.

| 단계 | Light | Dark |
|---|---|---|
| principle/1 (최근) | #EE937B | #C77562 |
| principle/2 | #F2B48E | #C99472 |
| principle/3 | #E9CF97 | #BBA676 |
| principle/4 | #C9D9A6 | #9BAE80 |
| principle/5 (오래됨) | #A9CBB0 | #82A38A |

- **라벨 글자(principle/on):** Light #2A211C, Dark #141312. 모든 단계에서 대비 ≥ 5:1.
- **단계 계산:** 마지막 등장일 기준 5분위.
- 항상 범례와 접근성 라벨을 함께 쓴다(색만으로 전달 금지).
- Dynamic Color를 써도 바꾸지 않는다.

### 1.2 Dynamic Color (Android)
- 배경화면 색으로 바꾸는 것은 primary와 container 계열**만**이다.
- canvas 톤, ai/*, principle/*, status/warning, feedback/danger, highlight는 의미 색이므로 고정한다.

## 2. 타이포그래피
**폰트**
- 세리프: **Noto Serif KR**. 제목, 사용자 일기 제목, AI 본문에 쓴다.
- 산세리프: 시스템 폰트(SF Pro + Apple SD Gothic Neo / Roboto + Noto Sans KR) 또는 Pretendard 번들.

| 스타일 | 폰트 / 굵기 | 크기 / 줄간격 | 용도 |
|---|---|---|---|
| Display | serif 600 | 32 / 1.3 | 인사, 온보딩 (온보딩 제목은 27) |
| Title | serif 600 | 28 (탭 제목 30) / 1.35 | 일기 제목 |
| Title S | serif 600 | 22 | 시트·다이얼로그 제목 |
| AI Body | serif 500 | 17–18 / 1.65 | 조언·요약 |
| Headline | sans 700 | 17 | 섹션 제목, 리스트 제목 |
| Body | sans 400 | 17 / 1.75 (본문) · 1.5 (미리보기) | 일기 본문 |
| Callout | sans 400 | 15 | 버튼, 설정 행 |
| Caption | sans 400 | 13 | 메타 정보 |
| Micro | sans 400 | 11.5 | AI 출처 라벨 전용 |

**글꼴 크기 확대 (Dynamic Type / 시스템 글꼴 크기 200%까지)**
- 레이아웃은 1열을 유지한다.
- 버블 라벨은 최대 22까지만 커진다. 넘치면 버블 지름을 키운다.

## 3. 간격 · 모서리 · 높이
- **간격 스케일:** 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48. 화면 좌우 여백은 20.
- **모서리**
  - 칩: 999(iOS), 8(Android)
  - 썸네일: 12
  - 카드: 20
  - 시트: 28(iOS 36)
  - 메뉴: iOS 22, Android 16
- **높이(그림자)**
  - 콘텐츠 카드에는 그림자가 없다. 배경 톤과 외곽선으로 구분한다.
  - 그림자는 떠 있는 요소에만 쓴다.
    - level 1: 탭 바, Glass 버튼
    - level 2: FAB, 메뉴
    - level 3: 시트, 다이얼로그
  - 다크 모드 Android는 그림자 대신 surfaceContainer 단계로 높이를 표현한다. FAB만 그림자를 유지한다.
- **터치 영역:** 최소 44pt / 48dp. 이보다 작은 칩은 히트 영역을 키운다.
- **콘텐츠 최대 폭:** 640 (Medium 이상).
- **기준 폭:** iOS Compact 390pt, Android Compact 412dp.

## 4. 컴포넌트

### 4.1 일기 리스트 아이템
**구성**
- 날짜 블록: 폭 40. 일 숫자는 serif 24/600, 요일은 Caption.
- 제목: 16/700. 없으면 본문 첫 줄.
- 본문: 2줄, 14.
- 키워드 칩: 최대 2개.
- 썸네일: 60. 사진이 있을 때만, 여러 장이면 "+N" 배지.

**여백:** 좌우 20, 위아래 14. 구분선은 hairline.

**변형**
- 기본
- 검색: 하이라이트, 요일 대신 월
- 2단 목록: 1줄 미리보기, 칩과 썸네일 생략
- 선택됨

### 4.2 칩
| 종류 | 모양 | 쓰는 곳 |
|---|---|---|
| 키워드 칩 (표시용) | ai/tint 바탕 + 원칙 색 점. iOS 캡슐 / Android Assist chip radius 8 | 리스트(최대 2), 상세(최대 5) |
| 키워드 칩 (편집용) | 이름 + ✕. "+ 추가" 칩. Android Input chip | 에디터 |
| 출처 칩 | **흰** 바탕. 사용자 일기로 가는 링크 | AI 조언, 주간 요약 |

### 4.3 날짜 블록 · 사진 썸네일
- **날짜 블록:** 검색 결과에서는 요일 대신 "10월"을 쓴다.
- **썸네일:** 정사각 크롭, radius 12.
  - 에디터: 88pt / 96dp. 삭제 ✕는 24pt / 28dp.
  - 리스트: 60. 여러 장이면 +N.
  - 추가 타일: 점선.
  - 자리표시: #DCD5C9 바탕 + 그림 아이콘 #8A837B (MPA-ImagePlaceholder).

### 4.4 원칙 버블 · 범례
- **지름:** 면적이 중요도에 비례한다. `d = d_min · √(w / w_min)`.
  - d_min: Compact 64, Expanded 74. d_max: 136.
- **색:** principle/1–5.
- **라벨:** 2–4글자, 한 줄, 15–20/700.
- **물리:** 중심으로 끌어당기는 스프링, 버블 사이 겹침 간격 2pt. 동작 줄이기가 켜져 있으면 정적 원형 배치.
- **범례:** "최근 ●●●●● 오래됨 · 크기 = 등장 빈도". 항상 버블 아래에 둔다.

### 4.5 버블 메뉴
- 헤더(이름 + "N개의 일기에서 발견") 아래에 항목을 최대 3개 둔다. 항목을 탭하면 일기 상세로 간다.
- **iOS:** contextMenu / Menu. 탭으로 열린다. 버블이 1.08배 커지고 배경이 블러된다. radius 22.
- **Android:** 버블에 앵커된 DropdownMenu. 딤이 없고 포커스 링을 그린다. radius 16, 행 56dp.

### 4.6 AI 경고 버튼 · 오류 알럿
- **버튼:** status/warning 원형, iOS 44 / Android 40. 아이콘만 있고 라벨은 "AI 기능을 사용할 수 없음".
  - 기기 AI와 키가 모두 불가일 때만 보여 준다. 해결되면 축소 + 페이드로 사라진다.
- **알럿:** iOS Alert / Android AlertDialog(아이콘 슬롯, 텍스트 버튼).
  - 원인 3종: 미지원, 꺼짐, 다운로드 중.

### 4.7 버튼
| 종류 | 스타일 | 규칙 |
|---|---|---|
| Primary | brand/primary 캡슐. 높이 44(iOS) / 48(Android, 리스트 밖에서는 40–48) | 화면당 1개 |
| Tonal | brand/container | Android FAB, 강조 보조 버튼 |
| Outlined · Text | 외곽선 / 텍스트 | 보조 동작 |
| Destructive | feedback/danger | 확인 단계와 함께 쓴다 |

### 4.8 토스트 · Snackbar
- **iOS:** 커스텀 캡슐. 탭 바 위 16, 5초.
- **Android:** M3 Snackbar, radius 8. Nav Bar 위 16, Short(4초). FAB를 밀어 올린다.
- 스크린리더가 켜져 있으면 유지 시간을 늘린다.

### 4.9 빈 상태 일러스트 (4종)
- 종류: 첫 일기, 기록 없음, 기기 안에서, 원칙 준비 중.
- 스타일: 라인 드로잉 1색(text/tertiary, 다크 #A39D96) + 원칙 색 포인트 1–3개. 선 굵기 1.6(원본 크기 기준).
- 장식이므로 접근성 트리에서 숨긴다. 의미는 아래 문구가 전달한다.

### 4.10 AI 카드
- 모든 상태 → ../Home (Part B)

## 5. 아이콘 매핑 (SF Symbols ↔ Material Symbols Rounded)
- Material은 Rounded, weight 400, fill 0을 쓴다. 선택 상태에만 fill 1.

| 의미 | iOS | Android |
|---|---|---|
| 새 일기 쓰기 | square.and.pencil | edit |
| 추가 (+) | plus | add |
| 탭 · 오늘 | sun.max | light_mode |
| 탭 · 기록 | book.closed | book |
| 탭 · 원칙 | bubbles.and.sparkles | bubble_chart |
| 탭 · 설정 | gearshape | settings |
| AI 표식 ✦ | sparkle | auto_awesome |
| AI 경고 | exclamationmark.triangle.fill | warning |
| 검색 | magnifyingglass | search |
| 캘린더 | calendar | calendar_month |
| 사진 추가 | photo.badge.plus | add_photo_alternate |
| 받아쓰기 | mic | mic |
| 다시 생성 | arrow.clockwise | refresh |
| 도움됨 / 안 됨 | hand.thumbsup · hand.thumbsdown | thumb_up · thumb_down |
| 고정 | pin / pin.fill | push_pin |
| 더보기 | ellipsis (가로) | more_vert (세로) |
| 삭제 | trash | delete |
| 닫기 · 완료 | xmark · checkmark | close · check |
| 뒤로 | chevron.left | arrow_back |
| 펼치기 / 접기 | chevron.down · chevron.up | expand_more · expand_less |
| 잠금 · 생체 인증 | lock · faceid | lock · fingerprint |
| 알림 | bell | notifications |
| 내보내기 · 공유 | square.and.arrow.up | share |
| 외부 전송 | icloud.and.arrow.up | cloud_upload |
| 붙여넣기 · 보기 | doc.on.clipboard · eye | content_paste · visibility |
| 도움이 필요할 때 | heart.text.square | volunteer_activism |
| AI 패널 · 사이드바 | sidebar.right · sidebar.left | right_panel_open · left_panel_open |

**색이 들어간 아이콘 팩** (디자인 색이 그대로 들어 있다)
- MPA-TabIcons, MPA-HomeIcons, MPA-AlertIcons, MPA-ImagePlaceholder, MPA-JournalIcons, MPA-SettingsIcons, MPA-EditorIcons.
- **Android:** `tint = Color.Unspecified`로 써야 색이 유지된다.
- **iOS:** asset의 렌더링 모드를 Original로 둔다.

## 6. 컴포넌트 · 패턴 매핑
| 역할 | iOS (26+, Liquid Glass) | Android (M3 Expressive) |
|---|---|---|
| 주 내비게이션 | 하단 떠 있는 탭 바 · Medium 이상은 상단 탭 바 / 사이드바 | Navigation Bar · Medium 이상은 Navigation Rail |
| 새 일기 | 내비게이션 바 (+) Glass 버튼 → large 시트 | Extended FAB(스크롤 시 축소) → 전체 화면(컨테이너 트랜스폼) |
| 홈 제목 | Large Title (날짜 위, 인사 아래) | Large Top App Bar (인사 + subtitle 날짜) |
| 뒤로 | Glass 원형 ‹ + 엣지 스와이프 | ← IconButton + Predictive Back |
| 버블 메뉴 | contextMenu / Menu, 확대 + 배경 블러 | 앵커 DropdownMenu, 딤 없음, 포커스 링 |
| 오류 알럿 | Alert, 캡슐 버튼 2개, 바깥 탭 무시 | AlertDialog + 아이콘, 텍스트 버튼 우측 정렬, 스크림 탭 = 닫기 |
| 시트 | .sheet detents(medium/large), 떠 있는 Glass, ✕ 버튼 | ModalBottomSheet, 가장자리 부착, 드래그 핸들 |
| 검색 | .searchable(내비게이션 바) + 취소 | SearchBar → 전체 화면 SearchView |
| 보기 전환 · 제공자 선택 | Segmented Picker | SegmentedButton (선택 시 체크) |
| 날짜 선택 | DatePicker(.graphical) 팝오버, 즉시 반영 | DatePickerDialog, 확인을 눌러야 반영 |
| 칩 | 캡슐 (radius 999) | Assist / Input chip (radius 8) |
| 스위치 | Toggle (brand tint) | Switch (켜짐 썸에 체크) |
| 목록 행 액션 | swipeActions + 길게 누르기 contextMenu | SwipeToDismissBox(삭제) + 행 ⋮ DropdownMenu |
| 실행 취소 알림 | 커스텀 캡슐 토스트 (5초) | Snackbar Short (4초) |
| 설정 목록 | inset grouped List | 섹션 헤더 + 2줄 ListItem |
| 2단 · 보조 패인 | NavigationSplitView · inspector | ListDetailPaneScaffold · SupportingPaneScaffold |
| 기기 AI | Apple Intelligence · Foundation Models | Gemini Nano (ML Kit GenAI / AICore) |
| AI 출처 라벨 | ✦ Apple Intelligence로 기기에서 생성됨 | ✦ 기기 내 AI로 생성됨 |
| API 키 저장 | Keychain | Android Keystore |
| 생체 잠금 | LocalAuthentication (Face ID / 암호) | BiometricPrompt (+ DEVICE_CREDENTIAL) · FLAG_SECURE |
| 햅틱 | 버블 탭·저장: UIImpactFeedback .light | HapticFeedbackConstants.CONFIRM / CONTEXT_CLICK |
| 색 | 고정 브랜드 팔레트 | 브랜드 팔레트 + Dynamic Color 옵션 (의미 색은 고정) |
| 전환 | zoom transition (리스트 → 상세) | shared element transition |
