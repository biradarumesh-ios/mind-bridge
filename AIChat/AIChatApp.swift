//
//  AIChatApp.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

import SwiftUI

@main
struct AIChatApp: App {
    
    @AppStorage ("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            
            if hasCompletedOnboarding {
                ContentView()
            }else{
                
                OnboardingView{
                    hasCompletedOnboarding = true
                }
                
            }
        }
    }
}
