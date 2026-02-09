//
//  AppleIntelligenceStatusView.swift
//  MPA_ios
//
//  Created by Claude on 2/9/26.
//

import SwiftUI
import FoundationModels

struct AppleIntelligenceStatusView: View {
    private let model = SystemLanguageModel.default

    @ViewBuilder
    var body: some View {
        switch model.availability {
        case .available:
            AvailableView()
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible, .modelNotReady:
                DeviceNotSupportedView()
            case .appleIntelligenceNotEnabled:
                NotEnabledView()
            @unknown default:
                DeviceNotSupportedView()
            }
        }
    }
}

// MARK: - Available View
private struct AvailableView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Intelligence")
                    .font(.headline)
                Text("Ready to use")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect()
    }
}

// MARK: - Device Not Supported View
private struct DeviceNotSupportedView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 28))
                .foregroundStyle(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Intelligence")
                    .font(.headline)
                Text("This device does not support Apple Intelligence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect()
    }
}

// MARK: - Not Enabled View
private struct NotEnabledView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Intelligence")
                        .font(.headline)
                    Text("Enable Apple Intelligence to use this feature")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            Button {
                if let url = URL(string: "App-prefs:APPLE_INTELLIGENCE") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect()
    }
}

#Preview("Available") {
    AvailableView()
        .padding()
}

#Preview("Not Supported") {
    DeviceNotSupportedView()
        .padding()
}

#Preview("Not Enabled") {
    NotEnabledView()
        .padding()
}
