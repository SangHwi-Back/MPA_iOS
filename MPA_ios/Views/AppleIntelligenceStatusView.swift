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
        .glassEffect(.regular.interactive())
    }
}

// MARK: - Device Not Supported View
private struct DeviceNotSupportedView: View {
    @Environment(\.showModal) var modalState: ModalState
    
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
        .glassEffect(.regular.interactive())
        .onTapGesture {
            modalState.modalType = .common(.init(
                title: "Apple Intelligence 를 사용할 수 없는 기기에요.",
                message: "이 앱은 애플의 AI 기능인 Foundations Model 을 사용합니다. 이는 Apple Intelligence 를 사용할 수 있는 기기만이 사용할 수 있습니다.\n\n하지만 일기를 작성하는 것은 가능합니다. 다른 기능을 시도해 보세요.",
                onConfirm: nil,
                onCancel: nil))
        }
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
        .glassEffect(.regular.interactive())
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
