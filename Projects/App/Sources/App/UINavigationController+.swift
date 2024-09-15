//
//  UINavigationController+.swift
//  SwimLight
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import UIKit

extension UINavigationController: ObservableObject, UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationBar.isHidden = true
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }
}
