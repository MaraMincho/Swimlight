//
//  Color+.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/16/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import SwiftUI

enum SLColor: String {
  case gray01
  case gray02
  case gray03
  case main01
  case main02
  case main03
  case primaryBG
  case primaryText
  case secondaryBG

  var color: Color {
    switch self {
    case .gray01:
      .gray01
    case .gray02:
      .gray02
    case .gray03:
      .gray03
    case .main01:
      .main01
    case .main02:
      .main02
    case .main03:
      .main03
    case .primaryBG:
      .primaryBG
    case .primaryText:
      .primaryText
    case .secondaryBG:
      .secondaryBG
    }
  }
}
