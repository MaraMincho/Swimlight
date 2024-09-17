//
//  SLHealthKitDelegate.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/16/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Dependencies
import Foundation
import HealthKit
import UIKit

// MARK: - SLHealthKitManager

struct SLHealthKitManager {
  static let store = HKHealthStore()
  var isHealthDataAvailable: () -> Bool
  private static func _isHealthDataAvailable() -> Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  var authorizationStatus: () async throws -> HKAuthorizationRequestStatus
  private static func _authorizationStatus() async throws -> HKAuthorizationRequestStatus {
    // MARK: - is only for write mode, so you make another logic

    let typesToShare: [HKWorkoutType] = []

    let typesToRead: [HKObjectType] = [
      .workoutType(),
      HKQuantityType(.heartRate),
      HKQuantityType(.walkingHeartRateAverage),
      HKQuantityType(.activeEnergyBurned),
      .activitySummaryType(),
      HKQuantityType(.swimmingStrokeCount),
      HKQuantityType(.distanceSwimming),
    ]

    return try await withCheckedThrowingContinuation { continuation in
      store.getRequestStatusForAuthorization(toShare: .init(typesToShare), read: .init(typesToRead)) { status, error in
        if let error {
          continuation.resume(throwing: error)
        }
        continuation.resume(returning: status)
      }
    }
  }

  var requestAuthorization: () async throws -> Void
  private static func _requestAuthorization() async throws {
    // none to write
    let typesToShare: [HKWorkoutType] = [
    ]

    let typesToRead: [HKObjectType] = [
      .workoutType(),
      HKQuantityType(.heartRate),
      HKQuantityType(.walkingHeartRateAverage),
      HKQuantityType(.activeEnergyBurned),
      .activitySummaryType(),
      HKQuantityType(.swimmingStrokeCount),
      HKQuantityType(.distanceSwimming),
    ]

    try await store.requestAuthorization(toShare: .init(typesToShare), read: .init(typesToRead))
  }

  var readSwimWorkouts: () async throws -> [HKWorkout]
  private static func _readSwimWorkouts() async throws -> [HKWorkout] {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      return []
    }
    return workouts
  }

  var readMonthWorkoutAverageSeconds: (_ targetDate: Date) async throws -> Int
  private static func _readMonthWorkoutAverageSeconds(_ targetDate: Date) async throws -> Int {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = firstAndLastDateOfMonth(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      throw NSError()
    }

    let totalTime = workouts.reduce(0) { $0 + $1.duration }
    let totalCountOfWorkoutDate = Set(workouts.map { dateFormatter.string(from: $0.startDate) }).count
    if totalCountOfWorkoutDate == 0 {
      return 0
    }

    return Int(totalTime) / totalCountOfWorkoutDate
  }

  var readTargetDateWorkoutSeconds: (_ targetDate: Date) async throws -> Int
  private static func _readTargetDateWorkoutSeconds(_ targetDate: Date) async throws -> Int {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      throw NSError()
    }

    let totalTime = workouts.reduce(0) { $0 + $1.duration }
    return Int(totalTime)
  }

  /// Generated By GPT4
  private static func startAndEndOfDay(for date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> (startDate: Date?, endDate: Date?) {
    // Start date: 해당 날짜의 0시
    let startDate = calendar.startOfDay(for: date)

    // End date: 다음 날의 0시 (즉, 현재 날의 마지막 시간을 포함하는 순간)
    let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)

    return (startDate, endDate)
  }

  /// Generated By GPT4
  private static func firstAndLastDateOfMonth(for date: Date) -> (firstDay: Date?, lastDay: Date?) {
    let calendar = Calendar(identifier: .gregorian)

    // Get the first day of the month
    guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
      return (nil, nil)
    }

    let firstDayOfMonth = monthInterval.start

    // Get the last day of the month by adding the month duration to the start date
    let lastDayOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)

    return (firstDayOfMonth, lastDayOfMonth)
  }

  private static var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }
}

// MARK: DependencyKey

extension SLHealthKitManager: DependencyKey {
  static var liveValue: SLHealthKitManager = .init(
    isHealthDataAvailable: _isHealthDataAvailable,
    authorizationStatus: _authorizationStatus,
    requestAuthorization: _requestAuthorization,
    readSwimWorkouts: _readSwimWorkouts,
    readMonthWorkoutAverageSeconds: _readMonthWorkoutAverageSeconds,
    readTargetDateWorkoutSeconds: _readTargetDateWorkoutSeconds
  )
}

extension DependencyValues {
  var healthKitManager: SLHealthKitManager {
    get { self[SLHealthKitManager.self] }
    set { self[SLHealthKitManager.self] = newValue }
  }
}
