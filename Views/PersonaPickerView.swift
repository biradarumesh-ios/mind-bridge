//
//  PersonaPickerView.swift
//  AIChat
//
//  Created by Apple on 5/21/26.

import SwiftUI

struct PersonaPickerView: View {
    
    @Binding var selectedPersona: AIPersona
    @Binding var customPrompt: String
    var onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var tempCustomPrompt: String = ""
    
    var body: some View {
        NavigationView {
            List {
                
                // MARK: - Preset personas
                Section {
                    ForEach(AIPersona.allCases.filter {
                        $0 != .custom
                    }) { persona in
                        PersonaRow(
                            persona: persona,
                            isSelected: selectedPersona == persona
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedPersona = persona
                            }
                        }
                    }
                } header: {
                    Text("Preset personas")
                } footer: {
                    Text("Choose a personality for your AI assistant in this conversation")
                }
                
                // MARK: - Custom persona
                Section {
                    PersonaRow(
                        persona: .custom,
                        isSelected: selectedPersona == .custom
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedPersona = .custom
                        }
                    }
                    
                    // Show text editor when custom selected
                    if selectedPersona == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom instructions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $tempCustomPrompt)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color(.systemGray4),
                                            lineWidth: 0.5
                                        )
                                )
                            
                            Text("Example: You are a financial advisor who explains investments in simple terms.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Custom persona")
                } footer: {
                    Text("Write your own instructions to fully customise the AI behaviour")
                }
                
                // MARK: - Preview section
                if selectedPersona != .custom {
                    Section {
                        Text(selectedPersona.systemPrompt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } header: {
                        Text("System prompt preview")
                    }
                }
            }
            .navigationTitle("AI Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if selectedPersona == .custom {
                            customPrompt = tempCustomPrompt
                        }
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                tempCustomPrompt = customPrompt
            }
        }
    }
}

// MARK: - Persona row
struct PersonaRow: View {
    let persona: AIPersona
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Emoji icon
            ZStack {
                Circle()
                    .fill(
                        isSelected
                        ? Color.blue.opacity(0.12)
                        : Color(.systemGray6)
                    )
                    .frame(width: 40, height: 40)
                Text(persona.emoji)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(persona.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
