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
    
    init(_ path: Binding<[Product]>) {
        let viewModel = MainDateListViewModel(navigationPath: path)
        _model = StateObject(wrappedValue: viewModel)
    }
    
    private var ListContents: some View {
        ForEach(model.items, id: \.id) { item in
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    MainDateListLabel()
                } else {
                    MainDateListSwipeableItem(product: item) {
                        withAnimation {
                            if let index = model.items.firstIndex(of: item) {
                                model.deleteItems(at: IndexSet(integer: index))
                            }
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
                    model.tappedList(item.id)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        tappedItemId = nil
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
                    .glassEffect()
                }
            } else {
                VStack {
                    ListContents
                }
                .glassEffect()
            }
        }
        .addToolbar(model)
    }
}

private extension View {
    func addToolbar(_ model: MainDateListViewModel) -> some View {
        return modifier(ToolBar(model))
    }
}

private struct ToolBar: ViewModifier {
    private var model: MainDateListViewModel
    
    init(_ model: MainDateListViewModel) {
        self.model = model
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
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .glassEffect()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ButtonWithAnimate {
                        model.tappedToolbarAddItem()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                    }
                }
            }
    }
}

#Preview {
    MainDateList(.constant([
        Product.init(id: 0, name: "Test1", desc: "", price: 0, stock: 0, images: [], createdAt: "", updatedAt: "")
    ]))
}
