//
//  AIConnectionDetailView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

struct AIConnectionDetailView: View {

    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch viewModel.aiConnection {
                case .connected:
                    connectedContent
                case .notConnected:
                    notConnectedContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.CANVAS.ignoresSafeArea())
        .navigationTitle("AI 연결")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.TEXT_PRIMARY)
                }
            }
        }
    }

    // MARK: - Connected

    private var connectedContent: some View {
        // Extract values
        let provider: AIProvider
        let maskedKey: String
        let lastTested: Date
        let consentDate: Date?

        if case .connected(let p, let k, let t, let c) = viewModel.aiConnection {
            provider = p; maskedKey = k; lastTested = t; consentDate = c
        } else {
            provider = .gemini; maskedKey = ""; lastTested = .now; consentDate = nil
        }

        return VStack(alignment: .leading, spacing: 28) {

            // ─── 연결 ───
            SettingsSection(title: "연결") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        // Checkmark
                        ZStack {
                            Circle()
                                .fill(Color.BRAND_PRIMARY)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.BRAND_ON_PRIMARY)
                        }

                        Text("\(provider.displayName) API (내 키) 사용")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.TEXT_PRIMARY)
                    }

                    Text("AI 카드에는 \"✦ \(provider.displayName) (내 API 키)\" 로 표시")
                        .font(.caption)
                        .foregroundStyle(Color.TEXT_SECONDARY)

                    Text("연결 테스트 성공 · \(relativeTime(lastTested))")
                        .font(.caption2)
                        .foregroundStyle(Color.BRAND_PRIMARY)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.SURFACE)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                )
            }

            // ─── 연결 정보 ───
            SettingsSection(title: "연결 정보") {
                VStack(spacing: 0) {
                    infoRow(label: "제공자", value: provider.displayName)
                    Divider().background(Color.HAIRLINE).padding(.leading, 16)
                    infoRow(label: "API 키", value: maskedKey)
                    Divider().background(Color.HAIRLINE).padding(.leading, 16)
                    infoRow(
                        label: "외부 전송 동의",
                        value: consentDate.map { formattedDate($0) } ?? "미동의"
                    )

                    // Actions
                    HStack {
                        Button("키 변경") {
                            // TODO: present key editing sheet
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.BRAND_PRIMARY)

                        Spacer()

                        Button("다시 테스트") {
                            viewModel.retestConnection()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.BRAND_PRIMARY)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.SURFACE)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                )
            }

            // ─── 연결 해제 ───
            SettingsSection(title: "연결 해제") {
                Text("연결을 해제하면 기기 내 저장된 키가 제거되고 외부 전송 동의도 함께 해제됩니다. 일기 쓰기는 그대로 사용하실 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(Color.TEXT_TERTIARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                Button {
                    viewModel.disconnect()
                    dismiss()
                } label: {
                    Text("연결 해제")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.DANGER)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.DANGER.opacity(0.3), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedContent: some View {
        @Bindable var vm = viewModel

        return VStack(alignment: .leading, spacing: 28) {

            // ─── 연결 안 됨 ───
            SettingsSection(title: "연결 안 됨") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.WARNING.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.WARNING)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("이 기기는 Apple Intelligence를 지원하지 않아요.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.TEXT_PRIMARY)

                            Text("내 API 키를 연결하면 프로나 효과·원칙을 쓸 수 있어요. 일기 쓰기는 그대로 사용하실 수 있어요.")
                                .font(.caption)
                                .foregroundStyle(Color.TEXT_SECONDARY)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.SURFACE)
                )
            }

            // ─── 내 API 키로 연결 ───
            SettingsSection(title: "내 API 키로 연결") {
                VStack(alignment: .leading, spacing: 14) {

                    // Provider segmented control
                    Picker("제공자", selection: $vm.selectedProvider) {
                        ForEach(AIProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    // API key input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API 키")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.TEXT_SECONDARY)

                        HStack(spacing: 8) {
                            SecureField("••••••••••••••", text: .constant(""))
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.SUNKEN)
                                )

                        }

                        // Paste + link row
                        HStack {
                            Button {
                                // paste from clipboard
                            } label: {
                                Text("붙여넣기")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.BRAND_PRIMARY)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                openProviderGuide(for: vm.selectedProvider)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(vm.selectedProvider.displayName) API 키 발급 방법")
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.BRAND_PRIMARY)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // CTA
                    Button {
                        // In production: POST https://api.mpa-app.com/v1/connect
                        // Never use http:// — always https://
                    } label: {
                        Text("연결 테스트")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.BRAND_ON_PRIMARY)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.BRAND_PRIMARY)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }

            // Footer note
            Text("키는 이 기기의 키체인에 저장되고, 일기와는 서버가 되지 않으므로, 요청은 원할 때만 꺼의 제도에 따라 파동입니다.")
                .font(.caption2)
                .foregroundStyle(Color.TEXT_TERTIARY)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.TEXT_SECONDARY)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: .now)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }

    private func openProviderGuide(for provider: AIProvider) {
        // Always https://
        let url: URL
        switch provider {
        case .gemini:
            url = URL(string: "https://aistudio.google.com/apikey")!
        case .openAI:
            url = URL(string: "https://platform.openai.com/api-keys")!
        }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}
