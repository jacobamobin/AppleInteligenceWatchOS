//
//  RewriteHelper.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-07.
//

import Foundation

// MARK: This re-writes the output text from Result into a more friendly speakable output for TTS
// For example "3°" would be converted to "3 degrees"
public func sendRewriteRequest(prompt: String) -> String {
    // Function to process the prompt for TTS-friendly output

    // Function to convert numbers to natural speech
    func numberToWords(_ number: String) -> String {
        guard let num = Int(number) else { return number }

        let units = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        let teens = ["", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
        let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
        let thousands = ["", "thousand", "million", "billion"]

        func convertToWords(_ n: Int) -> String {
            if n == 0 { return "zero" }

            var n = n
            var result = ""
            var place = 0

            while n > 0 {
                let chunk = n % 1000
                if chunk > 0 {
                    let chunkText = convertChunk(chunk)
                    let placeText = thousands[place]
                    result = "\(chunkText) \(placeText) \(result)".trimmingCharacters(in: .whitespaces)
                }
                n /= 1000
                place += 1
            }

            return result.trimmingCharacters(in: .whitespaces)
        }

        func convertChunk(_ n: Int) -> String {
            var n = n
            var result = ""

            if n >= 100 {
                let hundredsPlace = n / 100
                result += "\(units[hundredsPlace]) hundred "
                n %= 100
            }

            if n >= 20 {
                let tensPlace = n / 10
                result += "\(tens[tensPlace]) "
                n %= 10
            } else if n > 10 {
                result += "\(teens[n - 10]) "
                n = 0
            } else if n == 10 {
                result += "ten "
                n = 0
            }

            if n > 0 {
                result += "\(units[n]) "
            }

            return result.trimmingCharacters(in: .whitespaces)
        }

        return convertToWords(num)
    }

    // Dictionary for common replacements
    let replacements: [String: String] = [
        "%": " percent",
        "°": " degree",
        "&": " and",
        "@": " at",
        "$": " dollars",
        "#": " number"
    ]

    // Regex patterns and corresponding transformations
    let patterns: [(pattern: String, transform: (String) -> String)] = [
        // Convert numbers to words
        ("\\b\\d+\\b", numberToWords),

        // Remove parentheses and brackets
        ("[\\(\\)\\[\\]]", { _ in "" })
    ]

    // Perform replacements
    var modifiedPrompt = prompt

    // Direct replacements
    for (key, value) in replacements {
        modifiedPrompt = modifiedPrompt.replacingOccurrences(of: key, with: value)
    }

    // Pattern-based transformations
    for (pattern, transform) in patterns {
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: modifiedPrompt, range: NSRange(modifiedPrompt.startIndex..., in: modifiedPrompt))
        for match in matches.reversed() {
            let matchRange = Range(match.range, in: modifiedPrompt)!
            let matchText = String(modifiedPrompt[matchRange])
            modifiedPrompt.replaceSubrange(matchRange, with: transform(matchText))
        }
    }

    // Return the refactored text, first 1000 charachters, so if it returns something massive the api doesnt kill itself
    return modifiedPrompt
}





