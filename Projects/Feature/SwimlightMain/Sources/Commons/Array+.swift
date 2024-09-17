//
//  Array+.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/17/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    var set = Set<Element>()
    return filter { set.insert($0).inserted }
  }
}
