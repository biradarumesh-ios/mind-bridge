//
//  ChatBubble.swift
//  AIChat
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    @ObservedObject var speechService: SpeechService
    
    @State private var showCopied = false
    
    var isUser: Bool {
        message.role == .user
    }
    
    var isSpeakingThis: Bool {
        speechService.speakingMessageID == message.id
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isUser { Spacer() }
            
            ZStack(alignment: .top) {
                
                VStack(
                    alignment: isUser ? .trailing : .leading,
                    spacing: 6
                ) {
                    
                    // Image if present
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: UIScreen.main.bounds.width * 0.65,
                                maxHeight: 200
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Text with markdown for AI
                    if !message.text.isEmpty {
                        MarkdownBubble(
                            text: message.text,
                            isUser: isUser
                        )
                    }
                }
                
                // Copied toast
                if showCopied {
                    Text("Copied!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(y: -30)
                        .transition(.opacity)
                }
            }
            .onLongPressGesture {
                copyMessage()
            }
            
            // Speaker button only on AI messages
            if !isUser && !message.text.isEmpty {
                Button {
                    speechService.speak(
                        text: message.text,
                        messageID: message.id
                    )
                } label: {
                    ZStack {
                        // Loading indicator while fetching voice
                        if speechService.isLoading
                            && speechService.speakingMessageID == message.id {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 28, height: 28)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        } else {
                            Image(
                                systemName: isSpeakingThis
                                ? "speaker.wave.2.fill"
                                : "speaker.wave.2"
                            )
                            .font(.system(size: 14))
                            .foregroundColor(
                                isSpeakingThis ? .blue : .secondary
                            )
                            .padding(6)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                            .scaleEffect(isSpeakingThis ? 1.15 : 1.0)
                            .animation(
                                isSpeakingThis
                                ? .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                : .default,
                                value: isSpeakingThis
                            )
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            
            if !isUser { Spacer() }
        }
        .padding(.horizontal, 12)
    }
    
    func copyMessage() {
        UIPasteboard.general.string = message.text
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }
}
