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
            if UIDevice.current.userInterfaceIdiom == .pad {
                MainDateListLabel()
                    .listModifier(id: item.id, tappedItemId: $tappedItemId) {
                        tappedItemId = item.id
                        model.tappedList(item.id)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            tappedItemId = nil
                        }
                    }
            } else {
                MainDateListSwipeableItem(product: item) {
                    withAnimation {
                        if let index = model.items.firstIndex(of: item) {
                            model.deleteItems(at: IndexSet(integer: index))
                        }
                    }
                }
                .listModifier(id: item.id, tappedItemId: $tappedItemId) {
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
                }
            } else {
                VStack {
                    ListContents
                }
            }
        }
        .addToolbar(model)
        .onWillAppear {
            model.fetchItems()
        }
    }
}

private extension View {
    func addToolbar(_ model: MainDateListViewModel) -> some View {
        return modifier(ToolBar(model))
    }
    
    func listModifier(id: Int, tappedItemId: Binding<Int?>, animationHandler: @escaping () -> Void) -> some View {
        return modifier(ListModifier(tappedItemId: tappedItemId, id: id, animationHandler: animationHandler))
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

private struct ListModifier: ViewModifier {
    @Binding var tappedItemId: Int?
    var id: Int
    var animationHandler: () -> Void
    
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .scaleEffect(tappedItemId == id ? 0.95 : 1.0)
            .opacity(tappedItemId == id ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: tappedItemId)
            .onTapGesture {
                withAnimation {
                    animationHandler()
                }
            }
    }
}

extension View {
    func onWillAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(WillAppearModifier(callback: perform))
    }
}

struct WillAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content.background(UIViewLifeCycleHandler(onWillAppear: callback))
    }
}

struct UIViewLifeCycleHandler: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    var onWillAppear: () -> Void = { }

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> UIViewControllerType {
        context.coordinator
    }

    func updateUIViewController(
        _: UIViewControllerType,
        context _: UIViewControllerRepresentableContext<Self>
    ) { }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(onWillAppear: onWillAppear)
    }

    class Coordinator: UIViewControllerType {
        let onWillAppear: () -> Void

        init(onWillAppear: @escaping () -> Void) {
            self.onWillAppear = onWillAppear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            onWillAppear()
        }
    }
}

#Preview {
    MainDateList(.constant([
        Product.init(id: 0, name: "Test1", desc: "", price: 0, stock: 0, images: [], createdAt: "", updatedAt: "")
    ]))
}
