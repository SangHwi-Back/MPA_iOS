//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

enum SettingsDestination: Hashable {
    case aiConnection
}

enum SettingsLayout {
    static let gutter: CGFloat = 20
    static let phoneCardRadius: CGFloat = 24
    static let tabletCardRadius: CGFloat = 16
    static let rowHeight: CGFloat = 50
    static let tileSize: CGFloat = 30
    static let tabletSidebarWidth: CGFloat = 381
}

struct SettingsView: View {

    var viewModel: SettingsViewModel
    /// True while a pushed detail screen should hide the phone tab bar.
    @Binding var isDetailPresented: Bool

    @State private var path: [SettingsDestination] = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: SettingsViewModel, isDetailPresented: Binding<Bool> = .constant(false)) {
        self.viewModel = viewModel
        self._isDetailPresented = isDetailPresented
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            tabletLayout
        } else {
            phoneLayout
        }
    }

    private var phoneLayout: some View {
        NavigationStack(path: $path) {
            SettingsListContent(viewModel: viewModel, isRegular: false) {
                path.append(.aiConnection)
            }
            .background(Color.SUNKEN.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .aiConnection:
                    SettingsAIConnectionDetailView(viewModel: viewModel)
                }
            }
        }
        .onChange(of: path) { _, newPath in
            isDetailPresented = !newPath.isEmpty
        }
    }

    private var tabletLayout: some View {
        HStack(spacing: 0) {
            SettingsListContent(viewModel: viewModel, isRegular: true) {}
                .frame(width: SettingsLayout.tabletSidebarWidth)
                .background(Color.SUNKEN.ignoresSafeArea())

            Rectangle()
                .fill(Color.HAIRLINE)
                .frame(width: 1)
                .ignoresSafeArea()

            NavigationStack {
                SettingsAIConnectionDetailView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - List

private struct SettingsListContent: View {

    @Bindable var viewModel: SettingsViewModel
    let isRegular: Bool
    let onOpenAIConnection: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("설정")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .padding(.bottom, isRegular ? 4 : 0)
                    .accessibilityAddTraits(.isHeader)

                aiSection
                privacySection
                recordSection
                helpSection
            }
            .padding(.horizontal, SettingsLayout.gutter)
            .padding(.top, isRegular ? 12 : 36)
            .padding(.bottom, 32)
        }
    }

    private var aiSection: some View {
        SettingsSection(title: "AI", isRegular: isRegular, fill: isRegular ? Color.BRAND_CONTAINER : Color.SURFACE) {
            SettingsRow(
                tile: isRegular ? nil : "settings_tile_ai",
                title: "AI 연결",
                isSelected: isRegular,
                action: onOpenAIConnection
            ) {
                SettingsRowValue(text: connectionValue, color: connectionValueColor)
                SettingsChevron(isSelected: isRegular)
            }
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "개인정보", isRegular: isRegular) {
            SettingsRow(tile: tile("settings_tile_lock"), title: viewModel.biometricLockTitle) {
                Toggle(viewModel.biometricLockTitle, isOn: $viewModel.faceIDLocked)
                    .labelsHidden()
                    .tint(Color.BRAND_PRIMARY)
            }
            SettingsRowDivider(isRegular: isRegular)
            SettingsRow(tile: tile("settings_tile_data"), title: "데이터는 어디에 저장되나요?", action: {}) {
                SettingsChevron()
            }
        }
    }

    private var recordSection: some View {
        SettingsSection(title: "기록", isRegular: isRegular) {
            SettingsRow(tile: tile("settings_tile_reminder"), title: "매일 쓰기 알림", action: {}) {
                SettingsRowValue(text: viewModel.dailyReminderTime)
                SettingsChevron()
            }
            SettingsRowDivider(isRegular: isRegular)
            SettingsRow(tile: tile("settings_tile_export"), title: "기록 내보내기", action: {}) {
                SettingsChevron()
            }
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSection(title: "도움말", isRegular: isRegular) {
                SettingsRow(tile: tile("settings_tile_help"), title: "도움이 필요할 때", action: {}) {
                    SettingsChevron()
                }
                SettingsRowDivider(isRegular: isRegular)
                SettingsRow(tile: tile("settings_tile_about"), title: "앱 정보", action: {}) {
                    SettingsRowValue(text: viewModel.appVersion)
                    if isRegular {
                        SettingsChevron()
                    }
                }
            }

            SettingsFootnote("AI가 만든 조언과 요약은 전문적인 상담이나 의료 조언을 대신하지 않아요.")
                .padding(.top, isRegular ? 12 : 0)
        }
    }

    private func tile(_ name: String) -> String? {
        isRegular ? nil : name
    }

    private var connectionValue: String {
        switch viewModel.aiConnection {
        case .notConnected: return "연결 안 됨"
        case .deviceAI: return "기기 내장 AI"
        case .connected(let connection), .keyError(let connection):
            return "\(connection.provider.displayName) (내 키)"
        }
    }

    private var connectionValueColor: Color {
        if case .notConnected = viewModel.aiConnection { return Color.WARNING_TEXT }
        return Color.TEXT_SECONDARY
    }
}

