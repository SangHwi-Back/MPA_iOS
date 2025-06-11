//
//  MainDateList.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI
import SwiftData

struct MainDateList: View {
    @StateObject private var model: MainDateListViewModel
    @State private var tappedItemId: Int? = nil
    @Binding private var path: [Product]
    
    init(_ path: Binding<[Product]>) {
        self._path = path
        let viewModel = MainDateListViewModel()
        _model = StateObject(wrappedValue: viewModel)
    }
    
    private var ListContents: some View {
        ForEach(model.items, id: \.id) { item in
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    MainDateListLabel()
                } else {
                    MainDateListSwipeableItem(product: item) {
                        if let index = model.items.firstIndex(of: item) {
                            model.deleteItems(at: IndexSet(integer: index))
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
            .scaleEffect(tappedItemId == item.id ? 0.95 : 1.0)
            .opacity(tappedItemId == item.id ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: tappedItemId)
            .onTapGesture {
                withAnimation {
                    tappedItemId = item.id
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        tappedItemId = nil
                        path.append(item)
                    }
                }
            }
        }
        .onDelete(perform: model.deleteItems)
    }
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if model.items.isEmpty {
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
        .addToolbar($path)
    }
}

private extension View {
    func addToolbar(_ path: Binding<[Product]> = .constant([])) -> some View {
        return modifier(ToolBar(path))
    }
}

private struct ToolBar: ViewModifier {
    @Binding private var path: [Product]
    
    init(_ path: Binding<[Product]>) {
        self._path = path
    }
    
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
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                
                ToolbarItem {
                    Button {
                        path.append(Product(
                            id: -1,
                            name: "New Item",
                            desc: "",
                            price: 0,
                            stock: 0,
                            images: [],
                            createdAt: ISO8601DateFormatter.common.string(from: Date()),
                            updatedAt: nil))
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview {
    MainDateList(.constant([]))
}
