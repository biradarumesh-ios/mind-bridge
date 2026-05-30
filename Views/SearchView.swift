//
//  SearchView.swift
//  AIChat
//
//  Created by Apple on 5/26/26.
//

import SwiftUI

// MARK: - Search result model
struct SearchResult: Identifiable {
    let id = UUID()
    let conversation: Conversation
    let matchingMessage: StoredMessage?
    let matchType: MatchType
    
    enum MatchType {
        case title
        case message
    }
}

struct SearchView: View {
    
    @ObservedObject var history: HistoryService
    @Environment(\.dismiss) var dismiss
    var onConversationSelected: (UUID) -> Void
    
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - Search results
    var searchResults: [SearchResult] {
        guard !searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else { return [] }
        
        var results: [SearchResult] = []
        
        for conversation in history.conversations {
            
            // Check title match
            if conversation.title.localizedCaseInsensitiveContains(
                searchText
            ) {
                results.append(SearchResult(
                    conversation: conversation,
                    matchingMessage: nil,
                    matchType: .title
                ))
                continue
            }
            
            // Check message content match
            // Find first matching message
            if let matchingMessage = conversation.messages.first(
                where: {
                    $0.text.localizedCaseInsensitiveContains(searchText)
                }
            ) {
                results.append(SearchResult(
                    conversation: conversation,
                    matchingMessage: matchingMessage,
                    matchType: .message
                ))
            }
        }
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Search bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField(
                            "Search conversations and messages",
                            text: $searchText
                        )
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        
                        // Clear button
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - Content
                if searchText.isEmpty {
            
                    recentConversationsView
                } else if searchResults.isEmpty {
                   
                    noResultsView
                } else {
                   
                    searchResultsView
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
           
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.3
            ) {
                isSearchFocused = true
            }
        }
    }
    
    // MARK: - Recent conversations
    var recentConversationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                if history.conversations.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text("No conversations yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Start a new chat to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    
                } else {
                    
                    // Section header
                    Text("Recent conversations")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    
                    ForEach(
                        history.conversations.prefix(8)
                    ) { conversation in
                        RecentConversationRow(
                            conversation: conversation,
                            formattedDate: history.formatDate(
                                conversation.updatedAt
                            )
                        )
                        .onTapGesture {
                            onConversationSelected(conversation.id)
                            dismiss()
                        }
                        
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
    }
    
//Search results
    var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // Results count header
                Text(
                    "\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")"
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                ForEach(searchResults) { result in
                    SearchResultRow(
                        result: result,
                        searchText: searchText,
                        formattedDate: history.formatDate(
                            result.conversation.updatedAt
                        )
                    )
                    .onTapGesture {
                        onConversationSelected(result.conversation.id)
                        dismiss()
                    }
                    
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
    }
    
    // No results
    var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No results for")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent conversation row
struct RecentConversationRow: View {
    let conversation: Conversation
    let formattedDate: String
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "bubble.left")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let lastMessage = conversation.messages.last {
                    Text(lastMessage.text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
}

// MARK: - Search result row
struct SearchResultRow: View {
    let result: SearchResult
    let searchText: String
    let formattedDate: String
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Icon — different for title vs message match
            ZStack {
                Circle()
                    .fill(
                        result.matchType == .title
                        ? Color.blue.opacity(0.1)
                        : Color.purple.opacity(0.1)
                    )
                    .frame(width: 40, height: 40)
                
                Image(
                    systemName: result.matchType == .title
                    ? "bubble.left"
                    : "text.bubble"
                )
                .font(.system(size: 16))
                .foregroundColor(
                    result.matchType == .title ? .blue : .purple
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                
                // Conversation title with highlight
                HighlightedText(
                    text: result.conversation.title,
                    highlight: searchText,
                    font: .system(size: 14, weight: .medium),
                    highlightColor: .blue
                )
                
                // Show matching message preview if match
                // was inside a message not title
                if let message = result.matchingMessage {
                    HighlightedText(
                        text: String(message.text.prefix(100)),
                        highlight: searchText,
                        font: .system(size: 12),
                        highlightColor: .purple
                    )
                    .foregroundColor(.secondary)
                }
                
                // Match type tag
                HStack(spacing: 4) {
                    Image(
                        systemName: result.matchType == .title
                        ? "textformat"
                        : "text.magnifyingglass"
                    )
                    .font(.system(size: 9))
                    
                    Text(
                        result.matchType == .title
                        ? "Title match"
                        : "Message match"
                    )
                    .font(.system(size: 10))
                }
                .foregroundColor(
                    result.matchType == .title
                    ? .blue.opacity(0.8)
                    : .purple.opacity(0.8)
                )
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(result.conversation.messages.count) msgs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
}

// MARK: - Highlighted text view
// Shows search keyword highlighted in results
struct HighlightedText: View {
    let text: String
    let highlight: String
    let font: Font
    let highlightColor: Color
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
                .font(font)
        } else {
            Text(attributedString)
                .font(font)
        }
    }
    
    var attributedString: AttributedString {
        var attributed = AttributedString(text)
        
        // Find and highlight all occurrences
        let lowercasedText = text.lowercased()
        let lowercasedHighlight = highlight.lowercased()
        
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        
        while let range = lowercasedText.range(
            of: lowercasedHighlight,
            range: searchRange
        ) {
            // Convert string range to attributed string range
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].backgroundColor = highlightColor.opacity(0.2)
                attributed[attributedRange].foregroundColor = highlightColor
            }
            searchRange = range.upperBound..<lowercasedText.endIndex
        }
        
        return attributed
    }
}

#Preview {
    SearchView(
        history: HistoryService(),
        onConversationSelected: { _ in }
    )
}
