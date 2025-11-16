//
//  ConfirmationModalView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/16/25.
//

import SwiftUI

struct ConfirmationModalView: View {
    let data: ConfirmationData
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var Title: (String) -> Text = { text in
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    func ContentsSection<V: View>(title: String, content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content()
        }
    }
    
    func ActionButton(title: String, _ handler: @escaping () -> Void) -> Button<some View> {
        Button {
            handler()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
        }
    }
    
    var body: some View {
//        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ContentsSection(title: "Title") {
                        Text(data.title)
                            .font(.body)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect()
                            .shadow(radius: 3)
                    }
                    
                    ContentsSection(title: "Date") {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)

                            Text(data.date, style: .date)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(16)
                        .glassEffect()
                        .shadow(radius: 3)
                    }
                    
                    ContentsSection(title: "Content") {
                        Text(data.content)
                            .font(.body)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 150, alignment: .top)
                            .glassEffect(in: .rect(cornerRadius: 12))
                            .shadow(radius: 6)
                    }
                    
                    HStack(spacing: 12) {
                        ActionButton(title: "Cancel", onCancel)
                            .glassEffect(.regular.tint(Color.gray).interactive(), in: Capsule())
                        
                        ActionButton(title: data.isEditMode ? "Update" : "Save", onConfirm)
                            .glassEffect(.regular.tint(Color.blue).interactive(),
                                         in: Capsule())
                    }
                }
                .padding(20)
            }
            .navigationTitle("Confirm Journal")
            .navigationBarTitleDisplayMode(.inline)
//        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ConfirmationModalView(data: .init(title: "", date: .init(), content: "", isEditMode: false)) { } onCancel: { }
}
