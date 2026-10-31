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
    
    var body: some View {
        Group {
            if model.items.isEmpty {
                EmptyView
            } else {
                ListContentsForEach
            }
        }
        .onChange(of: path.count) { oldValue, newValue in
            if oldValue > newValue {
                model.fetchItems()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var EmptyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .fontWeight(.light)
                
                Text("반가워요")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title)
                    .fontWeight(.bold)
                
                Image("empty-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 160)
                
                Text("첫 일기를 써보세요")
                    .font(.title3.bold())
                
                Text("몇 줄이면 충분해요. 일기가 쌓이면\n그 안에서 나만의 원칙을 찾아드릴게요.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button {
                    let item = model.tappedToolbarAddItem()
                    path.append(item)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.tip")
                        Text("첫 일기 쓰기")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.blue)
                    )
                }
                
                Spacer()
                
                Text("이런 질문으로 시작해 보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 10) {
                    ForEach(Self.sampleQuestions, id: \.self) { question in
                        QuestionChip(text: question)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let item = model.tappedToolbarAddItem()
                                path.append(item)
                            }
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "scale")
                        .font(.caption)
                    Text("모든 분석은 이 기기 안에서 이루어져요")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 질문 데이터
    
    private static let sampleQuestions: [String] = [
        "오늘 가장 오래 머무른 생각은 무엇이었나요?",
        "최근 누군가에게 고마웠던 순간이 있나요?",
        "내일의 나에게 한마디 한다면?"
    ]
    
    // MARK: - 질문 칩
    
    private struct QuestionChip: View {
        let text: String
        
        var body: some View {
            HStack {
                Text(text)
                    .font(.body)
                    
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - List Contents
    
    private var ListContentsForEach: some View {
        List {
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
    }
    
    private func tappedItem(_ item: Product) {
        tappedItemId = item.id
        
        path.append(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tappedItemId = nil
        }
    }
}

// MARK: - View Extensions

extension View {
    func addToolbar(_ model: MainDateListViewModel, path: Binding<[Product]>) -> some View {
        return modifier(ToolBar(model, path: path))
    }
    
    func listModifier(id: Int, tappedItemId: Binding<Int?>, animationHandler: @escaping () -> Void) -> some View {
        return modifier(ListModifier(tappedItemId: tappedItemId, id: id, animationHandler: animationHandler))
    }
}

// MARK: - View Modifiers

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

// MARK: - Previews

#Preview("데이터 없음") {
    MainDateList(
        repository: EmptyProductRepositoryForPreview(),
        Binding.constant([Product]())
    )
}

#Preview("데이터 있음") {
    MainDateList(
        repository: MockProductRepository(withSampleData: true),
        Binding.constant([Product]())
    )
}
