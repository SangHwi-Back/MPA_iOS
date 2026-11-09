---
name: screen
description: specs 폴더의 화면별 SCREEN_SPEC.md와 기준 이미지를 바탕으로 iOS·Android 화면을 구현하고, 상태별 Preview를 기준 이미지와 비교해 검증한다.
disable-model-invocation: true
argument-hint: <화면 종류> [화면 이름] [build | verify] [ios | android]
---

# 화면 구현 + 검증

입력: $ARGUMENTS

## 인자 해석

- 첫 단어는 `화면 종류`다 (예: Home, Journal). specs 폴더 이름과 같다
- 그다음 단어 중 `build`, `verify`, `ios`, `android` 가 아닌 단어는 `화면 이름`이다
  - 생략하면 `화면 이름`은 `화면 종류`와 같다 (그 종류의 대표 화면)
- 모드 (생략하면 build 후 verify)
  - `build` : 구현만
  - `verify` : 검증만
- 플랫폼 (생략하면 둘 다): `ios`, `android`

| 입력 | 화면 종류 | 화면 이름 | iOS 파일 | Android 파일 |
|---|---|---|---|---|
| `/screen Home` | Home | Home | `HomeView.swift` | `HomeScreen.kt` |
| `/screen Journal Editor build ios` | Journal | Editor | `JournalEditorView.swift` | — |
| `/screen Settings AiConnectionDetail verify` | Settings | AiConnectionDetail | `SettingsAiConnectionDetailView.swift` | `SettingsAiConnectionDetailScreen.kt` |

- 화면 이름이 화면 종류와 같으면 파일 이름에 한 번만 쓴다 (`HomeHomeView` 가 아니라 `HomeView`)

## 프로젝트 설정

- iOS 화면 폴더: `MPA_ios/MPA_ios/Views/<화면 종류>/` (PascalCase, 예: `Views/Journal/`)
- Android 화면 폴더: `MPA_Android/app/src/main/java/com/example/mpa_android/ui/view/<화면 종류 소문자>/` (예: `ui/view/journal/`)
- iOS 모델: `MPA_ios/MPA_ios/Model/`
- Android 모델: `MPA_Android/app/src/main/java/com/example/mpa_android/model/`
- iOS scheme: `MPA_ios`

## specs 구조

```
specs/
  INDEX.md                      ← 문서 간 우선순위, 공통 규칙
  DesignSystem/SCREEN_SPEC.md   ← 색·타이포·간격 토큰, 컴포넌트, iOS↔Android 매핑
  <화면 종류>/                   ← PascalCase (Home, Journal, …)
    SCREEN_SPEC.md
    ios/<화면 이름>-<상태>.png      ← iPhone 세로, 390×844pt (@2x)
    android/<화면 이름>-<상태>.png  ← 폰 세로, 412×915dp (@2x)
    tablet/<화면 이름>-<상태>.png   ← iPad 가로 전체 화면, 1194×834pt (@2x)
```

- 이미지의 `<화면 이름>` 은 camelCase다. 대표 화면은 화면 종류를 소문자로 시작해 쓴다
  - HomeView → `specs/Home/ios/home-*.png`
  - JournalEditorView → `specs/Journal/ios/editor-*.png`
  - SettingsAiConnectionDetailView → `specs/Settings/ios/aiConnectionDetail-*.png`
- `<상태>` 는 그 화면이 보일 수 있는 상태다 (데이터 상태, 다크 모드, 버튼을 누른 뒤 열린 알림·메뉴 등)
  - `home-aiNotAvailableButtonTapped.png` = 홈에서 AI 경고 버튼을 눌러 알림이 열린 상태
- 상태가 없는 이미지는 `<화면 이름>.png` 이다

## 0. 준비

1. Bash로 `git rev-parse --show-toplevel` 을 실행해 프로젝트 루트를 확인한다. 이 스킬의 모든 경로는 이 루트 기준이다
2. `specs/INDEX.md` 를 읽는다
3. `specs/<화면 종류>/SCREEN_SPEC.md` 를 읽는다
   - 없으면 **멈추고** 찾은 경로와 함께 사용자에게 알린다
   - 문서가 Part로 나뉘어 있으면 front matter의 `parts` 를 보고 `화면 이름` 에 해당하는 Part만 자세히 읽는다
4. 화면에 AI 카드(조언, 요약, 글감, AI 한마디, 원칙 정의)가 있으면 `specs/Home/SCREEN_SPEC.md` Part B도 읽는다
5. 공통 컴포넌트·토큰이 필요하면 `specs/DesignSystem/SCREEN_SPEC.md` 를 읽는다
6. 값이 서로 다르면 INDEX.md의 우선순위를 따른다: DesignSystem > Home Part B > 각 화면 문서
7. Glob으로 `specs/<화면 종류>/{ios,android,tablet}/<화면 이름>*.png` 를 찾아 **상태 목록**을 만든다. 이 단계에서는 이미지를 열지 않는다

## 1. 구현 (build)

### 공통
- 모든 화면 파일 첫 줄에 `// Spec: specs/<화면 종류>/SCREEN_SPEC.md` 주석을 넣는다
- spec 텍스트를 기준으로 만든다. 이미지는 spec으로 알 수 없는 배치를 확인할 때만, 한 장씩 연다
  - 단, tablet 레이아웃은 spec 설명이 적으므로 tablet 이미지를 먼저 보고 만든다
