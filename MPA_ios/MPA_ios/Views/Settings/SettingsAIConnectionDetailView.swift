//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsAIConnectionDetailView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SafariServices
import SwiftUI

struct SettingsAIConnectionDetailView: View {

    @Bindable var viewModel: SettingsViewModel

    @State private var keyIssuePage: KeyIssuePage?
    @FocusState private var isKeyFieldFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isRegular: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusCard

                if viewModel.showsKeyInput {
                    keyInputSection
                }
                if let connection = viewModel.aiConnection.keyConnection, !viewModel.isEditingKey {
                    connectionInfoSection(connection)
                    disconnectSection
                }
            }
            .frame(maxWidth: isRegular ? 558 : .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isRegular ? 48 : SettingsLayout.gutter)
            .padding(.trailing, isRegular ? 96 : SettingsLayout.gutter)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background((isRegular ? Color.CANVAS : Color.SUNKEN).ignoresSafeArea())
        .navigationTitle("AI 연결")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isConsentPresented, onDismiss: viewModel.cancelConsent) {
            SettingsAIConsentSheet(
                provider: viewModel.selectedProvider,
                onAgree: { Task { await viewModel.agreeToConsent() } },
                onCancel: viewModel.cancelConsent
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $keyIssuePage) { page in
            SafariView(url: page.url)
                .ignoresSafeArea()
        }
        .confirmationDialog(
            "연결을 해제할까요? AI 기능이 꺼지고 일기 앱으로 사용돼요",
            isPresented: $viewModel.isDisconnectConfirmPresented,
            titleVisibility: .visible
        ) {
            Button("연결 해제", role: .destructive, action: viewModel.disconnect)
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - Status card

    @ViewBuilder
    private var statusCard: some View {
        switch viewModel.aiConnection {
        case .notConnected(let reason):
            StatusCard(
                kind: .warning,
                title: "연결 안 됨",
                detail: reason.message,
                caption: "일기 쓰기는 그대로 사용할 수 있어요.",
                isRegular: isRegular
            )
        case .deviceAI(let hasStandbyKey):
            VStack(alignment: .leading, spacing: 20) {
                StatusCard(
                    kind: .success,
                    title: hasStandbyKey ? "기기 내장 AI 사용 중 · 내 키는 대기 중" : "기기 내장 AI 사용 중",
                    detail: "Apple Intelligence로 기기 안에서 분석해요",
                    caption: nil,
                    isRegular: isRegular
                )
                detailCard {
                    SettingsRow(title: "고급: 내 API 키 사용", titleColor: .TEXT_TERTIARY) {
                        EmptyView()
                    }
                }
                .disabled(true)
            }
        case .connected(let connection):
            StatusCard(
                kind: .success,
                title: "\(connection.provider.displayName) API (내 키) 사용 중",
                detail: "AI 카드에는 “✦ \(connection.provider.displayName) (내 API 키)”로 표시돼요.",
                caption: "연결 테스트 성공 · \(relativeTime(connection.lastTestedAt))",
                isRegular: isRegular
            )
        case .keyError:
            StatusCard(
                kind: .warning,
                title: "키를 확인해 주세요",
                detail: "키가 만료되었거나 한도를 초과했을 수 있어요.",
                caption: "일기 쓰기는 그대로 사용할 수 있어요.",
                isRegular: isRegular
            )
        }
    }

    // MARK: - Key input

    private var keyInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "내 API 키로 연결", isRegular: isRegular)

            detailCard {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("제공자", selection: $viewModel.selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.isTesting)

                    keyField

                    Button {
                        keyIssuePage = KeyIssuePage(url: viewModel.selectedProvider.keyIssueURL)
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(viewModel.selectedProvider.displayName) API 키 발급 방법")
                            if !isRegular {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(Color.BRAND_PRIMARY)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -12)

                    if let failure = viewModel.testFailure {
                        Text(failure.message)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.DANGER)
                    }

                    testButton

                    if viewModel.isEditingKey {
                        Button("취소", action: viewModel.cancelKeyChange)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.BRAND_PRIMARY)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }

            SettingsFootnote("키는 이 기기의 키체인에만 저장되고, 개발자 서버를 거치지 않아요. 요금은 입력한 키의 계정에 부과돼요.")
                .padding(.top, 2)
        }
    }

    private var keyField: some View {
        let isEmphasized = isKeyFieldFocused || !viewModel.apiKeyInput.isEmpty

        return VStack(alignment: .leading, spacing: 6) {
            Text("API 키")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.TEXT_SECONDARY)

            HStack(spacing: 8) {
                SecureField(
                    "API 키",
                    text: $viewModel.apiKeyInput,
                    prompt: Text("\(viewModel.selectedProvider.keyPrefix)로 시작하는 키")
                        .foregroundStyle(Color.TEXT_TERTIARY)
                )
                .focused($isKeyFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .privacySensitive()
                .font(.system(size: 16))
                .foregroundStyle(Color.TEXT_PRIMARY)

                Button {
                    if let pasted = UIPasteboard.general.string {
                        viewModel.apiKeyInput = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Text("붙여넣기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.BRAND_ON_CONTAINER)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(isEmphasized ? Color.BRAND_CONTAINER : Color.clear, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .frame(minHeight: 48)
            .background(Color.SUNKEN, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.BRAND_PRIMARY, lineWidth: isEmphasized ? 1.5 : 0)
            }

            if viewModel.hasKeyFormatError {
                Text("키 형식을 확인해 주세요")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.DANGER)
            }
        }
    }

    private var testButton: some View {
        let isEnabled = viewModel.canTestConnection

        return Button {
            isKeyFieldFocused = false
            Task { await viewModel.startConnectionTest() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isTesting {
                    ProgressView()
                        .tint(Color.BRAND_ON_PRIMARY)
                }
                Text(viewModel.isTesting ? "확인 중…" : "연결 테스트")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(isEnabled || viewModel.isTesting ? Color.BRAND_ON_PRIMARY : Color.TEXT_TERTIARY)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isEnabled || viewModel.isTesting ? Color.BRAND_PRIMARY : Color.HAIRLINE, in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Connected

    private func connectionInfoSection(_ connection: AIKeyConnection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "연결 정보", isRegular: isRegular)

            detailCard {
                infoRow(label: "제공자") {
                    SettingsRowValue(text: connection.provider.displayName)
                }
                infoDivider
                infoRow(label: "API 키") {
                    Text(connection.maskedKey)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .lineLimit(1)
                }
                infoDivider
                infoRow(label: "외부 전송 동의") {
                    SettingsRowValue(text: formattedDate(connection.consentGrantedAt))
                }
                infoDivider
                SettingsActionRow(title: "키 변경", color: .BRAND_PRIMARY, action: viewModel.beginKeyChange)
                    .padding(.leading, 2)
                infoDivider
                SettingsRow(title: "다시 테스트", titleColor: .BRAND_PRIMARY, action: {
                    Task { await viewModel.retestConnection() }
                }) {
                    if viewModel.isRetesting {
                        ProgressView()
                    }
                }
                .padding(.leading, 2)
                .disabled(viewModel.isRetesting)
            }

            if let failure = viewModel.testFailure {
                Text(failure.message)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.DANGER)
                    .padding(.leading, 16)
            }
        }
    }

    private var disconnectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailCard {
                SettingsActionRow(title: "연결 해제", color: .DANGER) {
                    viewModel.isDisconnectConfirmPresented = true
                }
                .padding(.leading, 2)
            }
            .padding(.top, 4)

            SettingsFootnote("연결을 해제하면 키가 키체인에서 지워지고 외부 전송 동의도 철회돼요. 일기는 그대로 남아요.")
                .padding(.top, 2)
        }
    }

    private func infoRow<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Spacer(minLength: 12)
            value()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: SettingsLayout.rowHeight)
    }

    private var infoDivider: some View {
        Rectangle()
            .fill(Color.HAIRLINE)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    // MARK: - Helpers

    private func detailCard<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        DetailCard(isRegular: isRegular, content: content)
    }

    private func relativeTime(_ date: Date) -> String {
        guard Date.now.timeIntervalSince(date) >= 60 else { return "방금" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - Sub-views

private struct KeyIssuePage: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct SectionLabel: View {
    let title: String
    let isRegular: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: isRegular ? .bold : .regular))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .padding(.leading, isRegular ? 4 : 16)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct DetailCard<Content: View>: View {
    let isRegular: Bool
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: isRegular ? SettingsLayout.tabletCardRadius : SettingsLayout.phoneCardRadius)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.SURFACE, in: shape)
        .overlay {
            if isRegular {
                shape.stroke(Color.HAIRLINE, lineWidth: 1)
            }
        }
    }
}

