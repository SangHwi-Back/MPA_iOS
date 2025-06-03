//
//  ContentView.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Product]
    
    private func contentDateText(_ date: Date?) -> Text {
        if let date {
            Text("Item at \(date, format: Date.FormatStyle(date: .numeric, time: .standard))")
        } else {
            Text("No Date")
        }
    }
    
    private var contentViewContents: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    contentDateText(item.date)
                } label: {
                    contentDateText(item.date)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .addEditAndAddToolBar(addItem)
    }
    
    // MARK: - BODY
    var body: some View {
        NavigationSplitView {
            contentViewContents
        } detail: {
            Text("")
        }
    }
}

private extension ContentView {
    private func addItem() {
        withAnimation {
            let newItem = Product(
                id: items.count + 1,
                name: "New Item",
                desc: "",
                price: 0,
                stock: 0,
                images: [],
                createdAt: ISO8601DateFormatter.common.string(from: Date()),
                updatedAt: nil)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

private extension View {
    func addEditAndAddToolBar(_ addItem: @escaping () -> Void) -> some View {
        return modifier(ToolBar(addItem: addItem))
    }
}

private struct ToolBar: ViewModifier {
    var addItem: () -> Void
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Product.self, inMemory: true)
}
