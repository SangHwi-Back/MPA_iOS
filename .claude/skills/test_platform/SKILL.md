---
name: test_platform
description: Argument 로 전달된 플랫폼의 테스트 코드를 동시에 실행하고 결과를 검토하여 수정방안을 제시한다.
disable-model-invocation: true
argument-hint: <ios | android | all> [-- 추가 지시]
---

# 테스트 코드 실행 후 결과보고

입력: $ARGUMENTS

## 인자

- 인자의 종류는 `ios`, `android`, `all` 이다.
  - 입력은 알파벳만 허용. 모든 입력을 소문자로 바꾼 뒤 인자의 종류 중 하나와 일치하는지 검토한다.
  - 일치하지 않으면 사용법을 알려주고 스킬을 종료한다.
- `--` 뒤의 문장은 인자가 아니라 이번 실행에만 적용할 `추가 지시`이다
  - 위의 인자 규칙은 `--` 앞부분에만 적용한다. `--` 뒤의 단어는 플랫폼, 화면 이름, 모드로 해석하지 않는다
  - 예: `/test_platform all -- UI-Test 만 수행` → ios 와 android 의 테스트 코드 실행, 추가 지시 "Unit-Test 는 제외하고 UI-Test 만 수행"
  - 검증을 서브에이전트에게 맡길 때 추가 지시 중 검증에 관한 내용은 함께 넘긴다

## 프로젝트 설정 (프로젝트에 맞게 수정)

- iOS 프로젝트: `MPA_ios/MPA_ios.xcodeproj`, scheme: `MPA_ios`
  - Unit 테스트 타겟: `MPA_iosTests`
  - UI 테스트 타겟: `MPA_iosUITests`
- Android 프로젝트: `MPA_Android`, 모듈: `:app`
  - Unit 테스트: `app/src/test` → `:app:testDebugUnitTest`
  - UI(계측) 테스트: `app/src/androidTest` → `:app:connectedDebugAndroidTest`
- Android SDK: `~/Library/Android/sdk` (`platform-tools/adb`, `emulator/emulator`)

## 실행 환경 규칙

| 플랫폼 | 테스트 | 1순위 | 없을 때 |
|---|---|---|---|
| iOS | Unit | iPhone 시뮬레이터 | – |
| iOS | UI · iPhone | 연결된 실제 iPhone | iPhone 시뮬레이터 |
| iOS | UI · iPad | 연결된 실제 iPad | iPad 시뮬레이터 |
| Android | Unit | JVM (기기 필요 없음) | – |
| Android | UI · 폰 | 연결된 실제 폰 | 폰 에뮬레이터 |
| Android | UI · 태블릿 | **태블릿 에뮬레이터** (실제 태블릿이 연결돼 있어도 쓰지 않음) | 건너뜀 |

- 시뮬레이터를 고를 때는 iPhone Duo가 아닌 기기 중 최신 런타임을 쓴다
- 실제 기기가 같은 종류로 여러 대면 iPhone Duo가 아닌 기기를 먼저 고르고, 그래도 여러 대면 이름순 첫 번째를 쓴다
- `추가 지시`에 기기 이름이 있으면 그 기기를 우선한다

## 0. 준비

1. Bash로 `git rev-parse --show-toplevel` 을 실행해 프로젝트 루트를 확인한다. 이 스킬의 모든 경로는 이 루트 기준이다
2. 결과 폴더를 만든다: 세션 scratchpad 디렉터리(없으면 `$TMPDIR`) 아래 `test_platform/<yyyyMMdd-HHmmss>/`. 이하 `<OUT>`
3. `추가 지시`를 해석해 실행할 항목(Unit / UI, 기기 종류)을 정한다. 지시가 없으면 위 표의 모든 항목을 실행한다
4. 대상 플랫폼별로 기기를 고른다. 각 항목에 쓸 기기와 그 기기가 실제 기기인지 시뮬레이터·에뮬레이터인지를 기록해 둔다(보고에 쓴다)

