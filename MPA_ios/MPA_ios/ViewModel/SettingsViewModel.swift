//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI
import FoundationModels
import LocalAuthentication

@MainActor
@Observable
final class SettingsViewModel {

    // AI
    var aiConnection: AIConnectionState
    var selectedProvider: AIProvider = .gemini {
        didSet {
            guard selectedProvider != oldValue else { return }
            apiKeyInput = ""
        }
    }
    var apiKeyInput: String = "" {
        didSet { testFailure = nil }
    }
    var isEditingKey = false
    var isConsentPresented = false
    var isDisconnectConfirmPresented = false
    private(set) var isTesting = false
    private(set) var isRetesting = false
    private(set) var testFailure: AIKeyTestFailure?
    private(set) var consent: AIConsentRecord?

    // Privacy
    var faceIDLocked = true
    var biometricLockTitle: String

    // Recording
    var dailyReminderTime = "오후 9:30"

    // Help
    var appVersion = "1.0.0"

    private let keyTester: any AIKeyTesting
    private let deviceState: () -> AIConnectionState
    private let now: () -> Date
    /// Held in memory only until Keychain storage is added.
    private var connectedKey: String?

    init(
        keyTester: any AIKeyTesting = StubAIKeyTester(),
        deviceState: @escaping () -> AIConnectionState = SettingsViewModel.currentDeviceState,
        biometricLockTitle: String = SettingsViewModel.currentBiometricLockTitle(),
        now: @escaping () -> Date = Date.init
    ) {
        self.keyTester = keyTester
        self.deviceState = deviceState
        self.biometricLockTitle = biometricLockTitle
        self.now = now
        self.aiConnection = deviceState()
    }

    // MARK: - Key input

    var trimmedKey: String {
        apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasKeyFormatError: Bool {
        !trimmedKey.isEmpty && !trimmedKey.hasPrefix(selectedProvider.keyPrefix)
    }

    var canTestConnection: Bool {
        !trimmedKey.isEmpty && !hasKeyFormatError && !isTesting
    }

    var showsKeyInput: Bool {
        switch aiConnection {
        case .notConnected: return true
        case .connected, .keyError: return isEditingKey
        case .deviceAI: return false
        }
    }

    // MARK: - Connection

    /// Asks for consent first unless it was already given for the selected provider.
    func startConnectionTest() async {
        guard canTestConnection else { return }
        if consent?.provider == selectedProvider {
            await runKeyTest()
        } else {
            isConsentPresented = true
        }
    }

    func agreeToConsent() async {
        consent = AIConsentRecord(provider: selectedProvider, grantedAt: now())
        isConsentPresented = false
        await runKeyTest()
    }

    func cancelConsent() {
        isConsentPresented = false
    }

    func beginKeyChange() {
        if let provider = aiConnection.keyConnection?.provider {
            selectedProvider = provider
        }
        apiKeyInput = ""
        isEditingKey = true
    }

    func cancelKeyChange() {
        apiKeyInput = ""
        isEditingKey = false
    }

    func retestConnection() async {
        guard let connection = aiConnection.keyConnection, let key = connectedKey, !isRetesting else { return }
        isRetesting = true
        defer { isRetesting = false }
        testFailure = nil

        switch await keyTester.test(key: key, provider: connection.provider) {
        case nil:
            var updated = connection
            updated.lastTestedAt = now()
            aiConnection = .connected(updated)
        case .offline:
            testFailure = .offline
        case .invalidKey, .quotaExceeded:
            aiConnection = .keyError(connection)
        }
    }

    func disconnect() {
        connectedKey = nil
        consent = nil
        apiKeyInput = ""
        isEditingKey = false
        testFailure = nil
        aiConnection = deviceState()
    }

    private func runKeyTest() async {
        let key = trimmedKey
        let provider = selectedProvider
        guard let grantedAt = consent?.grantedAt else { return }

        isTesting = true
        testFailure = nil
        let failure = await keyTester.test(key: key, provider: provider)
        isTesting = false

        if let failure {
            testFailure = failure
            return
        }
        connectedKey = key
        aiConnection = .connected(AIKeyConnection(
            provider: provider,
            maskedKey: Self.maskedKey(key),
            lastTestedAt: now(),
            consentGrantedAt: grantedAt
        ))
        apiKeyInput = ""
        isEditingKey = false
    }

    // MARK: - Helpers

    static func maskedKey(_ key: String) -> String {
        guard key.count > 7 else { return "••••••" }
        return "\(key.prefix(4))••••••\(key.suffix(3))"
    }

    nonisolated static func currentDeviceState() -> AIConnectionState {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .deviceAI(hasStandbyKey: false)
        case .unavailable(.deviceNotEligible):
            return .notConnected(.unsupported)
        case .unavailable(.appleIntelligenceNotEnabled):
            return .notConnected(.turnedOff)
        case .unavailable(.modelNotReady):
            return .notConnected(.downloading)
        case .unavailable:
            return .notConnected(.unsupported)
        }
    }

    nonisolated static func currentBiometricLockTitle() -> String {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return "기기 암호로 잠금"
        }
        return context.biometryType == .touchID ? "Touch ID로 잠금" : "Face ID로 잠금"
    }
}
