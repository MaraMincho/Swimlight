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
    Text("안녕로봇")
  }

  var body: some View {
    ZStack {
      Color.white
        .ignoresSafeArea()
      VStack(spacing: 0) {
        makeContentView()
      }
    }
    .navigationBarBackButtonHidden()
    .onAppear {
      store.send(.view(.onAppear(true)))
    }
  }

  private enum Metrics {
    static let TextTopSpacing: CGFloat = 82
    static let TextAndLogoSpacing: CGFloat = 60
    static let logoHorizontalSpacing: CGFloat = 50
  }

  private enum Constants {}
}