### iOS 기기 선택
1. `xcrun devicectl list devices --json-output <OUT>/ios-devices.json` 을 실행한다
2. `result.devices[]` 중 아래를 모두 만족하면 실제 기기 후보다
   - `hardwareProperties.reality == "physical"`
   - `connectionProperties.tunnelState == "connected"`
   - `deviceProperties.developerModeStatus == "enabled"`
   - 종류는 `hardwareProperties.deviceType` (`iPhone` / `iPad`), xcodebuild에 넘길 id는 `hardwareProperties.udid`
3. 연결은 됐지만 개발자 모드가 꺼져 있거나 신뢰되지 않은 기기는 쓰지 않고, 보고의 "그 밖에 알릴 것"에 적는다
4. 실제 기기가 없는 종류는 `xcrun simctl list devices available --json` 에서 시뮬레이터를 고른다

### Android 기기 선택
1. `adb devices -l` 에서 상태가 `device` 인 serial을 모은다 (`unauthorized`, `offline`은 제외하고 보고에 적는다)
2. 각 serial에 대해
   - 실제 기기 여부: `adb -s <serial> shell getprop ro.boot.qemu` 가 `1`이 아니고 serial이 `emulator-`로 시작하지 않으면 실제 기기
   - 폰/태블릿 구분: `wm size`와 `wm density`로 최소 폭 dp = `min(너비, 높이) × 160 / density` 를 구한다. 600 이상이면 태블릿
3. 폰: 실제 폰을 고른다. 없으면 실행 중인 폰 에뮬레이터, 그것도 없으면 아래 방법으로 폰 AVD를 띄운다
4. 태블릿: 실행 중인 태블릿 에뮬레이터를 고른다. 없으면 `emulator -list-avds`의 각 AVD에 대해 `~/.android/avd/<이름>.avd/config.ini`의 `hw.lcd.width`, `hw.lcd.height`, `hw.lcd.density`로 최소 폭 dp를 구해 600 이상인 AVD를 띄운다(예: `Pixel_Fold` ≈ 701dp). 태블릿 AVD가 없으면 태블릿 UI 테스트는 건너뛰고 보고에 적는다
5. AVD 띄우기: `emulator -avd <이름> -no-snapshot-save -no-boot-anim` 를 백그라운드로 실행하고, `adb -s <serial> wait-for-device` 후 `getprop sys.boot_completed` 가 `1`이 될 때까지 기다린다. 이 스킬이 띄운 에뮬레이터는 목록에 적어 두었다가 끝나면 종료한다

### 실제 기기 공통
- 테스트 전 기기 화면이 켜져 있고 잠금이 풀려 있어야 한다. 잠금 때문에 실패하면 재시도하지 말고 사용자에게 잠금 해제를 요청한다
- Android 실제 기기는 `adb -s <serial> shell input keyevent KEYCODE_WAKEUP` 으로 화면만 깨운다. 기기 설정(애니메이션 배율 등)은 바꾸지 않는다

## 1. 실행

- iOS와 Android는 서로 독립이므로 **동시에** 실행한다: 각 플랫폼의 명령 묶음을 하나의 백그라운드 Bash 작업으로 돌리고, 완료 알림을 기다린다(폴링하지 않는다)
- 한 플랫폼 안에서는 아래 순서대로 **차례로** 실행한다. 앞 단계가 실패해도 다음 단계는 계속한다
- 각 명령의 전체 로그는 `<OUT>/<플랫폼>-<단계>.log` 로 남긴다

### iOS
1. Unit 테스트 (시뮬레이터)
   ```bash
   xcodebuild test -project MPA_ios/MPA_ios.xcodeproj -scheme MPA_ios \
     -destination 'platform=iOS Simulator,id=<SIM_UDID>' \
     -only-testing:MPA_iosTests \
     -resultBundlePath <OUT>/ios-unit.xcresult
   ```
