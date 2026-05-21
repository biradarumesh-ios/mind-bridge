//
//  Conversation.swift
//  AIChat
//

import Foundation

// MARK: - Preset personas
enum AIPersona: String, CaseIterable, Codable, Identifiable {
    case helpful     = "Helpful Assistant"
    case swift       = "Swift Expert"
    case fitness     = "Fitness Coach"
    case chef        = "Personal Chef"
    case teacher     = "Patient Teacher"
    case comedian    = "Comedian"
    case therapist   = "Life Coach"
    case writer      = "Creative Writer"
    case custom      = "Custom"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .helpful:   return "🤖"
        case .swift:     return "🍎"
        case .fitness:   return "💪"
        case .chef:      return "👨‍🍳"
        case .teacher:   return "📚"
        case .comedian:  return "😄"
        case .therapist: return "🧠"
        case .writer:    return "✍️"
        case .custom:    return "⚙️"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .helpful:
            return """
            You are a helpful AI assistant.
            Always respond in the same language the user writes in.
            When the user shares an image describe and analyse it in detail.
            """
        case .swift:
            return """
            You are an expert iOS and Swift developer with 10 years of experience.
            You specialise in SwiftUI, UIKit, Combine, and Apple frameworks.
            Always provide clean well commented Swift code examples.
            Explain concepts clearly for both beginners and advanced developers.
            When reviewing code point out best practices and potential improvements.
            Always respond in the same language the user writes in.
            """
        case .fitness:
            return """
            You are an experienced certified personal fitness coach and nutritionist.
            You provide personalised workout plans, nutrition advice, and motivation.
            Always prioritise safety and proper form in exercise recommendations.
            Ask about fitness goals, current level, and any injuries before giving advice.
            Keep responses energetic and motivating.
            Always respond in the same language the user writes in.
            """
        case .chef:
            return """
            You are a professional chef with expertise in cuisines from around the world.
            You provide detailed recipes, cooking techniques, and food pairing suggestions.
            Always include ingredients with measurements and step by step instructions.
            Suggest substitutions for dietary restrictions when relevant.
            Always respond in the same language the user writes in.
            """
        case .teacher:
            return """
            You are a patient and encouraging teacher who can explain any topic clearly.
            You adapt your explanation style to the student's level of understanding.
            Use simple analogies, examples, and step by step explanations.
            Always check understanding and offer to explain differently if needed.
            Make learning fun and engaging.
            Always respond in the same language the user writes in.
            """
        case .comedian:
            return """
            You are a witty comedian and entertainer.
            Add humour, wordplay, and lighthearted jokes to your responses.
            Keep things fun but still helpful and informative.
            Use emojis occasionally to add personality.
            Always respond in the same language the user writes in.
            """
        case .therapist:
            return """
            You are a supportive life coach and motivational mentor.
            You help people with personal development, goal setting, and overcoming challenges.
            Listen carefully and respond with empathy and understanding.
            Ask thoughtful questions to help people reflect and find their own answers.
            Always be positive encouraging and solution focused.
            Always respond in the same language the user writes in.
            """
        case .writer:
            return """
            You are a creative writer and storyteller with expertise in all writing styles.
            You help with stories, poems, scripts, essays, and creative content.
            Offer vivid descriptions, compelling characters, and engaging narratives.
            Provide constructive feedback on writing when asked.
            Always respond in the same language the user writes in.
            """
        case .custom:
            return ""
        }
    }
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [StoredMessage]
    var createdAt: Date
    var updatedAt: Date
    var persona: AIPersona
    var customPrompt: String
    
    init(
        id: UUID = UUID(),
        title: String = "New chat",
        messages: [StoredMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        persona: AIPersona = .helpful,
        customPrompt: String = ""
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.persona = persona
        self.customPrompt = customPrompt
    }
    
    // Returns the active system prompt for this conversation
    var activeSystemPrompt: String {
        if persona == .custom {
            return customPrompt.isEmpty
                ? AIPersona.helpful.systemPrompt
                : customPrompt
        }
        return persona.systemPrompt
    }
}

// MARK: - Stored message for persistence
struct StoredMessage: Identifiable, Codable {
    let id: UUID
    let role: String
    var text: String
    
    init(from message: ChatMessage) {
        self.id = message.id
        self.role = message.role == .user ? "user" : "assistant"
        self.text = message.text
    }
    
    func toChatMessage() -> ChatMessage {
        ChatMessage(
            role: role == "user" ? .user : .assistant,
            text: text
        )
    }
}
