//
//  RemoveCitations.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/10/25.
//

import Foundation

// MARK: This re-writes the output text from Result to remove citations like : [1]
public func RemoveCitations(prompt: String) -> String {
    // Remove any text inside square brackets, as well as the square brackets themselves
    let regexPattern = "\\[.*?\\]" // Matches any content inside square brackets
    let modifiedPrompt = prompt.replacingOccurrences(of: regexPattern, with: "", options: .regularExpression)
    
    return String(modifiedPrompt)
}
