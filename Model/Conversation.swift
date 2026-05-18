//
//  Conversation.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [StoredMessage]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "New chat",
        messages: [StoredMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Codable version of ChatMessage for saving to disk
struct StoredMessage: Identifiable, Codable {
    let id: UUID
    let role: String // "user" or "assistant"
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
