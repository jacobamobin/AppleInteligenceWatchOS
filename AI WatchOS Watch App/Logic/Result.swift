//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import Foundation

// MARK: - Enhanced API Manager with Streaming Support
class APIManager: ObservableObject {
    static let shared = APIManager()
    
    @Published var isLoading = false
    @Published var currentResponse = ""
    private var currentTask: URLSessionDataTask?
    
    private init() {}
    
    // MARK: Send streaming request with memory context
    func sendStreamingRequest(userPrompt: String) async -> String {
        // Cancel any existing request
        currentTask?.cancel()
        
        await MainActor.run {
            isLoading = true
            currentResponse = ""
        }
        
        let apiKey: String = loadAPIKey() ?? "Invalid API Key"
        let assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
        
        guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
            await MainActor.run { isLoading = false }
            return "Error: Invalid URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Build messages with memory context
        var messages: [[String: String]] = []
        
        // Enhanced system prompt with memory awareness
        let systemPrompt = """
        You are \(assistantName), an AI assistant on Apple Watch. BE CONCISE and DIRECT.
        
        CRITICAL: ALWAYS respond in English only. Never use any other language.
        
        Rules:
        - Keep responses under 200 tokens (shorter preferred)
        - No greetings unless first interaction
        - Use natural, conversational tone in English
        - If asked about previous topics, reference our conversation history
        - For errors like "0.1 seconds", respond: "I couldn't hear that, sorry"
        - Be helpful but brief - this is a wrist device
        - ALWAYS respond in English, regardless of the user's language
        """
        
        messages.append(["role": "system", "content": systemPrompt])
        
        // Add conversation history for context
        let contextMessages = ChatMemory.shared.getContextMessages()
        messages.append(contentsOf: contextMessages)
        
        // Add current user message
        messages.append(["role": "user", "content": userPrompt])
        
        // Enhanced payload for streaming
        let payload: [String: Any] = [
            "model": "sonar-pro",
            "messages": messages,
            "max_tokens": 200,
            "temperature": 0.3,
            "top_p": 0.9,
            "return_images": false,
            "return_related_questions": false,
            "search_recency_filter": "month",
            "top_k": 0,
            "stream": true,
            "frequency_penalty": 0.8
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            await MainActor.run { isLoading = false }
            return "Error: Failed to serialize JSON payload"
        }
        
        return await streamResponse(request: request, userPrompt: userPrompt)
    }
    
    // MARK: Real streaming response handler with URLSessionDataDelegate
    private func streamResponse(request: URLRequest, userPrompt: String) async -> String {
        return await withCheckedContinuation { continuation in
            let delegate = StreamingDelegate(apiManager: self, userPrompt: userPrompt, continuation: continuation)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let task = session.dataTask(with: request)
            currentTask = task // Store reference for cancellation
            task.resume()
        }
    }
    
    
    
    // MARK: Fallback regular response parsing
    private func parseRegularResponse(data: Data) -> String {
        do {
            if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let choices = responseObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    return content
                } else if let errorInfo = responseObject["error"] as? [String: Any],
                          let errorMessage = errorInfo["message"] as? String {
                    return "API Error: \(errorMessage)"
                }
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
        
        return "Error parsing response"
    }
}

// MARK: Legacy function for backward compatibility  
func sendRequest(userPrompt: String) -> String {
    // Use the new streaming API manager
    let semaphore = DispatchSemaphore(value: 0)
    var result = ""
    
    Task {
        result = await APIManager.shared.sendStreamingRequest(userPrompt: userPrompt)
        semaphore.signal()
    }
    
    semaphore.wait()
    return result
}

// MARK: Enhanced request with async/await
func sendRequestAsync(userPrompt: String) async -> String {
    return await APIManager.shared.sendStreamingRequest(userPrompt: userPrompt)
}

// MARK: - Real-time Streaming Delegate
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    private let apiManager: APIManager
    private let userPrompt: String
    private let continuation: CheckedContinuation<String, Never>
    private var fullResponse = ""
    private var currentSentence = ""
    private var hasResumed = false
    
    init(apiManager: APIManager, userPrompt: String, continuation: CheckedContinuation<String, Never>) {
        self.apiManager = apiManager
        self.userPrompt = userPrompt
        self.continuation = continuation
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        let lines = string.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if jsonString == "[DONE]" {
                    finishStreaming()
                    return
                }
                
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    
                    fullResponse += content
                    currentSentence += content
                    
                    // Update UI in real-time (character by character)
                    DispatchQueue.main.async {
                        self.apiManager.currentResponse = self.fullResponse
                    }
                    
                    // Check for complete sentences (more aggressive detection)
                    checkForCompleteSentences()
                }
            }
        }
    }
    
    private func checkForCompleteSentences() {
        // More conservative sentence detection to prevent fragmentation
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        
        // Only process complete sentences with proper punctuation
        let sentenceComponents = currentSentence.components(separatedBy: sentenceEnders)
        if sentenceComponents.count > 1 {
            for i in 0..<(sentenceComponents.count - 1) {
                let sentence = sentenceComponents[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if sentence.count > 10 { // Require meaningful length
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .streamingSentence, object: sentence)
                    }
                }
            }
            currentSentence = sentenceComponents.last ?? ""
        }
        
        // Only process phrases at commas if they're substantial
        if currentSentence.contains(",") && currentSentence.count > 30 {
            let commaComponents = currentSentence.components(separatedBy: ",")
            if commaComponents.count > 1 {
                let phrase = commaComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if phrase.count > 15 { // Much higher threshold
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .streamingSentence, object: phrase)
                    }
                    currentSentence = commaComponents.dropFirst().joined(separator: ",")
                }
            }
        }
    }
    
    private func finishStreaming() {
        // Handle any remaining content
        let remaining = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if remaining.count > 5 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .streamingSentence, object: remaining)
            }
        }
        
        // Add to memory
        let userMessage = ChatMessage(role: "user", content: userPrompt)
        let assistantMessage = ChatMessage(role: "assistant", content: fullResponse)
        
        DispatchQueue.main.async {
            ChatMemory.shared.addMessage(userMessage)
            ChatMemory.shared.addMessage(assistantMessage)
            self.apiManager.isLoading = false
        }
        
        if !hasResumed {
            hasResumed = true
            continuation.resume(returning: RemoveCitations(prompt: fullResponse))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.apiManager.isLoading = false
            }
            if !hasResumed {
                hasResumed = true
                continuation.resume(returning: "Error: \(error.localizedDescription)")
            }
        } else {
            finishStreaming()
        }
    }
}

// MARK: - Notification Extension for Streaming
extension Notification.Name {
    static let streamingSentence = Notification.Name("streamingSentence")
}

// Helper function to load Perplexity API key from the plist
func loadAPIKey() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["Perplexity"] as? String {
        return apiKey
    }
    return nil
}
