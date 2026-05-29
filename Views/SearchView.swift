//
//  SearchView.swift
//  AIChat
//
//  Created by Apple on 5/29/26.
//

//
//  SearchView.swift
//  AIChat
//

import SwiftUI

struct SearchView: View {
    
    @ObservedObject var history: HistoryService
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    
    // Filter conversations based on search text
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return history.conversations
        }
        return history.conversations.filter { conversation in
            conversation.title.localizedCaseInsensitiveContains(searchText) ||
            // Search in messages
            conversation.messages.contains {
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredConversations) { conversation in
                    Text(conversation.title)
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $searchText,
                prompt: "Search conversations"
            )
        }
    }
}

#Preview {
    SearchView(history: HistoryService())
}
