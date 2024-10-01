# Swimlight
수영기록에 대한 어플리케이션 입니다. (2024.09.16 ~ 18, 30)

# 기술적  도전에 관하여

## UIView + SwiftUI(UIViewControllerRepresentable 100퍼센트 활용하기)

SwiftUI와 UIKit의 생명주기를 Sync 하여, UIKit Comoponent를 100퍼센트 활용하였습니다. 
UICalendarView를 UICalendarViewController로 만들고, 이를 SwiftUIView로 만들었습니다.
그리고 UICalendarView의 업데이트 주기를 SwiftUI 뷰 업데이트 주기에 맞췄습니다.

![alt text](image.png)

![alt text](image-1.png)



## Stroke Meta Data 가져오기

Stroke종류(자유형, 평형, 배영, 접영, 킥판, 기타) Meta Data에 관한 항목이 에플 문서에 자세하게 써있지 않아서 다양한 HealthKit쿼리를 날려보면서 찾았습니다. 
또한 MetaData를 찾고 나서도 스트로크에 관한 정보들을 통해 다시 HealthKit에 질의하는 과정들이 있었습니다.
자료들이 코드를 작성하는데에 오래 걸렸습니다. 

### 완성 화면

![alt text](IMG_0418.jpeg)

### Apple HKSwimmingStrokeStyle

![alt text](image-2.png)

### Code

```swift
 /// Retrieves the distance swam for each stroke style on a specific date.
  /// - Parameter date: The date to retrieve stroke style distances for.
  /// - Returns: A dictionary mapping `SLStrokeStyle` to distance in meters.
  /// - Throws: An error if the retrieval or processing fails.
  var getStrokeStyleDistance: (_ date: Date) async throws -> [SLStrokeStyle: Int]
  private static func _getStrokeStyleDistance(_ targetDate: Date) async throws -> [SLStrokeStyle: Int] {
    // Closure to get distance for a specific time range
    let getDistanceClosure: (_ startDate: Date, _ endDate: Date) async throws -> Int? = { startDate, endDate in
      let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
      let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        datePredicate,
      ])
      let distances = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
        store.execute(
          HKSampleQuery(
            sampleType: HKQuantityType(.distanceSwimming),
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
      guard let distance = distances.first as? HKQuantitySample else {
        return nil
      }
      let targetDistance = Int(distance.quantity.doubleValue(for: .meter()))
      return targetDistance
    }

    // Get swim stroke style samples
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let workoutSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.swimmingStrokeCount),
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

    // Calculate distance for each stroke style
    var distanceByStrokeStyle: [SLStrokeStyle: Int] = [:]
    await workoutSamples.asyncForEach { sample in
      if let strokeStyleInt = sample.metadata?["HKSwimmingStrokeStyle"] as? Int,
         let strokeStyle = SLStrokeStyle(rawValue: strokeStyleInt),
         let targetDistance = try? await getDistanceClosure(sample.startDate, sample.endDate) {
        distanceByStrokeStyle[strokeStyle, default: 0] += targetDistance
      }
    }
    return distanceByStrokeStyle
  }


```



## HeartRate관련 로직

애플 헬스킷에서는 심박수 존에 관한 정보들을 제공하지 않습니다. 그래서 사용자에게 심박수 존을 보여주기 위해서 직접 심박수 Zone에 관한 로직을 생성했습니다. 

### 작동 화면
![alt text](IMG_0418-1.jpeg)

### Code
```swift
// Calculates the time spent in different heart rate zones during swimming workouts on a specific date.
  /// - Parameter date: The date to calculate heart rate zones for.
  /// - Returns: A dictionary mapping `HeartRateZone` to time spent in that zone (in seconds).
  /// - Throws: An error if the calculation fails.
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
      // Handle case when there's no previous data
      guard let targetPrevDate = prevDate else {
        prevDate = sample.startDate
        return
      }

      let interval = sample.startDate.timeIntervalSince(targetPrevDate)
      // Skip if interval is too long or negative
      if interval / 60 > 5 || interval < 0 {
        prevDate = nil
        return
      }
      res[heartRateZone, default: 0] += interval
      prevDate = sample.endDate
    }
    return res
  }
```

더 많은 코드를 헬스킷 코드를 보고 싶다면 `SLHealthKitManager`객체를 참고해주세요! 
