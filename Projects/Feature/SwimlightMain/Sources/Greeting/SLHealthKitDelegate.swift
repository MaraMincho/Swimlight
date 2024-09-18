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

  var readMonthWorkoutAverageDistance: (_ date: Date) async throws -> Int
  private static func _readMonthWorkoutAverageDistance(_ date: Date) async throws -> Int {
    let (startDate, endDate) = firstAndLastDateOfMonth(for: date)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.distanceSwimming),
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

    guard let quantity = samples as? [HKQuantitySample] else {
      throw NSError()
    }
    let totalCountOfWorkoutDate = Set(quantity.map { dateFormatter.string(from: $0.startDate) }).count
    if totalCountOfWorkoutDate == 0 {
      return 10
    }
    return quantity.map { Int($0.quantity.doubleValue(for: .meter())) }.reduce(0) { $0 + $1 } / totalCountOfWorkoutDate
  }

  var readTargetDateDistance: (_ date: Date) async throws -> Int
  private static func _readTargetDateDistance(_ date: Date) async throws -> Int {
    let (startDate, endDate) = startAndEndOfDay(for: date)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.distanceSwimming),
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

    guard let quantity = samples as? [HKQuantitySample] else {
      throw NSError()
    }
    return quantity.map { Int($0.quantity.doubleValue(for: .meter())) }.reduce(0) { $0 + $1 }
  }

  private static func getTargetDateSwimmingHeartRateSamples(_ targetDate: Date) async throws -> [[HKQuantitySample]] {
    // 수영 WorkoutData 구하기
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let workoutSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: swimWorkoutPredicate,
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

    guard let workoutSamples = workoutSamples as? [HKWorkout] else {
      throw NSError()
    }

    var heartRateSamples: [[HKQuantitySample]] = []
    for workout in workoutSamples {
      var currentSamples: [HKQuantitySample] = []
      let heartRatePredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
      let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
        let query = HKSampleQuery(
          sampleType: HKQuantityType(.heartRate),
          predicate: heartRatePredicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: true)]
        ) { _, results, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let samples = results as? [HKQuantitySample] else {
            continuation.resume(returning: [])
            return
          }
          continuation.resume(returning: samples)
        }
        store.execute(query)
      }
      currentSamples.append(contentsOf: samples)
      heartRateSamples.append(currentSamples)
    }
    return heartRateSamples
  }

  var calculateTimeInHeartRateZones: (_ date: Date) async throws -> [HeartRateZone: TimeInterval]
  private static func _calculateTimeInHeartRateZones(targetDate: Date) async throws -> [HeartRateZone: TimeInterval] {
    let heartRateSamples = try await getTargetDateSwimmingHeartRateSamples(targetDate).flatMap { $0 }

    let zoneManager = HeartRateZoneManager(maximumHeartRate: 190)
    var res: [HeartRateZone: Double] = [:]

    var prevDate: Date?
    heartRateSamples.forEach { sample in

      let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
      let heartRate = Int(sample.quantity.doubleValue(for: heartRateUnit))
      guard let heartRateZone = zoneManager.getHeartRateZone(for: heartRate) else {
        return
      }
      // 과거 데이터가 없을 경우
      guard let targetPrevDate = prevDate else {
        prevDate = sample.startDate
        return
      }

      let interval = sample.startDate.timeIntervalSince(targetPrevDate)
      if interval / 60 > 5 || interval < 0 {
        prevDate = nil
        return
      }
      res[heartRateZone, default: 0] += interval
      prevDate = sample.endDate
    }
    return res
  }

  var getHeartRateSamples: (_ date: Date) async throws -> HeartRateChartProperty
  private static func _getHeartRateSamples(_ targetDate: Date) async throws -> HeartRateChartProperty {
    let samples = try await getTargetDateSwimmingHeartRateSamples(targetDate)
    let flatSamples = samples.flatMap { $0 }
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    let samplesHeartRate = flatSamples.map { (Int($0.quantity.doubleValue(for: heartRateUnit)), $0.startDate) }
    let maximumHeartRate = samplesHeartRate.max(by: { $0.0 < $1.0 })?.0 ?? 100 // TODO: Default Value 수정
    let minimumHeartRate = samplesHeartRate.min(by: { $0.0 < $1.0 })?.0 ?? 180 // TODO: Default Value 수정
    var items: [HeartRateChartElement] = []
    let totalSeconds = samples
      .map { sample in
        guard let currentStartDate = sample.first?.startDate,
              let currentEndDate = sample.last?.startDate
        else {
          return 0
        }
        return Int(currentEndDate.timeIntervalSince(currentStartDate))
      }
      .reduce(0) { $0 + $1 }

    var countOfCheckedHeartRate = 0
    let heartRateWeightSum = samples
      .map { samples in
        var prevDate: Date? = nil
        var currentHeartRateWeightSum = 0

        samples.forEach { sample in
          guard let currentPrevDate = prevDate else {
            prevDate = sample.startDate
            return
          }
          let currentHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
          let interval = Double(sample.startDate.timeIntervalSince(currentPrevDate))

          countOfCheckedHeartRate += 1
          currentHeartRateWeightSum += Int(currentHeartRate * interval)
          items.append(.init(interval: interval, y: Int(currentHeartRate)))

          prevDate = sample.startDate
        }
        return currentHeartRateWeightSum
      }
      .reduce(0) { $0 + $1 }
    let averageHeartRage = heartRateWeightSum / totalSeconds
    let (totalHour, totalMinute, _) = formatTimeIntervalToHMS(totalSeconds)

    return .init(
      totalHour: totalHour,
      totalMinute: totalMinute,
      averageHeartRate: averageHeartRage,
      maximumHeartRate: maximumHeartRate,
      minimumHeartRate: minimumHeartRate,
      items: items
    )
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

// MARK: - HeartRateChartProperty

struct HeartRateChartProperty {
  let totalHour: Int
  let totalMinute: Int
  let averageHeartRate: Int
  let maximumHeartRate: Int
  let minimumHeartRate: Int
  let items: [HeartRateChartElement]
}

// MARK: - HeartRateChartElement

struct HeartRateChartElement {
  let interval: Double
  let y: Int
}

// MARK: - SLHealthKitManager + DependencyKey

extension SLHealthKitManager: DependencyKey {
  static var liveValue: SLHealthKitManager = .init(
    isHealthDataAvailable: _isHealthDataAvailable,
    authorizationStatus: _authorizationStatus,
    requestAuthorization: _requestAuthorization,
    readSwimWorkouts: _readSwimWorkouts,
    readMonthWorkoutAverageSeconds: _readMonthWorkoutAverageSeconds,
    readTargetDateWorkoutSeconds: _readTargetDateWorkoutSeconds,
    readMonthWorkoutAverageDistance: _readMonthWorkoutAverageDistance,
    readTargetDateDistance: _readTargetDateDistance,
    calculateTimeInHeartRateZones: _calculateTimeInHeartRateZones,
    getHeartRateSamples: _getHeartRateSamples
  )
}

extension DependencyValues {
  var healthKitManager: SLHealthKitManager {
    get { self[SLHealthKitManager.self] }
    set { self[SLHealthKitManager.self] = newValue }
  }
}
