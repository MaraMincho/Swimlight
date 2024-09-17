//
//  SwimDetailReducer.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import Foundation

// MARK: - SwimDetailReducer

@Reducer
struct SwimDetailReducer {
  @ObservableState
  struct State: Equatable {
    var onAppear: Bool = false
    fileprivate let targetDate: Date
    fileprivate var workoutSeconds: Int = 0
    fileprivate var monthAverageSeconds: Int = 0
    var workoutSecondsLabel: String {
      let (h, m, s) = formatTimeIntervalToHMS(workoutSeconds)
      let hourLabel = h != 0 ? "\(h)시간" : ""
      let minuteLabel = "\(m)분"
      let secondsLabel = "\(s)초"
      return [hourLabel, minuteLabel, secondsLabel].joined(separator: " ")
    }

    var workoutCapshuleLabel: String {
      if monthAverageSeconds == 0 {
        return "5%"
      }
      let percentage = Int(Double(workoutSeconds - monthAverageSeconds) / Double(monthAverageSeconds) * 100)
      return percentage.description + "%"
    }

    var titleLabel: String {
      dateFormatter.string(from: targetDate) + " 수영 리포트"
    }

    init(targetDate: Date) {
      self.targetDate = targetDate
    }
  }

  enum Action: Equatable {
    case onAppear(Bool)
    case updateWorkoutDuration(seconds: Int, monthSecondsAverage: Int)
  }

  @Dependency(\.healthKitManager) var healthKitManager

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .onAppear(val):
        if state.onAppear {
          return .none
        }

        state.onAppear = val
        return .run { [targetDate = state.targetDate] send in
          async let averageSeconds = healthKitManager.readMonthWorkoutAverageSeconds(targetDate)
          async let targetDateSeconds = healthKitManager.readTargetDateWorkoutSeconds(targetDate)
          try await send(.updateWorkoutDuration(seconds: targetDateSeconds, monthSecondsAverage: averageSeconds))
        }
      case let .updateWorkoutDuration(seconds, monthSecondsAverage):
        state.workoutSeconds = seconds
        state.monthAverageSeconds = monthSecondsAverage
        return .none
      }
    }
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM dd일"
  return formatter
}()

private func formatTimeIntervalToHMS(_ timeInterval: Int) -> (hours: Int, minutes: Int, seconds: Int) {
  // 총 시간을 초 단위로 받아온 뒤 각 단위로 변환
  let hours = timeInterval / 3600
  let minutes = (timeInterval % 3600) / 60
  let seconds = timeInterval % 60

  return (hours, minutes, seconds)
}
