---
name: screen
description: specs/<화면 종류>/SCREEN_SPEC.md를 기준으로 iOS·Android 화면을 구현하고, 아이폰·아이패드에서 디자인과 일치하는지 검증한다.
disable-model-invocation: true
argument-hint: <화면 종류> [화면 이름] [build | verify] [ios | android] [-- 추가 지시]
---

# 화면 구현 + 검증

입력: $ARGUMENTS

- 첫 단어는 `화면 종류`이다 (예: Home). 이 단어는 화면의 종류를 뜻한다
- 두 번째 단어부터 `View` 혹은 `Screen` 까지의 단어는 `화면 이름`이다
  - JournalEditorView.swift 의 `화면 종류` 는 Journal 이고 `화면 이름` 은 Editor 이다.
  - JournalEditorScreen.kt 의 `화면 종류` 는 Journal 이고 `화면 이름` 은 Editor 이다.
- 화면을 구현하는 코드 파일 이름은 `<화면 종류><화면 이름>View` 혹은 `<화면 종류><화면 이름>Screen` 이다
- 모드 (생략하면 build 후 verify 둘 다)
  - `build` : 구현만
  - `verify` : 검증만
- `플랫폼 이름` (생략하면 둘 다): `ios`, `android`
- `--` 뒤의 문장은 인자가 아니라 이번 실행에만 적용할 `추가 지시`이다
  - 위의 인자 규칙은 `--` 앞부분에만 적용한다. `--` 뒤의 단어는 화면 이름, 모드, 플랫폼으로 해석하지 않는다
  - 예: `/screen Journal verify ios -- 다크 모드도 확인` → 화면 종류 Journal, 모드 verify, 플랫폼 ios, 추가 지시 "다크 모드도 확인"
  - spec 과 충돌하면 추가 지시를 따르고, 보고할 때 그 사실을 적는다
  - 검증을 서브에이전트에게 맡길 때 추가 지시 중 검증에 관한 내용은 함께 넘긴다

## 프로젝트 설정 (프로젝트에 맞게 수정)

- iOS 화면 폴더: `MPA_ios/MPA_ios/Views/<화면 종류>/`
  - iOS 의 `화면 종류` 폴더 이름은 파스칼 케이스
- Android 화면 폴더: `MPA_Android/app/src/main/java/com/example/mpa_android/ui/view/<화면 종류>/`
  - Android 의 `화면 종류` 폴더 이름은 모두 소문자
- iOS scheme: `MPA_ios`

## 0. 준비

1. Bash로 `git rev-parse --show-toplevel` 을 실행해 프로젝트 루트를 확인한다. 이 스킬의 모든 경로는 이 루트 기준이다
2. `specs/<화면 종류>/SCREEN_SPEC.md` 를 읽는다. 없으면 임의로 판단하여 작업하고 사용자에게 알린다
3. 참고 이미지는 png 형식으로 `specs/<화면 종류>/<플랫폼 이름>/<화면 이름>-<설명>` 으로 저장된다
  - `화면 종류`만 있을 경우 `화면 종류`는 `화면 이름`과 같다
    - 예 : HomeView.swift 는 `specs/home/ios/home.png`, HomeView.kt 는 `specs/home/android/home.png`
    - 예 : JournalEditorView.swift 는 `specs/journal/ios/editor.png`, JournalEditorView.kt 는 `specs/journal/android/editor.png`
  - `설명` 은 해당 화면 내 모달과 같이 상태에 따라 보여질 수 있는 화면에 대한 설명이다
    - `specs/home/ios/home-aiNotAvailableButtonTapped.png` 는 `화면 이름`이 HomeView.swift 면서 화면 내 AI 사용할 수 없음 경고 버튼을 눌렀을 때의 상태를 나타내는 화면이다
  - specs 내 폴더 및 이미지 이름은 CamelCase 이다
4. `specs/DesignSystem/SCREEN_SPEC.md` 은 Card, Chip, Button, Label 등을 만들 때 참고 가능한 파일이다

