//
//  GreetingView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import ComposableArchitecture
import HealthKitUI
import SwiftUI

struct GreetingView: View {
  // MARK: Reducer

  @Bindable
  var store: StoreOf<Greeting>
  @State
  var trigger: Bool = false

  // MARK: Init

  init(store: StoreOf<Greeting>) {
    self.store = store
  }

  // MARK: Content

  @ViewBuilder
  private func makeContentView() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      makeTopGreetingView()
      makeCalendarView()
      makeBottomGreetingView()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, Metrics.horizontalSpacing)
  }

  // TODO: 오늘 수영했으면 멘트 바꾸기
  @ViewBuilder
  private func makeTopGreetingView() -> some View {
    Text("안녕하세요\n오늘도 즐거운 수영 되세요")
      .foregroundStyle(.black)
      .font(Font.pretendard(.regular, size: 18))
      .foregroundStyle(SLColor.primaryText.color)
  }

  @ViewBuilder
  private func makeCalendarView() -> some View {
    let buttonTitle = "눌러용"
    let isDisable = false
    VStack(spacing: 6) {
      SLCalendarView(
        calendarDelegate: store.calendarDelegate,
        singleSelectDelegate: store.calendarDelegate
      )
      .frame(maxWidth: .infinity, idealHeight: 450)
      .preferredColorScheme(.light)

      Button {
        store.send(.tappedDetailButton)
      } label: {
        Text(buttonTitle)
          .foregroundStyle(Color.white)
          .foregroundStyle(.black)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
          .background(isDisable ? SLColor.gray01.color : SLColor.main01.color)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .padding(.horizontal, 4)
    }
    .padding(.vertical, 6)
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .background(Color.main03.opacity(0.2))
  }

  @ViewBuilder
  private func makeBottomGreetingView() -> some View {
    VStack(alignment: .leading, spacing: Metrics.titleAndDescriptionSpading) {
      // Title
      Text("스트릭")
        .foregroundStyle(SLColor.primaryText.color)
        .font(.pretendard(.bold, size: 24))

      HStack(alignment: .center, spacing: 0) {
        // TODO: 멘트 배꾸기
        Text("오늘 수영하면 벌써 ")
          .foregroundStyle(SLColor.primaryText.color)
          .font(.pretendard(.bold, size: 18))

        // TODO: 멘트 바꾸기
        Text("10일")
          .foregroundStyle(SLColor.main01.color)
          .font(.pretendard(.bold, size: 20))
      }
    }
  }

  var body: some View {
    ZStack {
      Color.white
        .ignoresSafeArea()
      ScrollView {
        makeContentView()
      }
      .safeAreaPadding(.top, 55)
    }
    .navigationBarBackButtonHidden()
    .onAppear {
      store.send(.onAppear(true))
    }
    .sheet(item: $store.scope(state: \.detail, action: \.detail)) { store in
      SwimDetailView(store: store)
    }
  }

  private enum Metrics {
    static let horizontalSpacing: CGFloat = 16
    static let titleAndDescriptionSpading: CGFloat = 20
  }

  private enum Constants {}
}
