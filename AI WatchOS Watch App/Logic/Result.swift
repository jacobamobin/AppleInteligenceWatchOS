//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import Foundation

class StreamManager: NSObject, URLSessionDataDelegate {
    var onDataReceived: ((String) -> Void)?
    var onCompletion: ((Error?) -> Void)?
    
    private var session: URLSession!
    private var buffer = ""
    
    // We need to keep a reference to the StreamManager
    private var streamManager: StreamManager?

    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func sendRequest(userPrompt: String) {
        self.streamManager = self
        buffer = "" // Reset buffer for new request
        let apiKey: String = loadAPIKey() ?? "Invalid API Key"
        let assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
        
        guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
            print("Invalid URL")
            onCompletion?(NSError(domain: "Result.swift", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "sonar-pro",
            "messages": [
                ["role": "system", "content": "Dont greet the user get to the point. Your name is \(assistantName) and you are a WatchOS assistant on the user's wrist, act like you are having a normal conversation with the user, and answer any questions the user asks. Be a helpful, useful assistant and remember your name is \(assistantName), Keep your answers under 150 words if possible. If you get a sound error, like 0.1 seconds related, ignore it and return 'I couldn't hear that, sorry'."],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 300,
            "temperature": 0.2,
            "top_p": 0.9,
            "stream": true, // Enable streaming
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON payload: \(error.localizedDescription)")
            onCompletion?(error)
            return
        }
        
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return
        }
        
        // Add new data to buffer
        buffer += dataString
        
        // Process complete lines in the buffer
        let lines = buffer.components(separatedBy: .newlines)
        
        // Keep the last line in buffer (might be incomplete)
        buffer = lines.last ?? ""
        
        // Process all complete lines except the last one
        for line in lines.dropLast() {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                    onCompletion?(nil)
                    self.streamManager = nil
                    return
                }
                
                if !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let firstChoice = choices.first,
                               let delta = firstChoice["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                DispatchQueue.main.async {
                                    self.onDataReceived?(content)
                                }
                            }
                        } catch {
                            print("Error decoding chunk: \(error)")
                            // Don't fail the entire stream for one bad chunk
                        }
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onCompletion?(error)
        self.streamManager = nil
    }
}


// MARK: Uses the perplexity API to get a response to the user's question
func sendRequest(userPrompt: String, onDataReceived: @escaping (String) -> Void, onCompletion: @escaping (Error?) -> Void) {
    let streamManager = StreamManager()
    streamManager.onDataReceived = onDataReceived
    streamManager.onCompletion = onCompletion
    streamManager.sendRequest(userPrompt: userPrompt)
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