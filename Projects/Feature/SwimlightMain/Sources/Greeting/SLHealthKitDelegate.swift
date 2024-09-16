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
    let startDate = DateComponents(
      calendar: Calendar(
        identifier: .gregorian
      ),
      year: 2024,
      month: 1,
      day: 1
    ).date ?? .now.addingTimeInterval(-(60 * 60 * 24 * 10))
    let datePredicate = HKQuery.predicateForSamples(withStart: .now.addingTimeInterval(-(60 * 60 * 24 * 10)), end: .now, options: .strictStartDate)
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

            print(samples)
            guard let samples else {
              print("*** Invalid State: This can only fail if there was an error. ***")
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
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd, hh-mm-ss"
    workouts.forEach { print(dateFormatter.string(from: $0.startDate)) }
    return workouts
  }

  static func readWorkouts() async throws -> [HKQuantitySample]? {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)

    let datePredicate = HKQuery.predicateForSamples(withStart: .now.addingTimeInterval(-(60 * 60 * 24 * 10)), end: .now, options: .strictStartDate)

    // 두 가지 조건을 AND로 결합
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
    ])

    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.heartRate),
          predicate: datePredicate,
          limit: Int(HKObjectQueryNoLimit),
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }

            guard let samples else {
              fatalError("*** Invalid State: This can only fail if there was an error. ***")
            }

            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKQuantitySample] else {
      return nil
    }

    workouts.forEach { workout in
      let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
      print(Int(workout.quantity.doubleValue(for: heartRateUnit)), workout.quantityType, workout.startDate, workout.endDate)
    }
    return workouts
  }
}

// MARK: DependencyKey

extension SLHealthKitManager: DependencyKey {
  static var liveValue: SLHealthKitManager = .init(
    isHealthDataAvailable: _isHealthDataAvailable,
    authorizationStatus: _authorizationStatus,
    requestAuthorization: _requestAuthorization,
    readSwimWorkouts: _readSwimWorkouts
  )
}

extension DependencyValues {
  var healthKitManager: SLHealthKitManager {
    get { self[SLHealthKitManager.self] }
    set { self[SLHealthKitManager.self] = newValue }
  }
}
