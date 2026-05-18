//
//  VoiceLanguage.swift
//  AIChat
//

import Foundation

enum VoiceLanguage: String, CaseIterable, Identifiable {
    
    case english  = "English"
    case hindi    = "Hindi"
    case marathi  = "Marathi"
    case tamil    = "Tamil"
    case telugu   = "Telugu"
    case french   = "French"
    case spanish  = "Spanish"
    case german   = "German"
    case japanese = "Japanese"
    case arabic   = "Arabic"
    
    var id: String { rawValue }
    
    var flag: String {
        switch self {
        case .english:  return "🇺🇸"
        case .hindi:    return "🇮🇳"
        case .marathi:  return "🇮🇳"
        case .tamil:    return "🇮🇳"
        case .telugu:   return "🇮🇳"
        case .french:   return "🇫🇷"
        case .spanish:  return "🇪🇸"
        case .german:   return "🇩🇪"
        case .japanese: return "🇯🇵"
        case .arabic:   return "🇸🇦"
        }
    }
    
    // Apple Speech Recognition locale
    var languageCode: String {
        switch self {
        case .english:  return "en-US"
        case .hindi:    return "hi-IN"
        case .marathi:  return "mr-IN"
        case .tamil:    return "ta-IN"
        case .telugu:   return "te-IN"
        case .french:   return "fr-FR"
        case .spanish:  return "es-ES"
        case .german:   return "de-DE"
        case .japanese: return "ja-JP"
        case .arabic:   return "ar-SA"
        }
    }
    
    // ElevenLabs language code
    // This tells ElevenLabs which language to speak
    var elevenLabsLanguageCode: String {
        switch self {
        case .english:  return "en"
        case .hindi:    return "hi"
        case .marathi:  return "mr"
        case .tamil:    return "ta"
        case .telugu:   return "te"
        case .french:   return "fr"
        case .spanish:  return "es"
        case .german:   return "de"
        case .japanese: return "ja"
        case .arabic:   return "ar"
        }
    }
    
    // ElevenLabs voice IDs
    // Lily supports all these languages
    // with eleven_turbo_v2_5 model
    var elevenLabsVoiceID: String {
        switch self {
        case .english:
            // Rachel — best English voice
            return "21m00Tcm4TlvDq8ikWAM"
        case .hindi,
             .marathi,
             .tamil,
             .telugu,
             .french,
             .spanish,
             .german,
             .japanese,
             .arabic:
            // Lily — best multilingual voice
            return "pFZP5JQG7iQjIQuC4Bku"
        }
    }
}