- 색·글꼴·간격은 DesignSystem 토큰을 쓰고, 값을 직접 적지 않는다
- 모델이 필요하면 모델 폴더에서 먼저 찾고, 없을 때만 새로 만든다. 필드 이름은 INDEX.md에 적힌 `Journal.swift` / `Journal.kt` 기준을 따른다
- spec에 없어서 직접 정한 것은 목록으로 남긴다

### 상태별 Preview (검증의 기준이 된다)
- 0-7에서 만든 상태 목록의 **이미지 한 장마다 Preview 하나**를 mock 데이터로 만든다. Preview 이름은 이미지 파일 이름에서 `.png` 를 뺀 것이다
- 화면이 초기 상태를 받을 수 있게 만든다 (예: 알림 표시 여부, 열린 메뉴, 검색어). 버튼을 누른 뒤 상태(`…Tapped`, `…LongTap`, `…Swipe` 등)도 Preview에서 바로 보이게 하기 위해서다
- iOS
  ```swift
  #Preview("home-emptyJournals", traits: .fixedLayout(width: 390, height: 844)) { … }
  #Preview("home-darkMode", traits: .fixedLayout(width: 390, height: 844)) { ….preferredColorScheme(.dark) }
  #Preview("tablet-home-journalExists", traits: .fixedLayout(width: 1194, height: 834)) { … }
  ```
- Android
  ```kotlin
  @Preview(name = "home-emptyJournals", widthDp = 412, heightDp = 915, showBackground = true)
  @Preview(name = "home-darkMode", widthDp = 412, heightDp = 915, uiMode = Configuration.UI_MODE_NIGHT_YES)
  ```
- Preview로 만들 수 없는 상태(시스템 화면 전환, 실제 애니메이션 등)는 목록에 "시뮬레이터 확인"으로 표시한다

### 빌드
- iOS: Xcode MCP `BuildProject` 또는 XcodeBuildMCP로 빌드한다
- Android: `./gradlew assembleDebug` 로 빌드한다
- 실패하면 고쳐서 다시 빌드하되 최대 3회까지만 시도한다. 그래도 실패하면 멈추고 에러를 보고한다
- iOS는 빌드 후 대표 상태 Preview 하나를 `RenderPreview` 로 렌더링해 깨지지 않는지만 확인한다 (비교는 verify에서 한다)

## 2. 검증 (verify)

검증은 구현한 맥락과 분리하기 위해 **서브에이전트에게 맡긴다.**

서브에이전트에게 넘기는 것
- 화면 종류, 화면 이름, 플랫폼
- SCREEN_SPEC.md 경로와 읽을 Part
- 검사 목록: `기준 이미지 경로 ↔ Preview 이름` 짝
- 구현 과정, 내가 정한 것, 어려웠던 점은 넘기지 않는다

서브에이전트 규칙
- 코드를 수정하지 않는다. 읽기, 빌드, Preview 렌더링, 실행, 스크린샷만 한다
- 기준 이미지는 비교할 때 한 장씩만 연다
- 비교 항목: 레이아웃 구조, 요소 순서, 간격, 색상, 글꼴 굵기와 크기 차이, 잘림, 겹침, 문구
- 텍스트 내용(날짜, mock 일기 제목 등)은 mock 데이터 차이이므로 불일치로 보지 않는다

절차
1. iOS: 각 Preview를 `RenderPreview` 로 렌더링해 같은 이름의 기준 이미지와 비교한다
   - `tablet-` 으로 시작하는 Preview는 `tablet/` 폴더 이미지와 비교한다
2. Android: Preview 이미지를 만들 수 있으면(Compose Preview Screenshot Testing 등 설정이 있으면) 그것으로 비교한다
   - 없으면 에뮬레이터가 켜져 있을 때 앱을 실행해 `adb exec-out screencap -p > shot.png` 로 캡처할 수 있는 상태만 비교한다
   - 에뮬레이터가 꺼져 있으면 Android 항목은 "수동 확인 필요"로 둔다
3. "시뮬레이터 확인" 항목만 XcodeBuildMCP로 앱을 실행해 확인한다. 확인할 수 없으면 "수동 확인 필요"로 둔다
4. 기준 이미지가 없는 플랫폼은 SCREEN_SPEC.md 텍스트로만 판단한다
5. 사용한 시뮬레이터와 에뮬레이터는 끝나면 종료한다

## 3. 보고

| 플랫폼 | 기기 | 상태 (Preview 이름) | 결과 | 불일치 내용 |
|---|---|---|---|---|

- 결과는 `통과`, `불일치`, `수동 확인 필요` 중 하나다
- 불일치에는 근거가 된 spec 문장(절 번호)이나 이미지 파일 이름을 함께 적는다
- spec에 없어서 직접 정한 항목을 따로 나열한다
- spec과 기준 이미지가 서로 다르면 따로 나열한다. 어느 쪽을 따를지는 사용자가 정한다
- 불일치 수정은 사용자의 확인을 받은 뒤에 시작한다
