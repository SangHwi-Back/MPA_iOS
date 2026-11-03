//
//  SettingsHomeView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

// MARK: - Model

enum AIProvider: String, CaseIterable, Identifiable {
    case gemini
    case openAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .openAI: return "OpenAI"
        }
    }

    var iconSystemName: String {
        switch self {
        case .gemini: return "sparkles"
        case .openAI: return "circle.grid.cross.fill"
        }
    }
}

enum AIConnectionState {
    case notConnected
    case connected(
        provider: AIProvider,
        maskedKey: String,
        lastTestedAt: Date,
        consentGrantedAt: Date?
    )
}

// MARK: - Root

struct SettingsHomeView: View {

    @State private var viewModel = SettingsViewModel()
    @State private var path: [SettingsDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            settingsList
                .navigationDestination(for: SettingsDestination.self) { destination in
                    switch destination {
                    case .aiConnection:
                        AIConnectionDetailView(viewModel: viewModel)
                    }
                }
        }
        .background(Color.CANVAS.ignoresSafeArea())
    }

    // MARK: - List

    private var settingsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                settingsHeader

                // ─── AI ───
                SettingsSection(title: "AI") {
                    SettingsRow(
                        icon: "sparkles",
                        iconBackground: Color.AI_ACCENT.opacity(0.15),
                        iconForeground: Color.AI_ACCENT,
                        title: "AI 연결"
                    ) {
                        HStack(spacing: 4) {
                            Text(connectionSubtitle)
                                .font(.caption)
                                .foregroundStyle(Color.TEXT_SECONDARY)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.TEXT_TERTIARY)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        path.append(.aiConnection)
                    }
                }

                // ─── 개인정보 ───
                SettingsSection(title: "개인정보") {
                    SettingsRow(
                        icon: "lock.shield.fill",
                        iconBackground: Color.BRAND_PRIMARY.opacity(0.12),
                        iconForeground: Color.BRAND_PRIMARY,
                        title: "Face ID로 잠금"
                    ) {
                        Toggle("", isOn: $viewModel.faceIDLocked)
                            .labelsHidden()
                            .tint(Color.BRAND_PRIMARY)
                    }

                    SettingsRow(
                        icon: "globe",
                        iconBackground: Color.SUNKEN,
                        iconForeground: Color.TEXT_SECONDARY,
                        title: "데이터는 어디에 저장되나요?"
                    ) {
                        chevron
                    }
                }

                // ─── 기록 ───
                SettingsSection(title: "기록") {
                    SettingsRow(
                        icon: "bell.fill",
                        iconBackground: Color.WARNING.opacity(0.15),
                        iconForeground: Color.WARNING,
                        title: "매일 쓰기 알람"
                    ) {
                        HStack(spacing: 4) {
                            Text(viewModel.dailyReminderTime)
                                .font(.caption)
                                .foregroundStyle(Color.TEXT_SECONDARY)
                            chevron
                        }
                    }

                    SettingsRow(
                        icon: "square.and.arrow.up",
                        iconBackground: Color.SUNKEN,
                        iconForeground: Color.TEXT_SECONDARY,
                        title: "기록 내보내기"
                    ) {
                        chevron
                    }
                }

                // ─── 도움말 ───
                SettingsSection(title: "도움말") {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconBackground: Color.SUNKEN,
                        iconForeground: Color.TEXT_SECONDARY,
                        title: "도움이 필요할 때"
                    ) {
                        chevron
                    }

                    SettingsRow(
                        icon: "info.circle.fill",
                        iconBackground: Color.SUNKEN,
                        iconForeground: Color.TEXT_SECONDARY,
                        title: "앱 정보"
                    ) {
                        Text(viewModel.appVersion)
                            .font(.caption)
                            .foregroundStyle(Color.TEXT_TERTIARY)
                    }
                }

                // ─── Footer ───
                Text("AI와 분석 요약과 초안은 원칙적인 상점에서 일기로 원칙을 업데이트 합니다. 원치 않으시면 설정에서 끄세요.")
                    .font(.caption2)
                    .foregroundStyle(Color.TEXT_TERTIARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        Text("설정")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(Color.TEXT_PRIMARY)
    }

    private var connectionSubtitle: String {
        switch viewModel.aiConnection {
        case .connected(let provider, _, _, _):
            return "\(provider.displayName) 연결됨"
        case .notConnected:
            return "기기 내경 AI"
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.TEXT_TERTIARY)
    }
}

// MARK: - Reusable sub-views

/// A single row inside a settings section card.
struct SettingsRow<Trailing: View>: View {

    let icon: String
    let iconBackground: Color
    let iconForeground: Color
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconForeground)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.TEXT_PRIMARY)

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.vertical, 6)
    }
}

/// A titled section wrapper with a card background for its content.
struct SettingsSection<Content: View>: View {

    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.TEXT_TERTIARY)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.SURFACE)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            )
        }
    }
}

// MARK: - Navigation destination

enum SettingsDestination: Hashable {
    case aiConnection
}

// MARK: - Preview

#Preview("설정") {
    SettingsHomeView()
}

#Preview("AI 연결 – connected") {
    NavigationStack {
        AIConnectionDetailView(
            viewModel: {
                let vm = SettingsViewModel()
                vm.aiConnection = .connected(
                    provider: .gemini,
                    maskedKey: "A12a••••••••3f9",
                    lastTestedAt: .now,
                    consentGrantedAt: .now
                )
                return vm
            }()
        )
        .navigationTitle("AI 연결")
        .navigationBarTitleDisplayMode(.inline)
    }
    .background(Color.CANVAS)
}

#Preview("AI 연결 – not connected") {
    NavigationStack {
        AIConnectionDetailView(viewModel: SettingsViewModel())
            .navigationTitle("AI 연결")
            .navigationBarTitleDisplayMode(.inline)
    }
    .background(Color.CANVAS)
}