// MARK: - Reusable sub-views

/// A label above a white rounded group, shared by the list and the AI connection screen.
struct SettingsSection<Content: View>: View {

    var title: String?
    let isRegular: Bool
    var fill: Color = .SURFACE
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: isRegular ? .semibold : .regular))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .padding(.leading, isRegular ? 8 : 16)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(fill, in: .rect(cornerRadius: isRegular ? SettingsLayout.tabletCardRadius : SettingsLayout.phoneCardRadius))
        }
    }
}

struct SettingsRow<Trailing: View>: View {

    var tile: String?
    let title: String
    var isSelected = false
    var titleColor: Color = .TEXT_PRIMARY
    var action: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if let action {
            Button {
                action()
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            if let tile {
                Image(tile)
                    .resizable()
                    .frame(width: SettingsLayout.tileSize, height: SettingsLayout.tileSize)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Color.BRAND_ON_CONTAINER : titleColor)

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: SettingsLayout.rowHeight)
        .contentShape(.rect)
    }
}

/// A text-only tappable row, such as "키 변경" or "연결 해제".
struct SettingsActionRow: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        SettingsRow(title: title, titleColor: color, action: action) {
            EmptyView()
        }
    }
}

struct SettingsRowValue: View {
    let text: String
    var color: Color = .TEXT_SECONDARY

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(color)
    }
}

struct SettingsChevron: View {
    var isSelected = false

    var body: some View {
        Image(isSelected ? "chevron_right" : "disclosure")
            .resizable()
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}

struct SettingsRowDivider: View {
    let isRegular: Bool

    var body: some View {
        Rectangle()
            .fill(Color.HAIRLINE)
            .frame(height: 1)
            .padding(.leading, isRegular ? 0 : 56)
    }
}

struct SettingsFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .lineSpacing(3)
            .foregroundStyle(Color.TEXT_SECONDARY)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#if DEBUG
extension SettingsViewModel {
    static func preview(
        state: AIConnectionState,
        key: String = ""
    ) -> SettingsViewModel {
        let viewModel = SettingsViewModel(
            deviceState: { state },
            biometricLockTitle: "Face ID로 잠금"
        )
        viewModel.apiKeyInput = key
        return viewModel
    }

    static let previewConnection = AIKeyConnection(
        provider: .gemini,
        maskedKey: "AIza••••••3f9",
        lastTestedAt: .now,
        consentGrantedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 30)) ?? .now
    )
}
#endif

private struct SettingsDetailPreview: View {
    let viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            SettingsAIConnectionDetailView(viewModel: viewModel)
        }
    }
}

private let previewKey = "AIzaSyD00000000"

#Preview("settings") {
    SettingsView(viewModel: .preview(state: .deviceAI(hasStandbyKey: false)))
}

#Preview("aiConnectionDetail") {
    SettingsDetailPreview(viewModel: .preview(state: .notConnected(.unsupported), key: previewKey))
}

#Preview("beforeConfirm") {
    SettingsAIConsentSheet(provider: .gemini, onAgree: {}, onCancel: {})
}

#Preview("afterConfirm") {
    SettingsDetailPreview(viewModel: .preview(state: .connected(SettingsViewModel.previewConnection)))
}

#Preview("tablet-settings", traits: .fixedLayout(width: 1194, height: 834)) {
    SettingsView(viewModel: .preview(state: .notConnected(.unsupported)))
        .environment(\.horizontalSizeClass, .regular)
}
