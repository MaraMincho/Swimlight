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
    VStack(spacing: 0) {
      Text("하이 나는 그리팅")
      Text("하이 나는 그리팅")
        .font(.pretendard(.bold, size: 16))
    }
  }

  var body: some View {
    ZStack {
      Color.white
      VStack(spacing: 0) {
        makeContentView()
      }
    }
    .navigationBarBackButtonHidden()
    .onAppear {
      store.send(.view(.onAppear(true)))
    }
  }

  private enum Metrics {}

  private enum Constants {}
}
