//
//  PatternMatcher.swift
//  Iridium
//

import Foundation

struct PatternMatcher: Sendable {
    struct Result: Sendable {
        let contentType: ContentType
        let language: ProgrammingLanguage?
        let confidence: Double
    }

    func match(sample: String) -> Result? {
        // Check URL pattern first (fast, high confidence)
        if matchesURL(sample) {
            return Result(contentType: .url, language: nil, confidence: 0.95)
        }

        // Check email pattern
        if matchesEmail(sample) {
            return Result(contentType: .email, language: nil, confidence: 0.90)
        }

        // Check code patterns
        if let language = detectCodeLanguage(sample) {
            return Result(contentType: .code, language: language, confidence: 0.85)
        }

        // Check if it looks like code generically
        if looksLikeCode(sample) {
            return Result(contentType: .code, language: .unknown, confidence: 0.70)
        }

        // Default to prose if it's mostly text
        if sample.count > 10 {
            return Result(contentType: .prose, language: nil, confidence: 0.50)
        }

        return nil
    }

    // MARK: - URL Detection

    private func matchesURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Single-line check for URL-like content
        guard !trimmed.contains("\n") || trimmed.split(separator: "\n").count <= 2 else {
            return false
        }
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
            || trimmed.hasPrefix("ftp://") || trimmed.hasPrefix("ssh://")
            || (trimmed.hasPrefix("www.") && trimmed.contains("."))
    }

    // MARK: - Email Detection

    private func matchesEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains("\n"), trimmed.count < 254 else { return false }
        let parts = trimmed.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }

    // MARK: - Code Language Detection

    func detectCodeLanguage(_ text: String) -> ProgrammingLanguage? {
        let scores = languageScores(text)
        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= 3
        else {
            return nil
        }
        return best.key
    }

    private func languageScores(_ text: String) -> [ProgrammingLanguage: Int] {
        var scores: [ProgrammingLanguage: Int] = [:]

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Swift (exclude "let mut" which is Rust)
            if trimmed.hasPrefix("func ") || (trimmed.hasPrefix("let ") && !trimmed.hasPrefix("let mut "))
                || trimmed.hasPrefix("var ")
                || trimmed.hasPrefix("guard ") || trimmed.hasPrefix("import Swift")
                || (trimmed.contains("-> ") && !trimmed.contains("fn ")) || trimmed.hasPrefix("struct ")
                || trimmed.hasPrefix("@Observable") || trimmed.hasPrefix("@MainActor")
            {
                scores[.swift, default: 0] += 2
            }

            // Python
            if trimmed.hasPrefix("def ") || trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ")
                || trimmed.hasPrefix("class ") && trimmed.hasSuffix(":")
                || trimmed.hasPrefix("elif ") || trimmed.hasPrefix("print(")
                || trimmed.contains("self.")
            {
                scores[.python, default: 0] += 2
            }

            // JavaScript/TypeScript
            if trimmed.hasPrefix("const ") || trimmed.hasPrefix("function ")
                || trimmed.contains("=>") || trimmed.contains("console.log")
                || trimmed.hasPrefix("export ") || trimmed.hasPrefix("require(")
            {
                scores[.javascript, default: 0] += 2
            }
            if trimmed.contains(": string") || trimmed.contains(": number")
                || trimmed.contains("interface ") || trimmed.contains(": boolean")
            {
                scores[.typescript, default: 0] += 2
            }

            // Go
            if trimmed.hasPrefix("func ") && trimmed.contains("(") && !trimmed.contains("->") {
                scores[.go, default: 0] += 1
            }
            if trimmed.hasPrefix("package ") || trimmed.contains("fmt.") || trimmed.hasPrefix("go func") {
                scores[.go, default: 0] += 2
            }

            // Rust
            if trimmed.hasPrefix("fn ") || trimmed.hasPrefix("let mut ")
                || trimmed.contains("pub fn") || trimmed.contains("impl ")
                || trimmed.contains("::") && trimmed.contains("fn")
            {
                scores[.rust, default: 0] += 2
            }

            // Java
            if trimmed.hasPrefix("public class ") || trimmed.hasPrefix("private ")
                || trimmed.contains("System.out.println") || trimmed.hasPrefix("@Override")
            {
                scores[.java, default: 0] += 2
            }

            // Ruby
            if trimmed.hasPrefix("def ") && trimmed.hasSuffix(")")
                || trimmed.hasPrefix("end") || trimmed.contains("puts ")
                || trimmed.hasPrefix("require ")
            {
                scores[.ruby, default: 0] += 1
            }

            // HTML
            if trimmed.hasPrefix("<") && trimmed.contains(">")
                && (trimmed.contains("div") || trimmed.contains("html") || trimmed.contains("body")
                    || trimmed.contains("span") || trimmed.contains("class="))
            {
                scores[.html, default: 0] += 2
            }

            // CSS
            if trimmed.contains("{") && (trimmed.contains("color:") || trimmed.contains("margin:")
                || trimmed.contains("padding:") || trimmed.contains("display:")
                || trimmed.contains("font-"))
            {
                scores[.css, default: 0] += 2
            }

            // JSON
            if trimmed.hasPrefix("{") && trimmed.contains("\"") && trimmed.contains(":") {
                scores[.json, default: 0] += 1
            }

            // SQL
            let upper = trimmed.uppercased()
            if upper.hasPrefix("SELECT ") || upper.hasPrefix("INSERT ")
                || upper.hasPrefix("CREATE TABLE") || upper.hasPrefix("ALTER ")
                || upper.hasPrefix("FROM ") || upper.hasPrefix("WHERE ")
                || upper.hasPrefix("INNER JOIN") || upper.hasPrefix("LEFT JOIN")
                || upper.hasPrefix("RIGHT JOIN") || upper.hasPrefix("ORDER BY")
                || upper.hasPrefix("GROUP BY") || upper.hasPrefix("UPDATE ")
                || upper.hasPrefix("DELETE FROM")
            {
                scores[.sql, default: 0] += 2
            }

            // Shell
            if trimmed.hasPrefix("#!/bin/") || trimmed.hasPrefix("echo ")
                || trimmed.hasPrefix("export ") && trimmed.contains("=")
                || trimmed.hasPrefix("if [")
            {
                scores[.shell, default: 0] += 2
            }
        }

        return scores
    }

    // MARK: - Generic Code Detection

    private func looksLikeCode(_ text: String) -> Bool {
        let codeIndicators = ["{", "}", "()", ";", "//", "/*", "*/", "->", "=>", "!=", "=="]
        var count = 0
        for indicator in codeIndicators {
            if text.contains(indicator) { count += 1 }
        }
        return count >= 3
    }
}
