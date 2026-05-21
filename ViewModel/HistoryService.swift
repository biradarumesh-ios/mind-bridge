//
//  HistoryService.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//


import Foundation

class HistoryService: ObservableObject {
    
    @Published var conversations: [Conversation] = []
    
    private let saveKey = "saved_conversations"
    
    init() {
        load()
    }
    
    // MARK: - Load from disk
    func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode(
                [Conversation].self,
                from: data
              )
        else { return }
        conversations = decoded.sorted {
            $0.updatedAt > $1.updatedAt
        }
    }
    
    // MARK: - Save to disk
    func save() {
        guard let encoded = try? JSONEncoder().encode(conversations) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: saveKey)
    }
    
    // MARK: - Create new conversation
    func createConversation() -> Conversation {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        save()
        return conversation
    }
    
    // MARK: - Update existing conversation
    func updateConversation(
        _ id: UUID,
        messages: [ChatMessage]
    ) {
        guard let index = conversations.firstIndex(
            where: { $0.id == id }
        ) else { return }
        
        // Update messages
        conversations[index].messages = messages.map {
            StoredMessage(from: $0)
        }
        conversations[index].updatedAt = Date()
        
        // Auto generate title from first user message
        if conversations[index].title == "New chat",
           let firstUser = messages.first(where: {
               $0.role == .user
           }) {
            let title = String(firstUser.text.prefix(30))
            conversations[index].title = title.isEmpty
                ? "New chat" : title
        }
        
        // Sort by most recent
        conversations.sort { $0.updatedAt > $1.updatedAt }
        save()
    }
    
    // MARK: - Delete conversation
    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        save()
    }
    
    // MARK: - Rename conversation
    func renameConversation(_ id: UUID, newTitle: String) {
        guard let index = conversations.firstIndex(
            where: { $0.id == id }
        ) else { return }
        
        let trimmed = newTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !trimmed.isEmpty else { return }
        
        conversations[index].title = trimmed
        save()
    }
    
    // MARK: - Clear all history
    func clearAll() {
        conversations.removeAll()
        save()
    }
    
    // MARK: - Format date for display
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
