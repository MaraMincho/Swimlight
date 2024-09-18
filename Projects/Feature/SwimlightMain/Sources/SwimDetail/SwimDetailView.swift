//
//  SwimDetailView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

// MARK: - SwimDetailView

struct SwimDetailView: View {
  @Bindable
  var store: StoreOf<SwimDetailReducer>

  @ViewBuilder
  private func makeContent() -> some View {
    VStack(alignment: .leading, spacing: 40) {
      makeTitleLabel()
        .padding(.horizontal, 16)
      ScrollView {
        makeScrollContentView()
      }
    }
    .padding(.top, 20)
  }

  @ViewBuilder
  private func makeTitleLabel() -> some View {
    Text(store.titleLabel)
      .foregroundStyle(SLColor.primaryText.color)
      .font(.pretendard(.bold, size: 24))
  }

  @ViewBuilder
  private func makeScrollContentView() -> some View {
    VStack(spacing: 40) {
      makeMonthDifferenceView()
    }
  }

  @ViewBuilder
  private func makeMonthDifferenceView() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      makeCardTitleView(Constants.MonthDifferenceTitle)
      HStack(spacing: 9) {
        makeHalfCardTitle(topLabel: "운동 시간", middleLabel: store.workoutSecondsLabel, capsuleLabel: store.workoutSecondsCapsuleLabel)

        makeHalfCardTitle(topLabel: "운동 거리", middleLabel: store.workoutDistanceLabel, capsuleLabel: store.workoutDistanceCapsuleLabel)
      }
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func makeHalfCardTitle(
    topLabel: String,
    middleLabel: String,
    capsuleLabel: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(topLabel)
        .foregroundStyle(SLColor.primaryText.color)
        .font(.pretendard(.bold, size: 18))

      Text(middleLabel)
        .foregroundStyle(SLColor.main01.color)
        .font(.pretendard(.bold, size: 24))
        .lineLimit(1)
        .minimumScaleFactor(0.4)

      Spacer()

      Text(capsuleLabel)
        .foregroundStyle(Color.white)
        .font(.pretendard(.bold, size: 12))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.primaryText)
        .clipShape(Capsule())
    }
    .padding(.all, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .makeSLCardShadow()
  }

  @ViewBuilder
  private func makeCardTitleView(_ label: String) -> some View {
    Text(label)
      .foregroundStyle(SLColor.primaryText.color)
      .font(.pretendard(.bold, size: 18))
  }

  var body: some View {
    makeContent()
      .onAppear {
        store.send(.onAppear(true))
      }
  }

  private enum Constants {
    static let MonthDifferenceTitle = "이번달과 비교해서"
  }
}

private extension View {
  func makeSLCardShadow() -> some View {
    background(.gray01)
      .cornerRadius(8)
      .shadow(color: .black.opacity(0.25), radius: 2, x: 2, y: 2)
  }
}
