//
//  SideMenuView.swift
//  AIChat
//

import SwiftUI

struct SideMenuView: View {
    
    @ObservedObject var history: HistoryService
    @Binding var selectedConversationID: UUID?
    @Binding var isMenuOpen: Bool
    var onNewChat: () -> Void
    var onSettingsTapped: () -> Void
    var onSearchTapped: () -> Void
    
    @State private var conversationToDelete: Conversation? = nil
    @State private var showDeleteAlert = false
    @State private var showClearAllAlert = false
    
    // Rename states
    @State private var conversationToRename: Conversation? = nil
    @State private var showRenameAlert = false
    @State private var renameText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Menu header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Assistant")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Chat history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Search button
                    Button {
                        onSearchTapped()
                        withAnimation {
                            isMenuOpen = false
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    // New chat button
                    Button {
                        onNewChat()
                        withAnimation {
                            isMenuOpen = false
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            
            Divider()
            
            // MARK: - Conversations list
            if history.conversations.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No chats yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start a new conversation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(history.conversations) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                isSelected: selectedConversationID == conversation.id,
                                formattedDate: history.formatDate(
                                    conversation.updatedAt
                                )
                            )
                            .onTapGesture {
                                selectedConversationID = conversation.id
                                withAnimation {
                                    isMenuOpen = false
                                }
                            }
                            // MARK: - Swipe actions
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                // Delete button
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                // Rename button
                                Button {
                                    conversationToRename = conversation
                                    renameText = conversation.title
                                    showRenameAlert = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            // MARK: - Long press context menu
                            .contextMenu {
                                // Rename option
                                Button {
                                    conversationToRename = conversation
                                    renameText = conversation.title
                                    showRenameAlert = true
                                } label: {
                                    Label(
                                        "Rename",
                                        systemImage: "pencil"
                                    )
                                }
                                
                                // Select option
                                Button {
                                    selectedConversationID = conversation.id
                                    withAnimation {
                                        isMenuOpen = false
                                    }
                                } label: {
                                    Label(
                                        "Open chat",
                                        systemImage: "bubble.left"
                                    )
                                }
                                
                                Divider()
                                
                                // Delete option
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showDeleteAlert = true
                                } label: {
                                    Label(
                                        "Delete",
                                        systemImage: "trash"
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Divider()
            
            // MARK: - Bottom buttons
            VStack(spacing: 0) {
                
                Button {
                    onSettingsTapped()
                    withAnimation {
                        isMenuOpen = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        Text("Settings")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                
                Button {
                    showClearAllAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Clear all history")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
        
        // MARK: - Rename alert
        .alert(
            "Rename conversation",
            isPresented: $showRenameAlert
        ) {
            TextField("Conversation title", text: $renameText)
            
            Button("Save") {
                if let conv = conversationToRename {
                    history.renameConversation(
                        conv.id,
                        newTitle: renameText
                    )
                }
                conversationToRename = nil
                renameText = ""
            }
            Button("Cancel", role: .cancel) {
                conversationToRename = nil
                renameText = ""
            }
        } message: {
            Text("Enter a new name for this conversation")
        }
        
        // MARK: - Delete single conversation alert
        .alert(
            "Delete conversation?",
            isPresented: $showDeleteAlert
        ) {
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let conv = conversationToDelete {
                    withAnimation {
                        history.deleteConversation(conv.id)
                        if selectedConversationID == conv.id {
                            selectedConversationID = nil
                        }
                    }
                    conversationToDelete = nil
                }
            }
        } message: {
            Text(
                (conversationToDelete?.title ?? "This chat") +
                " will be permanently deleted."
            )
        }
        
        // MARK: - Clear all alert
        .alert(
            "Clear all history?",
            isPresented: $showClearAllAlert
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Clear all", role: .destructive) {
                withAnimation {
                    history.clearAll()
                    selectedConversationID = nil
                    isMenuOpen = false
                }
            }
        } message: {
            Text(
                "All \(history.conversations.count) conversations will be permanently deleted. This cannot be undone."
            )
        }
    }
}

// MARK: - Single conversation row
struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let formattedDate: String
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: "bubble.left")
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Message count badge
            if !conversation.messages.isEmpty {
                Text("\(conversation.messages.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isSelected
            ? Color.blue.opacity(0.08)
            : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
