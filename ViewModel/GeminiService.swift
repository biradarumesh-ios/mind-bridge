//
//  GeminiService.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

import Foundation

class GeminiService: ObservableObject {
    
    // Your OpenRouter API key
    private let apiKey = "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"
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    func sendMessage(
        messages: [ChatMessage],
        onToken: @escaping (String) -> Void,
        onComplete: @escaping () -> Void
    ) async {
        
        guard let url = URL(string: baseURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("AIChat iOS App", forHTTPHeaderField: "X-Title")
        
        // Convert messages to OpenAI format
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": """
            You are a helpful AI assistant with vision capabilities.
            Always respond in the same language the user writes or speaks in.
            If the user speaks Hindi — respond in Hindi.
            If the user speaks Marathi — respond in Marathi.
            If the user speaks Tamil — respond in Tamil.
            And so on for any language.
            When the user shares an image, describe and analyse it in detail.
            """]
        ]
        
        for message in messages {
            apiMessages.append([
                "role": message.role == .user ? "user" : "assistant",
                "content": message.text
            ])
        }
        
        let body: [String: Any] = [
            "model": "nvidia/nemotron-3-super-120b-a12b:free",
            "messages": apiMessages,
            "stream": true,
            "max_tokens": 1024,
            "temperature": 0.7
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return
        }
        
        request.httpBody = jsonData
        
        do {
            print("📤 Sending to OpenRouter...")
            
            let (stream, response) = try await URLSession.shared.bytes(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            for try await line in stream.lines {
                
                guard line.hasPrefix("data: ") else { continue }
                
                let jsonString = String(line.dropFirst(6))
                
                if jsonString == "[DONE]" { break }
                
                guard
                    let data = jsonString.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = json["choices"] as? [[String: Any]],
                    let first = choices.first,
                    let delta = first["delta"] as? [String: Any]
                else { continue }
                
                // Only show actual content, skip reasoning/thinking tokens
                guard let text = delta["content"] as? String,
                      !text.isEmpty
                else { continue }
                
                await MainActor.run {
                    onToken(text)
                }
            }
            
            await MainActor.run {
                onComplete()
            }
            
        } catch {
            print(" Error: \(error)")
            await MainActor.run {
                onToken("Sorry, something went wrong.")
                onComplete()
            }
        }
    }
}
