//
//  AppDelegate.swift
//  SwimLight
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import SwiftUI
import SwimlightMain
import UIKit

class MyAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    Font.registerFont()
    registerFirebase()
    return true
  }

  func registerFirebase() {
    #if !DEBUG
      FirebaseApp.configure()
    #endif
  }

  func application(
    _: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = MySceneDelegate.self
    return sceneConfig
  }
}
