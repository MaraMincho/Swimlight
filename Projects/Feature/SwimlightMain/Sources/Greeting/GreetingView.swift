//
//  GreetingView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import ComposableArchitecture
import SwiftUI

struct GreetingView: View {
  // MARK: Reducer

  @Bindable
  var store: StoreOf<Greeting>

  // MARK: Init

  init(store: StoreOf<Greeting>) {
    self.store = store
  }

  // MARK: Content

  @ViewBuilder
  private func makeContentView() -> some View {
    VStack(spacing: 6) {
      Text("안녕하세요\n오늘도 즐거운 수영 되세요")
        .foregroundStyle(.black)
      SLCalendarView()
        .frame(maxWidth: .infinity, idealHeight: 450)
        .preferredColorScheme(.light)

      Button {
        store.send(.tappedDetailButton)
      } label: {
        Text("눌러 ")
          .foregroundStyle(.black)
      }
    }
    .frame(maxWidth: .infinity)
  }

  var body: some View {
    ZStack {
      Color.white
        .ignoresSafeArea()
      ScrollView {
        makeContentView()
      }
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
    static let TextTopSpacing: CGFloat = 82
    static let TextAndLogoSpacing: CGFloat = 60
    static let logoHorizontalSpacing: CGFloat = 50
  }

  private enum Constants {}
}
