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

  var calendarView: UICalendarView = {
    let view = UICalendarView()
    view.tintColor = UIColor(SLColor.main01.color)

    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
}

// MARK: - SLCalendarView

struct SLCalendarView: UIViewControllerRepresentable {
  func makeUIViewController(context _: Context) -> SLCalendarViewController {
    let vc = SLCalendarViewController()
    return vc
  }

  func updateUIViewController(_: SLCalendarViewController, context _: Context) {}

  typealias UIViewControllerType = SLCalendarViewController
}