2. UI 테스트 (실제 기기). iPhone과 iPad가 모두 실제 기기이면 `-destination`을 두 번 넘겨 한 번에 실행한다
   ```bash
   xcodebuild test -project MPA_ios/MPA_ios.xcodeproj -scheme MPA_ios \
     -destination 'platform=iOS,id=<IPHONE_UDID>' \
     -destination 'platform=iOS,id=<IPAD_UDID>' \
     -only-testing:MPA_iosUITests \
     -allowProvisioningUpdates \
     -resultBundlePath <OUT>/ios-ui-device.xcresult
   ```
3. UI 테스트 (시뮬레이터). 실제 기기가 없던 종류만 `platform=iOS Simulator,id=<SIM_UDID>`로 같은 명령을 실행한다. 결과는 `<OUT>/ios-ui-sim.xcresult`
- 실제 기기 빌드가 서명 오류로 실패하면 그 기기 종류는 시뮬레이터로 다시 실행하고, 서명 오류를 보고에 적는다

### Android (`MPA_Android` 폴더에서)
1. Unit 테스트
   ```bash
   ./gradlew :app:testDebugUnitTest --continue
   ```
   끝나면 `app/build/test-results/testDebugUnitTest/` 를 `<OUT>/android-unit/` 으로 복사한다
2. UI 테스트 · 폰
   ```bash
   ANDROID_SERIAL=<PHONE_SERIAL> ./gradlew :app:connectedDebugAndroidTest --continue
   ```
   끝나면 `app/build/outputs/androidTest-results/connected/` 를 `<OUT>/android-ui-phone/` 으로 복사한다
3. UI 테스트 · 태블릿: 2와 같은 명령을 `ANDROID_SERIAL=<TABLET_SERIAL>`로 실행하고 `<OUT>/android-ui-tablet/` 으로 복사한다
- `ANDROID_SERIAL`을 빼면 연결된 모든 기기에서 실행되므로 반드시 지정한다
- 2와 3은 결과 폴더를 덮어쓰므로 동시에 실행하지 않는다

### 결과 모으기
- iOS: `xcrun xcresulttool get test-results tests --path <xcresult> --compact` (JSON 출력)에서 결과가 `Failed`인 테스트의 이름, 기기, 실패 메시지를 뽑는다
- Android: 복사한 폴더의 `TEST-*.xml` 에서 `<testcase>` 안에 `<failure>` 또는 `<error>`가 있는 항목을 뽑는다
- 빌드 단계에서 실패해 테스트가 하나도 돌지 않은 항목은 로그의 첫 번째 에러를 실패로 기록한다
- 항목마다 전체·성공·실패·건너뜀 수를 센다

### 정리
- 이 스킬이 띄운 에뮬레이터는 `adb -s <serial> emu kill`, 시뮬레이터는 `xcrun simctl shutdown <UDID>` 로 종료한다. 원래 켜져 있던 것은 그대로 둔다
- 결과보고 전에 아래 실행 요약표를 먼저 보여준다

| 플랫폼 | 테스트 | 기기 | 기기 구분 | 전체 | 성공 | 실패 | 건너뜀 |
|---|---|---|---|---|---|---|---|

- 기기 구분은 `실제 기기` / `시뮬레이터` / `에뮬레이터`. 실행하지 못한 항목은 숫자 대신 이유를 적는다

## 2. 결과보고

실패한 테스트만을 아래 순서로 보고한다.

**검증표**

| 번호 | 플랫폼 | 기기 | 상태 | 불일치 내용 | 수정 방안 |
|---|---|---|---|---|---|

- 불일치 내용은 테스트 타겟이 되는 클래스 혹은 뷰 등을 표기한다.
- 수정 방안은 간단할 경우 코드를 적어도 되지만 설명의 형식을 가지고 간단히 적는다

**3) 그 밖에 알릴 것**
- 어떤 번호를 로컬 LLM 을 이용해 고칠지 물어보기

- 검증에서 나온 불일치 수정은 사용자의 확인을 받은 뒤에 시작한다
