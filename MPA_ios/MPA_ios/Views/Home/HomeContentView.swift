//
//  HomeContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/16/26.
//

import SwiftUI

/*
 # uitest
 ## 개요
 - HomeView 의 본문 화면. 일기 개수와 AI 사용 가능 여부에 따라 `첫 실행`, `일기 앱`, `AI 초기`, `AI 전체` 중 한 상태를 보여준다
 - 폭이 넓은 기기(iPad 등)의 `AI 초기`, `AI 전체` 는 두 칼럼으로 배치되지만 보이는 요소는 같다
 ## 용어 정리
 - 준비 상태 (테스트 실행 인자로 만든다)
   - `[빈 상태]` : 일기 0개
   - `[일기 앱]` : AI 사용 불가, 일기 3개, 오늘 일기 없음
   - `[일기 앱·오늘 씀]` : AI 사용 불가, 오늘 일기를 포함한 일기 3개
   - `[AI 초기]` : AI 사용 가능, 일기 1개, 오늘 일기 없음
   - `[AI 전체]` : AI 사용 가능, 이번 주 일기를 포함한 일기 3개 이상, 오늘 일기 없음
 - `첫 실행` : `home.empty` 와 예시 질문 `home.empty.example.[1번부터 시작하는 번호]` 가 있는 상태
 - `일기 앱` : `home.weekStrip`, `home.recent` 가 있는 상태. 오늘 일기가 없으면 `home.todayCard`, 있으면 `home.todayPreview` 가 보인다
 - `AI 초기` : `ai.card.homeAdvice`, `home.prompt`, `home.principles.progress` 가 있는 상태
 - `AI 전체` : `ai.card.homeAdvice`, `home.prompt`, `home.principles` 가 있고 `home.principles.progress` 는 없는 상태. 이번 주 일기가 있으면 `ai.card.homeWeekly` 가 보인다
 - `AI 경고 버튼` : `home.aiWarningButton`. AI 를 쓸 수 없을 때만 툴바에 보인다
 ## 테스트할 요소
 - 공통: `home.greeting` 과 `home.date` 가 보인다
 - [빈 상태] 공통: `home.empty`, `home.empty.example.1` 이 보이고 `home.recent`, `ai.card.homeAdvice` 는 없다
 - [일기 앱] 공통: `home.todayCard`, `home.weekStrip`, `home.recent.item.1` 이 보이고 `ai.card.homeAdvice` 는 없다
 - [일기 앱] 공통: `home.aiWarningButton` 을 누르면 알림이 뜨고, 알림의 확인 버튼을 누르면 알림이 사라진다
 - [일기 앱·오늘 씀] 공통: `home.todayPreview` 가 보이고 `home.todayCard` 는 없다
 - [AI 초기] 공통: `ai.card.homeAdvice`, `home.prompt`, `home.principles.progress` 가 보이고 `home.aiWarningButton` 은 없다
 - [AI 전체] 공통: `ai.card.homeAdvice`, `home.principles`, `ai.card.homeWeekly` 가 보이고 `home.principles.progress` 는 없다
 ## 제외
 - 다른 화면으로 넘어가는 동작 (예시 질문, 글감 쓰기, `home.todayCard.write`, 최근 기록 항목, 주간 스트립 날짜를 눌렀을 때 에디터·상세가 열리는지): 에디터·상세 화면의 식별자가 아직 없음
 - AI 카드 안의 내용과 버튼 (조언 문구, 출처 칩, 피드백·다시 생성): 생성 결과에 따라 달라짐. 표시 여부는 위 상태 케이스에서, 값은 Unit 테스트에서 확인
 - 알림의 API 키 연결 버튼: 설정 화면으로 이동하는 동작이라 위 첫 번째 제외 항목과 같은 이유
 */

struct HomeContentView: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    let onConnectKey: () -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isHeaderScrolledAway = false
    
    private var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeLayoutMetrics.sectionSpacing) {
                HomeGreetingHeader(dateLine: homeViewModel.dateLine, greeting: homeViewModel.greeting)
                    .padding(.bottom, 4)
                if isRegular, homeViewModel.layout == .full || homeViewModel.layout == .early {
                    HomeContentRegularColumns(
                        onWrite: onWrite,
                        onOpenEntry: onOpenEntry,
                        onSelectTab: onSelectTab,
                        onConnectKey: onConnectKey
                    )
                } else {
                    HomeContentSections(
                        onWrite: onWrite,
                        onOpenEntry: onOpenEntry,
                        onSelectTab: onSelectTab,
                        onConnectKey: onConnectKey
                    )
                }
            }
            .padding(.horizontal, HomeLayoutMetrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: isRegular ? 1100 : HomeLayoutMetrics.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color.CANVAS)
        .accessibilityIdentifier(AccessibilityID.Home.screen)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 72
        } action: { _, isHidden in
            isHeaderScrolledAway = isHidden
        }
        .navigationTitle(isHeaderScrolledAway ? "오늘" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { HomeContentToolbar(onWrite: onWrite) }
        .alert(
            homeViewModel.aiStatus.unavailableReason?.homeAlertTitle ?? "",
            isPresented: Binding(get: {
                homeViewModel.isAlertPresented
            }, set: {
                homeViewModel.isAlertPresented = $0
            }),
            presenting: homeViewModel.aiStatus.unavailableReason
        ) { _ in
            Button("API 키 연결", action: onConnectKey)
            Button("확인") {}
                .keyboardShortcut(.defaultAction)
        } message: { reason in
            Text(reason.homeAlertMessage)
        }
    }
}

// MARK: - HomeContentToolbar

private struct HomeContentToolbar: ToolbarContent {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some ToolbarContent {
        if !homeViewModel.aiStatus.isAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    homeViewModel.isAlertPresented = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.WARNING)
                .accessibilityLabel(homeViewModel.aiStatus.unavailableReason?.homeAlertTitle ?? "AI 경고")
                .accessibilityIdentifier(AccessibilityID.Home.aiWarningButton)
                .transition(.scale.combined(with: .opacity))
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // An existing entry for today should open in edit mode; the editor cannot load one yet.
                onWrite(nil, nil)
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .accessibilityLabel("새 일기")
            .accessibilityIdentifier(AccessibilityID.Home.newJournalButton)
        }
    }
}
