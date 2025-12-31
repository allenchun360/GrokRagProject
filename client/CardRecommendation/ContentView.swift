//
//  ContentView.swift
//  CardRecommendation
//
//  Created by Allen Chun on 4/2/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var notifier = NotificationManager.shared

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if authManager.isAuthenticated && !authManager.registeredName {
                    NavigationStack {
                        RegisterNameView()
                        .transition(.opacity)
                    }
                } else if authManager.isAuthenticated && authManager.registeredName && authManager.completed {
                    NavigationStack {
                        HomeView()
                        .transition(.opacity)
                    }
                } else {
                    NavigationStack {
                        LandingView()
                    }
                    .transition(.opacity)
                }
            }
        }
        .overlay(NotifierView())
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.completed)
        .preferredColorScheme(.dark)
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

#Preview {
    ContentView()
}
