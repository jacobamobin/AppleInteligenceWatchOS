//
//  ChatMemory.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import Foundation

// MARK: - Chat Memory Management
class ChatMemory: ObservableObject {
    static let shared = ChatMemory()
    
    @Published var messages: [ChatMessage] = []
    private let maxMessages = 20 // Keep last 20 exchanges for context
    private let userDefaultsKey = "ChatHistory"
    
    private init() {
        loadChatHistory()
    }
    
    // MARK: - Add message to memory
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        
        // Keep only the last maxMessages
        if messages.count > maxMessages {
            messages.removeFirst()
        }
        
        saveChatHistory()
    }
    
    // MARK: - Get context for API calls
    func getContextMessages() -> [[String: String]] {
        // Return recent messages for API context, limiting to last 10 exchanges
        let recentMessages = Array(messages.suffix(10))
        return recentMessages.map { message in
            [
                "role": message.role,
                "content": message.content
            ]
        }
    }
    
    // MARK: - Clear memory
    func clearMemory() {
        messages.removeAll()
        saveChatHistory()
    }
    
    // MARK: - Save to UserDefaults
    private func saveChatHistory() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save chat history: \(error)")
        }
    }
    
    // MARK: - Load from UserDefaults
    private func loadChatHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            messages = try JSONDecoder().decode([ChatMessage].self, from: data)
        } catch {
            print("Failed to load chat history: \(error)")
            messages = []
        }
    }
    
    // MARK: - Get summary of recent conversation
    func getConversationSummary() -> String {
        let recentMessages = Array(messages.suffix(6))
        let summary = recentMessages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        return summary.isEmpty ? "No previous conversation" : summary
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
} 