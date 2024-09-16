//
//  CalendarView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - SLCalendarViewController

final class SLCalendarViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(calendarView)
    calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    calendarView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  let gregorianCalendar = Calendar(identifier: .gregorian)
  lazy var calendarView: UICalendarView = {
    let view = UICalendarView()
    view.tintColor = UIColor(SLColor.main01.color)

    view.calendar = gregorianCalendar
    view.fontDesign = .rounded

    if let fromDate = fromDateComponents().date,
       let toDate = makeTodayDateComponent().date {
      let calendarViewDateRange = DateInterval(start: fromDate, end: toDate)
      view.availableDateRange = calendarViewDateRange
    }

    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private func fromDateComponents() -> DateComponents {
    DateComponents(calendar: gregorianCalendar, year: 2024, month: 1, day: 1)
  }

  private func makeTodayDateComponent() -> DateComponents {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateString = dateFormatter.string(from: .now)
    let components = dateString.split(separator: "-").map { Int($0) ?? 0 }
    
    return DateComponents(
      calendar: gregorianCalendar,
      year: components[safe: 0],
      month: components[safe: 1],
      day: components[safe: 2]
    )
  }
}

// MARK: - SLCalendarView

struct SLCalendarView: UIViewControllerRepresentable {
  weak var calendarDelegate: UICalendarViewDelegate?
  weak var singleSelectDelegate: UICalendarSelectionSingleDateDelegate?
  init(
    calendarDelegate: UICalendarViewDelegate? = nil,
    singleSelectDelegate: UICalendarSelectionSingleDateDelegate? = nil
  ) {
    self.calendarDelegate = calendarDelegate
    self.singleSelectDelegate = singleSelectDelegate
  }

  func makeUIViewController(context _: Context) -> SLCalendarViewController {
    let vc = SLCalendarViewController()
    vc.calendarView.delegate = calendarDelegate
    vc.calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: singleSelectDelegate)
    return vc
  }

  func updateUIViewController(_: SLCalendarViewController, context _: Context) {}

  typealias UIViewControllerType = SLCalendarViewController
}

extension Array {
  subscript(safe index: Int) -> Element? {
    if indices.contains(index) {
      return self[index]
    } else {
      return nil
    }
  }
}
