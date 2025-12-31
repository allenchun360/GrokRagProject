//
//  CardRecommendationApp.swift
//  CardRecommendation
//
//  Created by Allen Chun on 4/2/25.
//

import SwiftUI
import UIKit

@main
struct CardRecommendationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject var authManager = AuthManager()

    init() {
        // Set delaysContentTouches to false for all UIScrollViews globally
        UIScrollView.appearance().delaysContentTouches = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(authManager)
            .onAppear {
                // Lock the screen orientation to portrait
                AppDelegate.orientationLock = .portrait
            }
        }
    }
}

// Create an AppDelegate class to handle orientation locking
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