private struct StatusCard: View {
    enum Kind {
        case warning, success
    }

    let kind: Kind
    let title: String
    let detail: String
    let caption: String?
    let isRegular: Bool

    var body: some View {
        DetailCard(isRegular: isRegular) {
            Group {
                if isRegular {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: kind == .warning ? "exclamationmark.triangle" : "checkmark.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .accessibilityHidden(true)
                            titleText
                        }
                        .foregroundStyle(kind == .warning ? Color.WARNING_TEXT : Color.BRAND_PRIMARY)
                        bodyText
                    }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        Image(kind == .warning ? "status_disconnected" : "status_connected")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            titleText
                                .foregroundStyle(Color.TEXT_PRIMARY)
                            bodyText
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var titleText: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(detail)
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(Color.TEXT_PRIMARY)
                .fixedSize(horizontal: false, vertical: true)
            if let caption {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
        }
    }
}

// MARK: - Consent sheet

struct SettingsAIConsentSheet: View {
    let provider: AIProvider
    let onAgree: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Image("consent_tile")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)

                Text("일기 내용이 \(provider.companyName) 서버로 전송돼요")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("AI 분석을 위해 일기 내용이 선택한 제공자(\(provider.companyName)) 서버로 전송됩니다. 요금과 데이터 처리는 입력한 키의 계정 정책을 따릅니다.")
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    ConsentRow(isSent: true, text: "가능하면 기기에서 줄인 **요약·키워드**만 보내요")
                    ConsentRow(isSent: true, text: "조언에 꼭 필요할 때만 본문 일부를 보내요")
                    ConsentRow(isSent: false, text: "사진과 사진 캡션은 보내지 않아요")
                    ConsentRow(isSent: false, text: "개발자 서버는 거치지 않아요")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.SURFACE, in: .rect(cornerRadius: 20))
                .padding(.top, 8)

                Text("동의는 설정 › AI 연결의 ‘연결 해제’로 언제든 철회할 수 있어요.")
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 12) {
            VStack(spacing: 8) {
                Button(action: onAgree) {
                    Text("동의하고 연결")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.BRAND_ON_PRIMARY)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.BRAND_PRIMARY, in: .capsule)
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("취소")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.BRAND_PRIMARY)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
        }
        .background(Color.CANVAS.ignoresSafeArea())
    }
}

private struct ConsentRow: View {
    let isSent: Bool
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(isSent ? "consent_send" : "consent_not_send")
                .resizable()
                .frame(width: 20, height: 20)
                .accessibilityLabel(isSent ? "보내는 것" : "보내지 않는 것")

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
