//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsInformationPrivacyDescriptionView.swift
//  MPA_ios
//

import SwiftUI

/// "데이터는 어디에 저장되나요?" — where journals live and where each AI reads them.
/// The large header scrolls away and "데이터 저장 위치" takes its place in the bar.
struct SettingsInformationPrivacyDescriptionView: View {

    let aiConnection: AIConnectionState

    @State private var isHeaderScrolledAway = false

    private var deviceName: String { UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                storageSection
                readersSection
                deletionSection
            }
            .padding(.horizontal, SettingsLayout.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.screen)
        .background(Color.SUNKEN.ignoresSafeArea())
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 56
        } action: { _, isHidden in
            isHeaderScrolledAway = isHidden
        }
        .navigationTitle(isHeaderScrolledAway ? "데이터 저장 위치" : "")
        .navigationBarTitleDisplayMode(.inline)
        // The design shows an opaque bar with a divider, so content is cut off under it instead of blurring.
        .scrollEdgeEffectStyle(.hard, for: .top)
        .toolbarBackground(Color.SUNKEN, for: .navigationBar)
        .toolbarBackgroundVisibility(isHeaderScrolledAway ? .visible : .hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("데이터는 어디에 저장되나요?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.title)
            Text("MPA에는 개발자가 운영하는 서버가 없어요. 일기는 이 \(deviceName) 안에만 저장되고, AI가 일기를 어디에서 읽는지는 연결한 AI에 따라 달라요.")
                .font(.system(size: 16))
                .lineSpacing(6)
                .foregroundStyle(Color.TEXT_PRIMARY)
        }
    }

    private var storageSection: some View {
        PrivacySection(title: "일기와 사진") {
            PrivacyBulletCard(items: [
                "일기·사진·키워드는 이 \(deviceName)의 앱 저장 공간에만 저장돼요. 개발자를 포함해 누구에게도 자동으로 보내지 않아요.",
                "\(deviceName) 백업(iCloud 또는 컴퓨터)을 켜 두었다면 백업에 함께 들어가요.",
                "사진과 사진 캡션은 어떤 AI에도 보내지 않아요.",
            ])
            .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.storage)
        }
    }

    private var readersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PrivacySection(title: "AI가 일기를 읽는 곳") {
                VStack(spacing: 16) {
                    PrivacyReaderCard(
                        name: "Apple Intelligence",
                        chips: [.onDevice] + (isInUse(nil) ? [.inUse] : []),
                        text: "일기를 읽고 조언·요약·원칙을 만드는 일이 모두 이 \(deviceName) 안에서 이루어져요. 일기가 기기 밖으로 나가지 않아요."
                    )
                    .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.reader("onDevice"))
                    ForEach(AIProvider.allCases) { provider in
                        PrivacyReaderCard(
                            name: "\(provider.displayName) (내 API 키)",
                            chips: [.external] + (isInUse(provider) ? [.inUse] : []),
                            text: externalText(provider)
                        )
                        .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.reader(provider.rawValue))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.readers)
            }
            SettingsFootnote("API 키는 이 \(deviceName)의 키체인에만 저장되고, 화면에는 일부만 보여요.")
        }
    }

    private var deletionSection: some View {
        PrivacySection(title: "지우거나 앱을 삭제하면") {
            PrivacyBulletCard(items: [
                "일기를 지우면 실행 취소 시간이 지난 뒤 이 기기에서 완전히 지워져요.",
                "앱을 삭제하면 기기에 있던 일기도 함께 지워져요. 필요하면 먼저 ‘기록 내보내기’로 파일을 저장해 두세요.",
                "이미 Gemini·OpenAI로 보낸 내용은 각 제공자의 정책에 따라 처리돼요.",
            ])
            .accessibilityIdentifier(AccessibilityID.InformationPrivacyDescription.deletion)
        }
    }

    // MARK: - Helpers

    /// `nil` means the on-device AI.
    private func isInUse(_ provider: AIProvider?) -> Bool {
        switch aiConnection {
        case .deviceAI: return provider == nil
        case .connected(let connection), .keyError(let connection): return provider == connection.provider
        case .notConnected: return false
        }
    }

    private func externalText(_ provider: AIProvider) -> String {
        switch provider {
        case .gemini:
            return "가능하면 기기에서 줄인 요약·키워드만, 조언에 꼭 필요할 때는 본문 일부도 Google 서버로 보내요. 보낸 내용의 처리와 보관은 Google의 Gemini API 정책과 내 키 계정 설정을 따라요."
        case .openAI:
            return "가능하면 기기에서 줄인 요약·키워드만, 조언에 꼭 필요할 때는 본문 일부도 OpenAI 서버로 보내요. 보낸 내용의 처리와 보관은 OpenAI API 정책과 내 키 계정 설정을 따라요."
        }
    }
}

// MARK: - Sub-views

private struct PrivacySection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .padding(.leading, 16)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }
}

private struct PrivacyBulletCard: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(Color.TEXT_TERTIARY.opacity(0.6))
                        .frame(width: 5, height: 5)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 4 }
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .foregroundStyle(Color.TEXT_PRIMARY)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.SURFACE, in: .rect(cornerRadius: SettingsLayout.phoneCardRadius))
    }
}

private struct PrivacyReaderCard: View {
    let name: String
    let chips: [PrivacyChip]
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                ForEach(chips, id: \.self) { chip in
                    chip.label
                }
            }
            Text(text)
                .font(.system(size: 15))
                .lineSpacing(5)
                .foregroundStyle(Color.TEXT_PRIMARY)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.SURFACE, in: .rect(cornerRadius: SettingsLayout.phoneCardRadius))
        .accessibilityElement(children: .combine)
    }
}

/// Chip colors follow the design: green = stays on device, brand = in use, warning = leaves the device.
/// There is no green token yet, so the on-device chip uses its own pair.
enum PrivacyChip: Hashable {
    case onDevice
    case inUse
    case external

    var title: String {
        switch self {
        case .onDevice: return "기기 안"
        case .inUse: return "지금 사용 중"
        case .external: return "외부 전송"
        }
    }

    private var colors: (background: Color, foreground: Color) {
        switch self {
        case .onDevice: return (Color(red: 0.87, green: 0.94, blue: 0.87), Color(red: 0.15, green: 0.35, blue: 0.20))
        case .inUse: return (.BRAND_CONTAINER, .BRAND_ON_CONTAINER)
        case .external: return (Color.WARNING.opacity(0.15), .WARNING_TEXT)
        }
    }

    var label: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colors.background, in: .capsule)
    }
}

#Preview {
    NavigationStack {
        SettingsInformationPrivacyDescriptionView(aiConnection: .deviceAI(hasStandbyKey: false))
    }
}
