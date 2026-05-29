//
//  SplashView.swift
//  AIChat
//

import SwiftUI

struct SplashView: View {
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var titleOffset: CGFloat = 20
    @State private var taglineOpacity: CGFloat = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var pulseIcon = false
    
    var body: some View {
        ZStack {
            
            // MARK: - Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.1, green: 0.2, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles in background
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: -120, y: -200)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: 150, y: 250)
            
            // MARK: - Main content
            VStack(spacing: 20) {
                
                Spacer()
                
                // Icon with pulse ring
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(
                            Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulseIcon ? 1.15 : 1.0)
                        .opacity(pulseIcon ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: pulseIcon
                        )
                    
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 110, height: 110)
                    
                    // Brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 52))
                        .foregroundColor(.white)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                
 
                Text("AIChat")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
       
                Text("Your personal AI assistant")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(taglineOpacity)
                    .offset(y: taglineOffset)
                
                Spacer()
                
                // Loading dots at bottom
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        LoadingDot(delay: Double(i) * 0.2)
                    }
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations sequence
    func startAnimations() {
        // Icon appears first
        withAnimation(.spring(
            response: 0.6,
            dampingFraction: 0.7
        )) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Title slides up after icon
        withAnimation(
            .easeOut(duration: 0.5)
            .delay(0.3)
        ) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // Tagline slides up after title
        withAnimation(
            .easeOut(duration: 0.5)
            .delay(0.5)
        ) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }
        
        // Start pulse animation
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.3
        ) {
            pulseIcon = true
        }
    }
}

//Loading dot
struct LoadingDot: View {
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.7))
            .frame(width: 8, height: 8)
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.3)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    SplashView()
}
