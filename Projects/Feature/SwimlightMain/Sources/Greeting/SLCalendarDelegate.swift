//
//  SLCalendarDelegate.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/16/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Combine
import UIKit

final class SLCalendarDelegate: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
  var swimWorkoutDates: Set<Date> = .init()
  override init() {
    super.init()
  }

  func dateSelection(_: UICalendarSelectionSingleDate, didSelectDate component: DateComponents?) {
    guard let component else {
      return
    }
    outputPublisher.send(.selectedDate(component))
  }

  func calendarView(
    _: UICalendarView,
    decorationFor dateComponents: DateComponents
  ) -> UICalendarView.Decoration? {
    let day = DateComponents(
      calendar: dateComponents.calendar,
      year: dateComponents.year,
      month: dateComponents.month,
      day: dateComponents.day
    )
    guard let targetDate = day.date else {
      return nil
    }
    return swimWorkoutDates.contains(targetDate) ? makeSwimDataDecoration() : nil
  }

  func makeSwimDataDecoration() -> UICalendarView.Decoration {
    .customView {
      let label = UILabel()
      label.text = "🏊‍♂️"
      label.font = UIFont.systemFont(ofSize: 15)
      return label
    }
  }

  var outputPublisher: PassthroughSubject<Output, Never> = .init()

  enum Output: Equatable {
    case selectedDate(DateComponents)
  }

  func updateSwimWorkoutDates(_ dates: [Date]) {
    let calendar = Calendar(identifier: .gregorian)

    let componentDates = dates.compactMap { calendar.dateComponents([.calendar, .year, .month, .day], from: $0).date }
    swimWorkoutDates = .init(componentDates)
  }
}
