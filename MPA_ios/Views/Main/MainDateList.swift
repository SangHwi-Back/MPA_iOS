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
    
    init() {
        let viewModel = MainDateListViewModel()
        _model = StateObject(wrappedValue: viewModel)
    }
    
    private var ListContents: some View {
        ForEach(model.items) { item in
            NavigationLink {
                Text("Detail")
            } label: {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    MainDateListLabel()
                } else {
                    MainDateListItem(product: item)
                }
            }
            .listRowSeparator(.hidden)
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
        .addEditAndAddToolBar(model.addItem)
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
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
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