## 1. 구현 (build)

- 모든 작업 파일 첫 줄에 `// [NO AC] Spec: specs/<화면 종류>/SCREEN_SPEC.md` 주석을 넣는다
  - spec 에 해당되지 않는 파일일 경우엔 `// [NO AC]` 주석을 넣는다
- iOS
  - 빌드한다 (Xcode MCP `BuildProject` 또는 XcodeBuildMCP). 실패하면 고쳐서 다시 빌드하되 최대 3회까지만 시도하고, 그래도 실패하면 멈추고 에러를 보고한다
  - iPhone, iPad `#Preview` 를 만들고 `RenderPreview` 로 1차 확인한다
  - iOS 에서 SwiftUI 로 뷰를 만든 파일들은 모두 View 로 끝나도록 한다.
- Android
  - `gradlew assembleDebug` 로 빌드한다. 실패 시 규칙은 iOS와 같다
  - Android 에서 Jetpack Compose 로 뷰를 만든 파일들은 모두 Screen 으로 끝나도록 한다.
- 모델 파일이 필요할 경우 iOS 와 Android 에 대해 각각의 경로를 참고하고 없다면 임의의 모델 타입을 생성한다.
  - iOS : `MPA_ios/MPA_ios/Model/`
  - Android : `MPA_Android/app/src/main/java/com/example/mpa_android/model/`
- 기준 이미지마다 같은 이름의 #Preview 를 mock 데이터로 만든다
  예: home-emptyJournals.png → #Preview("emptyJournals")
- 검증은 각 Preview를 RenderPreview 로 렌더링해 같은 이름의 이미지와 비교한다

## 2. 검증 (verify)

검증은 구현한 맥락과 분리하기 위해 **서브에이전트에게 맡긴다.**

서브에이전트에게는 아래만 넘긴다.
- 화면 이름, spec 경로, images 경로, 검사할 기기·상태 목록
- `추가 지시` 중 검증에 관한 내용 (있을 때만)
- 구현 과정이나 내가 내린 판단은 넘기지 않는다

서브에이전트 규칙
- 코드를 수정하지 않는다. 읽기, 빌드, 실행, 스크린샷만 한다
- 기준 이미지는 비교할 때 한 장씩만 읽는다

검사 대상

| 플랫폼 | 기기 | 상태 | 기준 이미지 |
|---|---|---|---|
| iOS | iPhone Duo 가 아닌 iPhone 시뮬레이터 | 세로 | `specs/<화면 종류>/ios` 폴더 내 이미지 |
| iOS | iPad 시뮬레이터 | 가로 | `specs/<화면 종류>/tablet` 폴더 내 이미지 |
| Android | 에뮬레이터 | 세로 | `specs/<화면 종류>/android` 폴더 내 이미지 |

- 기준 이미지가 없는 항목은 SCREEN_SPEC.md 기준으로만 판단한다

절차
1. 앱을 빌드·실행하고 해당 화면으로 이동한다 (XcodeBuildMCP)
2. 스크린샷을 찍고 기준 이미지와 비교한다
   - 레이아웃 구조, 간격, 색상, 잘린 요소, 겹침, 상태별 화면
3. Android는 에뮬레이터가 켜져 있으면 `adb exec-out screencap -p > shot.png` 로 캡처해 비교한다. 꺼져 있으면 건너뛰고 표시한다
4. 사용한 시뮬레이터와 에뮬레이터는 끝나면 종료한다

## 3. 보고

아래 형식으로 보고한다.

| 플랫폼 | 기기 | 상태 | 결과 | 불일치 내용 |
|---|---|---|---|---|

- 결과는 `통과`, `불일치`, `수동 확인 필요` 중 하나다
- 불일치는 근거가 된 spec 문장이나 이미지를 함께 적는다
- 구현 중 spec에 없어서 임의로 정한 항목을 따로 나열한다
- 불일치 수정은 사용자의 확인을 받은 뒤에 시작한다
