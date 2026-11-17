//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsAlertExportJournalsView.swift
//  MPA_ios
//

import SwiftUI
import UIKit

/// "기록을 내보낼까요?" alert. Picking a format writes the file and opens the share sheet.
/// Applied with `.exportJournalsAlert(isPresented:journals:)`.
struct SettingsAlertExportJournalsView: ViewModifier {

    @Binding var isPresented: Bool
    let journals: [Journal]

    @State private var exportedFile: ExportedFile?

    func body(content: Content) -> some View {
        content
            .alert("기록을 내보낼까요?", isPresented: $isPresented) {
                Button("텍스트(.md)로 내보내기") { export(.markdown) }
                    .keyboardShortcut(.defaultAction)
                Button("JSON으로 내보내기") { export(.json) }
                Button("취소", role: .cancel) {}
            } message: {
                Text(Self.message(count: journals.count))
            }
            .sheet(item: $exportedFile) { file in
                ShareSheet(items: [file.url])
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
    }

    static func message(count: Int) -> String {
        "일기 \(count)편의 날짜·제목·본문·키워드를 파일 하나로 만들어 공유해요. 사진은 포함되지 않아요. 내보낸 파일은 앱 잠금으로 보호되지 않으니 보관할 곳을 신중히 골라 주세요."
    }

    private func export(_ format: JournalExportFormat) {
        guard let url = try? JournalExporter.write(journals, format: format) else { return }
        exportedFile = ExportedFile(url: url)
    }
}

extension View {
    func exportJournalsAlert(isPresented: Binding<Bool>, journals: [Journal]) -> some View {
        modifier(SettingsAlertExportJournalsView(isPresented: isPresented, journals: journals))
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("alertExportJournals") {
    Color.SUNKEN
        .ignoresSafeArea()
        .exportJournalsAlert(isPresented: .constant(true), journals: Journal.homeSamples)
}
