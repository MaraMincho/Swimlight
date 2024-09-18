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
    fileprivate var workoutDistance: Int = 0
    fileprivate var monthAverageDistance: Int = 0
    var chartProperty: HeartRateChartProperty? = nil
    var heartRateZones: [HeartRateZone: TimeInterval] = [:]

    private let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      return formatter
    }()

    var workoutSecondsLabel: String {
      let (h, m, s) = formatTimeIntervalToHMS(workoutSeconds)
      let hourLabel = h != 0 ? "\(h)시간" : ""
      let minuteLabel = "\(m)분"
      let secondsLabel = "\(s)초"
      return [hourLabel, minuteLabel, secondsLabel].joined(separator: " ")
    }

    var workoutSecondsCapsuleLabel: String {
      if monthAverageSeconds == 0 {
        return ""
      }
      let percentage = Int(Double(workoutSeconds - monthAverageSeconds) / Double(monthAverageSeconds) * 100)
      return (percentage > 0 ? "+" : "") + percentage.description + "%"
    }

    var workoutDistanceLabel: String {
      (numberFormatter.string(from: workoutDistance as NSNumber) ?? "0") + "m"
    }

    var workoutDistanceCapsuleLabel: String {
      if monthAverageDistance == 0 {
        return ""
      }
      let percentage = Int(Double(workoutDistance - monthAverageDistance) / Double(monthAverageDistance) * 100)
      return (percentage > 0 ? "+" : "") + percentage.description + "%"
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
    case updateWorkoutDistance(distance: Int, monthDistanceAverage: Int)
    case updateHeartRateChartProperty(HeartRateChartProperty)
    case updateHeartRateZone([HeartRateZone: TimeInterval])
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
          await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask {
              async let averageSeconds = healthKitManager.readMonthWorkoutAverageSeconds(targetDate)
              async let targetDateSeconds = healthKitManager.readTargetDateWorkoutSeconds(targetDate)
              try await send(.updateWorkoutDuration(seconds: targetDateSeconds, monthSecondsAverage: averageSeconds))
            }
            taskGroup.addTask {
              async let averageDistance = healthKitManager.readMonthWorkoutAverageDistance(targetDate)
              async let targetDateDistance = healthKitManager.readTargetDateDistance(targetDate)
              try await send(.updateWorkoutDistance(distance: targetDateDistance, monthDistanceAverage: averageDistance))
            }
            taskGroup.addTask {
              let chartProperty = try await healthKitManager.getHeartRateSamples(targetDate)
              await send(.updateHeartRateChartProperty(chartProperty))
            }
            taskGroup.addTask {
              let heartRateZone = try await healthKitManager.calculateTimeInHeartRateZones(targetDate)
              await send(.updateHeartRateZone(heartRateZone))
            }
            taskGroup.addTask {
              try await healthKitManager.getStrokeStyleDistance(targetDate)
            }
          }
        }
      case let .updateWorkoutDuration(seconds, monthSecondsAverage):
        state.workoutSeconds = seconds
        state.monthAverageSeconds = monthSecondsAverage
        return .none

      case let .updateWorkoutDistance(distance, monthDistanceAverage):
        state.workoutDistance = distance
        state.monthAverageDistance = monthDistanceAverage
        return .none

      case let .updateHeartRateChartProperty(property):
        state.chartProperty = property
        return .none

      case let .updateHeartRateZone(zone):
        state.heartRateZones = zone
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

func formatTimeIntervalToHMS(_ timeInterval: Int) -> (hours: Int, minutes: Int, seconds: Int) {
  // 총 시간을 초 단위로 받아온 뒤 각 단위로 변환
  let hours = timeInterval / 3600
  let minutes = (timeInterval % 3600) / 60
  let seconds = timeInterval % 60

  return (hours, minutes, seconds)
}
