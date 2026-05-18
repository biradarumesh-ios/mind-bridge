//
//  SpeechService.swift
//  AIChat
//

import Foundation
import AVFoundation

class SpeechService: ObservableObject {
    
    @Published var isSpeaking = false
    @Published var speakingMessageID: UUID? = nil
    @Published var selectedLanguage: VoiceLanguage = .english
    @Published var isLoading = false
    
    private let apiKey = "sk_392dc5e60f2f2b2283a0e9e53eae395b8df9f48e5efddae8"
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    
    private var audioPlayer: AVAudioPlayer?
    private var audioDelegate: AudioDelegate?
    
    // Apple TTS fallback
    private let synthesizer = AVSpeechSynthesizer()
    private var fallbackDelegate: FallbackDelegate?
    
    init() {
        fallbackDelegate = FallbackDelegate(service: self)
        synthesizer.delegate = fallbackDelegate
    }
    
    // MARK: - Main speak function
    func speak(text: String, messageID: UUID) {
        
        if speakingMessageID == messageID {
            stop()
            return
        }
        
        stop()
        speakingMessageID = messageID
        isSpeaking = true
        isLoading = true
        
        print("🗣️ Speaking in: \(selectedLanguage.rawValue)")
        print("📝 Text: \(text.prefix(100))")
        
        Task {
            do {
                let audioData = try await fetchElevenLabsTTS(text: text)
                await MainActor.run {
                    isLoading = false
                    playAudio(audioData, messageID: messageID)
                }
            } catch {
                print("❌ ElevenLabs error: \(error)")
                await MainActor.run {
                    isLoading = false
                    // Fallback to Apple TTS
                    fallbackToAppleTTS(
                        text: text,
                        messageID: messageID
                    )
                }
            }
        }
    }
    
    // MARK: - Fetch from ElevenLabs
    private func fetchElevenLabsTTS(
        text: String
    ) async throws -> Data {
        
        let voiceID = selectedLanguage.elevenLabsVoiceID
        
        // Use turbo model for faster response
        // eleven_turbo_v2_5 supports 32 languages
        // including Hindi, Tamil, Telugu etc
        let modelID = "eleven_turbo_v2_5"
        
        guard let url = URL(
            string: "\(baseURL)/\(voiceID)?output_format=mp3_44100_128"
        ) else {
            throw TTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            apiKey,
            forHTTPHeaderField: "xi-api-key"
        )
        request.setValue(
            "audio/mpeg",
            forHTTPHeaderField: "Accept"
        )
        
        let cleanText = cleanMarkdown(text)
        
        // language code tells ElevenLabs
        // which language to speak in
        let body: [String: Any] = [
            "text": cleanText,
            "model_id": modelID,
            "language_code": selectedLanguage.elevenLabsLanguageCode,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        ]
        
        print("📤 ElevenLabs request:")
        print("   Voice ID: \(voiceID)")
        print("   Model: \(modelID)")
        print("   Language: \(selectedLanguage.elevenLabsLanguageCode)")
        
        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 ElevenLabs status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                // Print error response for debugging
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorStr)")
                }
                throw TTSError.apiError(httpResponse.statusCode)
            }
        }
        
        print("✅ Audio data received: \(data.count) bytes")
        return data
    }
    
    // MARK: - Play audio
    private func playAudio(
        _ data: Data,
        messageID: UUID
    ) {
        do {
            // Deactivate first to reset session
            try? AVAudioSession.sharedInstance().setActive(false)
            
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            
            audioDelegate = AudioDelegate(service: self)
            audioPlayer?.delegate = audioDelegate
            
            let success = audioPlayer?.play() ?? false
            print(success ? "▶️ Audio playing" : "❌ Audio failed to play")
            
        } catch {
            print("❌ AVAudioPlayer error: \(error)")
            isSpeaking = false
            speakingMessageID = nil
        }
    }
    
    // MARK: - Apple TTS fallback
    private func fallbackToAppleTTS(
        text: String,
        messageID: UUID
    ) {
        print("⚠️ Using Apple TTS for \(selectedLanguage.rawValue)")
        
        let cleanText = cleanMarkdown(text)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Use correct language voice
        utterance.voice = AVSpeechSynthesisVoice(
            language: selectedLanguage.languageCode
        )
        
        if utterance.voice == nil {
            // Fallback to English if language not found
            utterance.voice = AVSpeechSynthesisVoice(
                language: "en-US"
            )
            print("⚠️ Language voice not found — using English")
        }
        
        speakingMessageID = messageID
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // MARK: - Stop
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioDelegate = nil
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        isSpeaking = false
        isLoading = false
        speakingMessageID = nil
        
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
    
    // MARK: - Clean markdown
    private func cleanMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "---", with: "")
            .replacingOccurrences(of: ">>>", with: "")
    }
}

// MARK: - Errors
enum TTSError: Error {
    case invalidURL
    case apiError(Int)
    case parseError
}

// MARK: - Audio player delegate
class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    weak var service: SpeechService?
    
    init(service: SpeechService) {
        self.service = service
    }
    
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        DispatchQueue.main.async {
            self.service?.isSpeaking = false
            self.service?.speakingMessageID = nil
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
            print("✅ Playback finished")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        print("❌ Audio decode error: \(String(describing: error))")
        DispatchQueue.main.async {
            self.service?.isSpeaking = false
            self.service?.speakingMessageID = nil
        }
    }
}

// MARK: - Apple TTS delegate
class FallbackDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var service: SpeechService?
    
    init(service: SpeechService) {
        self.service = service
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            self.service?.isSpeaking = false
            self.service?.speakingMessageID = nil
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            self.service?.isSpeaking = false
            self.service?.speakingMessageID = nil
        }
    }
}
