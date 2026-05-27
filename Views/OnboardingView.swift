//
//  OnboardingView.swift
//  AIChat
//

import SwiftUI

// MARK: - Onboarding page model
struct OnboardingPage {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

struct OnboardingView: View {
    
    var onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var animateIcon = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "brain.head.profile",
            iconColor: .blue,
            title: "Meet AIChat",
            subtitle: "Your personal AI assistant",
            description: "Ask anything, get instant answers. AIChat understands your questions and responds like a real conversation."
        ),
        OnboardingPage(
            id: 1,
            icon: "mic.circle.fill",
            iconColor: .purple,
            title: "Talk Naturally",
            subtitle: "Voice conversations in any language",
            description: "Speak in Hindi, English, Tamil or 10 other languages. AIChat listens, understands, and talks back to you."
        ),
        OnboardingPage(
            id: 2,
            icon: "eye.circle.fill",
            iconColor: .orange,
            title: "See and Understand",
            subtitle: "Send images for AI analysis",
            description: "Point your camera at anything — documents, food, objects — and get instant AI powered insights."
        )
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    pages[currentPage].iconColor.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                ZStack{
                    
                    Circle().fill(pages[currentPage].iconColor.opacity(0.8))
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),value: animateIcon)
                    
                   
                    // inner circle
                    
                    Circle().fill(pages[currentPage].iconColor.opacity(0.15)).frame(width: 120, height: 120)
                    
                    
                    //icon
                    
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 54))
                        .foregroundColor(pages[currentPage].iconColor)
                        .symbolEffect(.bounce, value: currentPage)
                 
                }
                .padding(.bottom, 48)
                
                //Text content
                
                VStack(spacing: 12){
                    
                    Text(pages[currentPage].title)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    
                    
                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(pages[currentPage].iconColor)
                        .multilineTextAlignment(.center)
                    
                    Text(pages[currentPage].description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal,32)
                        .padding(.top,4)
                    
                }
                .id(currentPage)
                .animation(.easeInOut(duration: 0.35),value: currentPage)
                
                Spacer()
                
                
                //Page dots
                
                HStack(spacing: 8){
                    
                    ForEach(0..<pages.count, id: \.self){ index in
                        Capsule().fill(
                            index == currentPage ? pages[currentPage].iconColor : Color(.systemGray4)
                        
                        )
                        .frame(width: index == currentPage ? 24 : 8, height: 8 )
                        .animation(.easeOut(duration: 0.35), value: currentPage)
                    }
                      
                }
                .padding(.bottom, 40)
                
                //next button
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        if currentPage < pages.count - 1{
                            currentPage += 1
                            
                        }else{
                            onComplete()
                        }
                        
                    }
                    
                }, label: {
                    HStack(spacing:8){
                        Text(currentPage == pages.count - 1 ? "Get Started" :"Next" )
                            .font(.system(size: 17, weight: .semibold))
                        
                        
                        Image(systemName: currentPage == pages.count - 1
                                                   ? "checkmark"
                                                   : "arrow.right"
                                               )
                                               .font(.system(size: 15, weight: .semibold))
                        
                        
                    }
                    
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(pages[currentPage].iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: pages[currentPage].iconColor.opacity(0.3),radius: 8,  y: 4)
                    .animation(.easeOut(duration: 0.3), value: currentPage)
                    
                })
                .padding(.horizontal, 32)
                
                //Skip button
                if currentPage < pages.count - 1{
                    
                    Button("Skip") {
                        withAnimation {

                              onComplete()
                        }
                      }
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                    
                }
                Spacer()
                    .frame(height: 40)
                
            }
        }
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
