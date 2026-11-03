//
//  SettingsViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//


import SwiftUI

@Observable final class SettingsViewModel {

    // AI
    var aiConnection: AIConnectionState = .notConnected
    var selectedProvider: AIProvider = .gemini

    // Privacy
    var faceIDLocked: Bool = true

    // Recording
    var dailyReminderEnabled: Bool = true
    var dailyReminderTime: String = "오후 9:30"

    // Help
    var appVersion: String = "1.0.0"

    // MARK: - Actions

    func connectWith(key: String, provider: AIProvider) {
        // In production: POST to https:// (e.g. https://api.mpa-app.com/v1/connect)
        // For now, simulate success:
        let masked = maskAPIKey(key)
        aiConnection = .connected(
            provider: provider,
            maskedKey: masked,
            lastTestedAt: .now,
            consentGrantedAt: .now
        )
        selectedProvider = provider
    }

    func disconnect() {
        aiConnection = .notConnected
    }

    func retestConnection() {
        switch aiConnection {
        case .connected(let p, let k, _, let consent):
            // In production: GET https://…/v1/ping
            aiConnection = .connected(
                provider: p,
                maskedKey: k,
                lastTestedAt: .now,
                consentGrantedAt: consent
            )
        case .notConnected:
            break
        }
    }

    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else { return "••••" }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(3))
        return "\(prefix)••••••••••\(suffix)"
    }
}