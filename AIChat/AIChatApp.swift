//
//  AIChatApp.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

//
//  AIChatApp.swift
//  AIChat
//

import SwiftUI

@main
struct AIChatApp: App {
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    // Controls which screen shows
    @State private var appState: AppState = .splash
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                    
                case .splash:
                    SplashView()
                        .transition(
                            .opacity
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 2.5
                            ) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    if hasCompletedOnboarding {
                                        appState = .main
                                    } else {
                                        appState = .onboarding
                                    }
                                }
                            }
                        }
                    
                case .onboarding:
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                            appState = .main
                        }
                    }
                    .transition(.opacity)
                    
                case .main:
                    ContentView()
                        .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - App states
enum AppState {
    case splash
    case onboarding
    case main
}
