//
//  VoiceButton.swift
//  AIChat
//
//  Created by Apple on 5/12/26.

import SwiftUI
import Speech

struct VoiceButton: View {
    
    @ObservedObject var voiceService: VoiceInputService
    var onResult: (String) -> Void
    
    @State private var hasPermission = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        Button {
            handleTap()
        } label: {
            ZStack {
                // Outer pulse ring when recording
                if voiceService.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.25), lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .scaleEffect(1 + voiceService.audioLevel * 0.6)
                        .animation(
                            .easeInOut(duration: 0.1),
                            value: voiceService.audioLevel
                        )
                    
                    Circle()
                        .stroke(Color.red.opacity(0.15), lineWidth: 2)
                        .frame(width: 60, height: 60)
                        .scaleEffect(1 + voiceService.audioLevel * 0.8)
                        .animation(
                            .easeInOut(duration: 0.15),
                            value: voiceService.audioLevel
                        )
                }
                
                // Main mic button
                Circle()
                    .fill(
                        voiceService.isRecording
                        ? Color.red
                        : Color(.systemGray5)
                    )
                    .frame(width: 36, height: 36)
                
                Image(
                    systemName: voiceService.isRecording
                    ? "waveform"
                    : "mic.fill"
                )
                .font(.system(size: 14))
                .foregroundColor(
                    voiceService.isRecording ? .white : .primary
                )
                .symbolEffect(
                    .variableColor,
                    isActive: voiceService.isRecording
                )
            }
        }
        .alert(
            "Permission Required",
            isPresented: $showPermissionAlert
        ) {
            Button("Open Settings") {
                if let url = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow microphone and speech recognition access in Settings.")
        }
        .onAppear {
            checkPermission()
        }
    }
    
    func handleTap() {
        if hasPermission {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            voiceService.toggleRecording {
                // Called automatically when silence detected
                // or user stops recording
                let text = voiceService.transcribedText
                if !text.isEmpty {
                    onResult(text)
                    voiceService.transcribedText = ""
                }
            }
        } else {
            voiceService.requestPermissions { granted in
                if granted {
                    hasPermission = true
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    voiceService.startRecording {
                        let text = voiceService.transcribedText
                        if !text.isEmpty {
                            onResult(text)
                            voiceService.transcribedText = ""
                        }
                    }
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    func checkPermission() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioApplication.shared.recordPermission
        hasPermission = speechStatus == .authorized
            && micStatus == .granted
    }
}
