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
    VStack(alignment: .leading, spacing: 24) {
      makeTopGreetingView()
      makeStrictView()
      makeCalendarView()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, Metrics.horizontalSpacing)
  }

  // TODO: 오늘 수영했으면 멘트 바꾸기
  @ViewBuilder
  private func makeTopGreetingView() -> some View {
    Text("안녕하세요\n오늘도 즐거운 수영 되세요")
      .foregroundStyle(.black)
      .font(Font.pretendard(.bold, size: 30))
      .foregroundStyle(SLColor.primaryText.color)
  }

  @ViewBuilder
  private func makeCalendarView() -> some View {
    let buttonTitle = store.buttonTitle
    let isDisable = !store.isDetailReportExist
    VStack(spacing: 6) {
      SLCalendarView(
        calendarDelegate: store.calendarDelegate,
        singleSelectDelegate: store.calendarDelegate
      )
      .frame(maxWidth: .infinity, idealHeight: 450)
      .preferredColorScheme(.light)
      .padding(.vertical, 6)
      .background(Color.main03.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .id(store.calendarViewID)

      Button {
        store.send(.tappedDetailButton)
      } label: {
        Text(buttonTitle)
          .font(.pretendard(.bold, size: 20))
          .foregroundStyle(Color.white)
          .foregroundStyle(.black)
          .padding(.vertical, 20)
          .frame(maxWidth: .infinity)
          .background(isDisable ? SLColor.gray03.color : SLColor.main01.color)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .disabled(isDisable)
      .padding(.horizontal, 4)
    }
  }

  @ViewBuilder
  private func makeStrictView() -> some View {
    HStack(alignment: .top, spacing: 0) {
      VStack(alignment: .leading, spacing: Metrics.titleAndDescriptionSpading) {
        Text("스트릭")
          .foregroundStyle(SLColor.gray03.color)
          .font(.pretendard(.bold, size: 24))

        HStack(alignment: .center, spacing: 0) {
          Text("오늘 수영하면 벌써 ")
            .foregroundStyle(SLColor.gray02.color)
            .font(.pretendard(.bold, size: 18))
        }
      }
      Spacer()

      Circle()
        .fill(.main02)
        .frame(width: 100, height: 100)
        .overlay(alignment: .center) {
          Text("10일")
            .foregroundStyle(SLColor.primaryText.color)
            .font(.pretendard(.bold, size: 30))
        }
    }
    .padding(.all, 12)
    .background(Color.main03.opacity(0.2))
    .clipShape(RoundedRectangle(cornerRadius: 12))
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
    .alert($store.scope(state: \.alert, action: \.alert))
    .onChange(of: store.openSettings) { _, _ in
      openHealthApp()
    }
  }

  private func openHealthApp() {
    if let url = URL(string: "x-apple-health://") {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  private enum Metrics {
    static let horizontalSpacing: CGFloat = 16
    static let titleAndDescriptionSpading: CGFloat = 20
  }

  private enum Constants {}
}
