//
//  SwimDetailView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Charts
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
      .safeAreaPadding(.bottom, 20)
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
      makeHeartRateChartView()
      makeZoneChartView()
      makeStrokeStyleView()
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
  private func makeHeartRateChartView() -> some View {
    if let chartProperty = store.chartProperty {
      let range = (chartProperty.minimumHeartRate - 10) ... (chartProperty.maximumHeartRate + 10)
      VStack(alignment: .leading, spacing: 12) {
        makeCardTitleView("심박수")
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 0) {
            Text("평균 심박수")
              .foregroundStyle(SLColor.primaryText.color)
              .font(.pretendard(.bold, size: 22))

            Spacer()

            Text(chartProperty.maximumHeartRate.description + "BPM")
              .foregroundStyle(SLColor.main01.color)
              .font(.pretendard(.bold, size: 22))
          }
          HStack(spacing: 0) {
            Text("최소 심박수: " + chartProperty.minimumHeartRate.description)
              .foregroundStyle(SLColor.primaryText.color)
              .font(.pretendard(.bold, size: 14))

            Spacer()

            Text("최대 심박수: " + chartProperty.maximumHeartRate.description)
              .foregroundStyle(SLColor.primaryText.color)
              .font(.pretendard(.bold, size: 14))
          }

          Chart(chartProperty.items) { item in
            LineMark(
              x: .value("Time", item.interval),
              y: .value("HeartRate", item.y)
            )
          }
          .chartYScale(domain: range)
          .chartYAxis(.hidden)
          .chartXAxis(.hidden)
          .chartLegend(.hidden)
          .foregroundStyle(SLColor.main01.color)
          .frame(idealHeight: 350)
          .background(Color.white)

          Text(chartProperty.totalHour.description + "H" + chartProperty.totalMinute.description + "M")
            .foregroundStyle(SLColor.primaryText.color)
            .font(.pretendard(.bold, size: 22))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.all, 12)
        .makeSLCardShadow()
      }
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func makeZoneChartView() -> some View {
    let heartRateZones: [(HeartRateZone, TimeInterval)] = store.heartRateZones.sorted { $0.key.id < $1.key.id }.map { ($0.key, $0.value) }

    if !heartRateZones.isEmpty {
      let totalSeconds = heartRateZones.map(\.1).reduce(0) { $0 + $1 }

      VStack(alignment: .leading, spacing: 12) {
        makeCardTitleView("심박수 강도 Zone")
        VStack(alignment: .leading, spacing: 12) {
          ForEach(heartRateZones, id: \.0) { zone, interval in
            let (h, m, s) = formatTimeIntervalToHMS(Int(interval))
            let trailingTitle = ((h == 0) ? "" : "\(h)H")
              + ((m == 0) ? "" : "\(m)M")
              + ((s == 0) ? "" : "\(s)S")
            let ratio = interval / totalSeconds

            makeZoneChartElement(
              leadingLabel: zone.description + "  " + zone.subTitle,
              trailingLabel: trailingTitle,
              widthRatio: ratio
            )
          }
        }
        .padding(.all, 12)
        .makeSLCardShadow()
      }
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func makeStrokeStyleView() -> some View {
    let items = store.strokeStylesAndMeter.sorted(by: { $0.key.rawValue < $1.key.rawValue }).filter { [2, 3, 4, 5].contains($0.key.rawValue) }

    if !items.isEmpty {
      let leftoverMeter = store.workoutDistance - items.reduce(0) { $0 + $1.value }
      VStack(alignment: .leading, spacing: 12) {
        makeCardTitleView("수영 상세")
        VStack(alignment: .leading, spacing: 12) {
          ForEach(items, id: \.key.rawValue) { item in
            HStack(alignment: .center, spacing: 0) {
              Text(item.key.description())
              Spacer()
              Text(item.value.description + "M")
            }
          }
          HStack(alignment: .center, spacing: 0) {
            Text("기타")
            Spacer()
            Text(leftoverMeter.description + "M")
          }
        }
        .padding(.all, 12)
        .makeSLCardShadow()
      }
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func makeZoneChartElement(
    leadingLabel: String,
    trailingLabel: String,
    widthRatio: Double
  ) -> some View {
    VStack(spacing: 4) {
      HStack(alignment: .center, spacing: 0) {
        Text(leadingLabel)
          .foregroundStyle(SLColor.primaryText.color)
          .font(.pretendard(.regular, size: 12))

        Spacer()

        Text(trailingLabel)
          .foregroundStyle(SLColor.primaryText.color)
          .font(.pretendard(.regular, size: 12))
      }
      GeometryReader { proxy in
        RoundedRectangle(cornerRadius: 12)
          .fill(SLColor.gray03.color)
          .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
              .fill(SLColor.main01.color)
              .frame(width: proxy.size.width * widthRatio)
          }
      }
      .frame(maxWidth: .infinity, idealHeight: 15)
    }
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
