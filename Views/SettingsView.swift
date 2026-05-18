//
//  SettingsView.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var history: HistoryService
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("userName") var userName = ""
    @AppStorage("aiPersonality") var aiPersonality = "Helpful"
    @State private var showClearConfirm = false
    @State private var editingName = false
    
    let personalities = ["Helpful", "Friendly", "Professional", "Concise"]
    
    var body: some View {
        NavigationView {
            List {
                
                // MARK: - Profile section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text(userName.isEmpty ? "?" : String(userName.prefix(1)).uppercased())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if userName.isEmpty {
                                Text("Set your name")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            } else {
                                Text(userName)
                                    .font(.headline)
                            }
                            Text("AI Chat User")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            editingName = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Profile")
                }
                
                // MARK: - Appearance section
                Section {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark mode", systemImage: "moon.fill")
                    }
                    .tint(.blue)
                } header: {
                    Text("Appearance")
                }
                
                // MARK: - AI personality section
                Section {
                    Picker("AI personality", selection: $aiPersonality) {
                        ForEach(personalities, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("AI behaviour")
                } footer: {
                    Text("Changes how the AI responds to you")
                }
                
                // MARK: - Stats section
                Section {
                    HStack {
                        Label(
                            "Total conversations",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        Spacer()
                        Text("\(history.conversations.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(
                            "Total messages",
                            systemImage: "text.bubble"
                        )
                        Spacer()
                        Text("\(history.conversations.flatMap { $0.messages }.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Stats")
                }
                
                // MARK: - Data section
                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label(
                            "Clear all chat history",
                            systemImage: "trash"
                        )
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will permanently delete all your conversations")
                }
                
                // MARK: - About section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Model", systemImage: "cpu")
                        Spacer()
                        Text("Nemotron Vision")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Powered by", systemImage: "bolt")
                        Spacer()
                        Text("OpenRouter")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("Clear all history?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear all", role: .destructive) {
                    history.clearAll()
                }
            } message: {
                Text("This will permanently delete all your conversations and cannot be undone.")
            }
            .alert("Your name", isPresented: $editingName) {
                TextField("Enter your name", text: $userName)
                Button("Save") {}
                Button("Cancel", role: .cancel) {}
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
