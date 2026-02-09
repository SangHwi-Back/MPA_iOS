//
//  MainDateList.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateList: View {
    @StateObject private var model: MainDateListViewModel
    
    @Binding private var path: [Product]
    
    @State private var tappedItemId: Int? = nil
    
    init(repository: ProductRepositoryProtocol, _ path: Binding<[Product]>) {
        self._path = path
        _model = StateObject(wrappedValue: MainDateListViewModel(repository: repository))
    }
    
    private var ListContentsForEach: some View {
        ForEach(model.items, id: \.id) { item in
            if UIDevice.current.userInterfaceIdiom == .pad {
                MainDateListLabel(product: item)
                    .listModifier(id: item.id, tappedItemId: $tappedItemId) {
                        self.tappedItem(item)
                    }
                    .padding(.horizontal)
            } else {
                MainDateListSwipeableItem(product: item) {
                    withAnimation {
                        if let index = model.items.firstIndex(of: item) {
                            model.deleteItems(at: IndexSet(integer: index))
                        }
                    }
                }
                .padding(.horizontal)
                .listModifier(id: item.id, tappedItemId: $tappedItemId) {
                    self.tappedItem(item)
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
                    List { ListContentsForEach }
                }
            } else {
                VStack { ListContentsForEach }
            }
        }
        .addToolbar(model, path: $path)
        .onChange(of: path.count) { oldValue, newValue in
            if oldValue > newValue {
                model.fetchItems()
            }
        }
    }
    
    private func tappedItem(_ item: Product) {
        tappedItemId = item.id
        
        path.append(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tappedItemId = nil
        }
    }
}

private extension View {
    func addToolbar(_ model: MainDateListViewModel, path: Binding<[Product]>) -> some View {
        return modifier(ToolBar(model, path: path))
    }
    
    func listModifier(id: Int, tappedItemId: Binding<Int?>, animationHandler: @escaping () -> Void) -> some View {
        return modifier(ListModifier(tappedItemId: tappedItemId, id: id, animationHandler: animationHandler))
    }
}

private struct ToolBar: ViewModifier {
    private var model: MainDateListViewModel
    @Binding private var path: [Product]
    
    init(_ model: MainDateListViewModel, path: Binding<[Product]>) {
        self.model = model
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
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .glassEffect()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ButtonWithAnimate {
                        let item = model.tappedToolbarAddItem()
                        path.append(item)
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

//#Preview("데이터 없음") {
//    ContentView()
//        .productRepository(MockProductRepository(withSampleData: false))
//}

#Preview("데이터 있음") {
    MainDateList.init(
        repository: MockProductRepository(withSampleData: true),
        Binding.constant([Product]())
    )
}
