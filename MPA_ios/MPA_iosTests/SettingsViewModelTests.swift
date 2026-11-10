//
//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsViewModelTests.swift
//  MPA_iosTests
//

import XCTest
@testable import MPA_ios

private final class FakeKeyTester: AIKeyTesting, @unchecked Sendable {
    var result: AIKeyTestFailure?

    func test(key: String, provider: AIProvider) async -> AIKeyTestFailure? {
        result
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private let geminiKey = "AIzaSyABCDEFG3f9"
    private let deviceDefault = AIConnectionState.notConnected(.unsupported)
    private var tester: FakeKeyTester!
    private var sut: SettingsViewModel!

    override func setUp() async throws {
        tester = FakeKeyTester()
        let deviceDefault = self.deviceDefault
        sut = SettingsViewModel(
            keyTester: tester,
            deviceState: { deviceDefault },
            biometricLockTitle: "Face ID로 잠금",
            now: { Date(timeIntervalSince1970: 1_000) }
        )
    }

    private func connect() async {
        sut.apiKeyInput = geminiKey
        await sut.startConnectionTest()
        await sut.agreeToConsent()
    }

    func testMaskedKeyKeepsFourPrefixAndThreeSuffix() {
        XCTAssertEqual(SettingsViewModel.maskedKey(geminiKey), "AIza••••••3f9")
    }

    func testKeyFormatValidation() {
        sut.apiKeyInput = "sk-abc"
        XCTAssertTrue(sut.hasKeyFormatError)
        XCTAssertFalse(sut.canTestConnection)

        sut.apiKeyInput = "  AIza123456  "
        XCTAssertEqual(sut.trimmedKey, "AIza123456")
        XCTAssertTrue(sut.canTestConnection)

        sut.apiKeyInput = ""
        XCTAssertFalse(sut.hasKeyFormatError)
        XCTAssertFalse(sut.canTestConnection)
    }

    func testFirstConnectionAsksForConsent() async {
        sut.apiKeyInput = geminiKey
        await sut.startConnectionTest()

        XCTAssertTrue(sut.isConsentPresented)
        XCTAssertEqual(sut.aiConnection, deviceDefault)
    }

    func testCancelConsentKeepsDiaryMode() async {
        sut.apiKeyInput = geminiKey
        await sut.startConnectionTest()
        sut.cancelConsent()

        XCTAssertFalse(sut.isConsentPresented)
        XCTAssertNil(sut.consent)
        XCTAssertEqual(sut.aiConnection, deviceDefault)
    }

    func testAgreeConnectsAndClearsInput() async {
        await connect()

        XCTAssertEqual(sut.aiConnection.keyConnection?.maskedKey, "AIza••••••3f9")
        XCTAssertEqual(sut.aiConnection.keyConnection?.provider, .gemini)
        XCTAssertEqual(sut.apiKeyInput, "")
        XCTAssertFalse(sut.isConsentPresented)
    }

    func testFailedFirstTestStaysNotConnected() async {
        tester.result = .invalidKey
        await connect()

        XCTAssertEqual(sut.testFailure, .invalidKey)
        XCTAssertEqual(sut.aiConnection, deviceDefault)
    }

    func testKeyChangeWithSameProviderSkipsConsent() async {
        await connect()
        sut.beginKeyChange()
        sut.apiKeyInput = "AIzaNewKey000999"
        await sut.startConnectionTest()

        XCTAssertFalse(sut.isConsentPresented)
        XCTAssertEqual(sut.aiConnection.keyConnection?.maskedKey, "AIza••••••999")
        XCTAssertFalse(sut.isEditingKey)
    }

    func testChangingProviderClearsKeyAndRequiresConsent() async {
        await connect()
        sut.beginKeyChange()
        sut.apiKeyInput = geminiKey
        sut.selectedProvider = .openAI
        XCTAssertEqual(sut.apiKeyInput, "")

        sut.apiKeyInput = "sk-abcdefghij"
        await sut.startConnectionTest()
        XCTAssertTrue(sut.isConsentPresented)
    }

    func testRetestQuotaFailureBecomesKeyError() async {
        await connect()
        tester.result = .quotaExceeded
        await sut.retestConnection()

        guard case .keyError = sut.aiConnection else {
            return XCTFail("Expected keyError, got \(sut.aiConnection)")
        }
    }

    func testRetestOfflineKeepsConnection() async {
        await connect()
        tester.result = .offline
        await sut.retestConnection()

        guard case .connected = sut.aiConnection else {
            return XCTFail("Expected connected, got \(sut.aiConnection)")
        }
        XCTAssertEqual(sut.testFailure, .offline)
    }

    func testDisconnectClearsConsentAndRestoresDeviceState() async {
        await connect()
        sut.disconnect()

        XCTAssertNil(sut.consent)
        XCTAssertEqual(sut.aiConnection, deviceDefault)
    }
}
