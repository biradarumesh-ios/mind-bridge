//
//  VoiceInputService.swift
//  AIChat
//

import Foundation
import Speech
import AVFoundation

class VoiceInputService: ObservableObject {
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage = ""
    @Published var audioLevel: CGFloat = 0
    
    // Selected language — synced with SpeechService
    var selectedLanguage: VoiceLanguage = .english {
        didSet {
            // Recreate recognizer when language changes
            setupRecognizer()
        }
    }
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var lastTranscriptionTime: Date = Date()
    
    init() {
        setupRecognizer()
    }
    
    // MARK: - Setup recognizer for selected language
    private func setupRecognizer() {
        speechRecognizer = SFSpeechRecognizer(
            locale: Locale(identifier: selectedLanguage.languageCode)
        )
        print("🎤 Speech recognizer set to: \(selectedLanguage.languageCode)")
    }
    
    // MARK: - Request permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            completion(granted)
                        }
                    }
                default:
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Start recording
    func startRecording(onSilence: @escaping () -> Void) {
        
        transcribedText = ""
        errorMessage = ""
        
        // Check recognizer is available for selected language
        guard let recognizer = speechRecognizer else {
            errorMessage = "Speech recognizer not available"
            fallbackToEnglish(onSilence: onSilence)
            return
        }
        
        guard recognizer.isAvailable else {
            errorMessage = "\(selectedLanguage.rawValue) not available"
            print("⚠️ \(selectedLanguage.rawValue) recognition not available — falling back to English")
            fallbackToEnglish(onSilence: onSilence)
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )
            try audioSession.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Enable on device recognition if available
            // Works offline for supported languages
            if recognizer.supportsOnDeviceRecognition {
                recognitionRequest.requiresOnDeviceRecognition = true
                print("✅ Using on-device recognition for \(selectedLanguage.rawValue)")
            }
            
            let inputNode = audioEngine.inputNode
            
            recognitionTask = recognizer.recognitionTask(
                with: recognitionRequest
            ) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                        self.lastTranscriptionTime = Date()
                        print("🎤 Heard: \(self.transcribedText)")
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    DispatchQueue.main.async {
                        self.stopRecording()
                        onSilence()
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: recordingFormat
            ) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                
                // Audio level for mic animation
                guard let channelData = buffer.floatChannelData?[0] else {
                    return
                }
                let frameLength = Int(buffer.frameLength)
                let rms = sqrt(
                    (0..<frameLength).map {
                        pow(channelData[$0], 2)
                    }.reduce(0, +) / Float(frameLength)
                )
                DispatchQueue.main.async {
                    self?.audioLevel = CGFloat(min(rms * 20, 1.0))
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                print("▶️ Recording started in \(self.selectedLanguage.rawValue)")
            }
            
            startSilenceTimer(onSilence: onSilence)
            
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    // MARK: - Fallback to English if selected language fails
    private func fallbackToEnglish(onSilence: @escaping () -> Void) {
        print("⚠️ Falling back to English recognition")
        speechRecognizer = SFSpeechRecognizer(
            locale: Locale(identifier: "en-US")
        )
        startRecording(onSilence: onSilence)
    }
    
    // MARK: - Silence timer
    private func startSilenceTimer(onSilence: @escaping () -> Void) {
        silenceTimer?.invalidate()
        lastTranscriptionTime = Date()
        
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            
            let silence = Date().timeIntervalSince(
                self.lastTranscriptionTime
            )
            
            if silence > 2.0
                && !self.transcribedText.isEmpty
                && self.isRecording {
                DispatchQueue.main.async {
                    self.stopRecording()
                    onSilence()
                }
            }
        }
    }
    
    // MARK: - Stop recording
    func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioLevel = 0
            print("⏹️ Recording stopped")
        }
    }
    
    // MARK: - Toggle
    func toggleRecording(onSilence: @escaping () -> Void) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(onSilence: onSilence)
        }
    }
    
    // MARK: - Check if language is supported
    func isLanguageSupported(_ language: VoiceLanguage) -> Bool {
        let recognizer = SFSpeechRecognizer(
            locale: Locale(identifier: language.languageCode)
        )
        return recognizer?.isAvailable ?? false
    }
}
