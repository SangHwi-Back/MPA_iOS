//
//  MainDateList.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI
import SwiftData

struct MainDateList: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Product]
    
    private func contentDateText(_ date: Date?) -> some View {
        var label: Text
        if let date {
            label = Text("Item at \(date, format: Date.FormatStyle(date: .numeric, time: .standard))")
        } else {
            label = Text("No Date")
        }
        
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
            label
        }
        .frame(height: 60)
    }
    
    private var ListContents: some View {
        ForEach(items) { item in
            NavigationLink {
                contentDateText(item.date)
            } label: {
                contentDateText(item.date)
            }
            .listRowSeparator(.hidden)
        }
        .onDelete(perform: deleteItems)
    }
    
    var body: some View {
        Group {
        if UIDevice.current.userInterfaceIdiom == .pad {
                if items.isEmpty {
                    Color.clear
                } else {
                    List {
                        ListContents
                    }
                    .listStyle(.plain)
                    .listRowBackground(Color.clear)
                }
        } else {
            VStack {
                ListContents
            }
        }
        }
        .addEditAndAddToolBar(addItem)
    }
}

private extension MainDateList {
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
    
    private let showCalendar = ContextMenu {
        Button("Show Calendar") {
            // TODO: Show Calendar modal
            print("Calendar")
        }
    }
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .topBarLeading) {
                        Image(systemName: "calendar")
                            .tint(.blue)
                            .contextMenu(showCalendar)
                            
                    }
                }
                
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
    MainDateList()
}
