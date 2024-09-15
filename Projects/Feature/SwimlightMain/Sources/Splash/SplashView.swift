//
//  SplashView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import ComposableArchitecture
import SwiftUI

struct SplashView: View {
  // MARK: Reducer

  @Bindable
  var store: StoreOf<Splash>

  // MARK: Init

  init(store: StoreOf<Splash>) {
    self.store = store
  }

  // MARK: Content

  @ViewBuilder
  private func makeContentView() -> some View {
    VStack(spacing: Metrics.TextAndLogoSpacing) {
      Text("Swimlight")
        .font(.pretendard(.bold, size: 65))
        .padding(.top, Metrics.TextTopSpacing)
        .foregroundStyle(Color.black)

      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Metrics.logoHorizontalSpacing)
    }
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
