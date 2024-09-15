
//
//  SwimLight
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import SwiftUI
import SwimlightMain

@main
struct SwimLightApp: App {
  init() {
    #if DEBUG
      UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    #endif
  }

  @UIApplicationDelegateAdaptor var delegate: MyAppDelegate
  var body: some Scene {
    WindowGroup {
      SwimlightBuilderView()
    }
  }
}
