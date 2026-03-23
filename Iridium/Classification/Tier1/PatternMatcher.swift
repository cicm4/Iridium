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

        // Check code patterns — language-specific detection (high confidence)
        if let language = detectCodeLanguage(sample) {
            return Result(contentType: .code, language: language, confidence: 0.85)
        }

        // Check if it looks like code generically
        // Use 0.85 confidence — strong enough to beat Tier 2 NL classifier
        // which may mistake code for prose
        if looksLikeCode(sample) {
            return Result(contentType: .code, language: .unknown, confidence: 0.85)
        }

        // Default to prose if it's mostly natural language text
        if sample.count > 10 && looksLikeProse(sample) {
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
        // Threshold of 2 (was 3) so even short snippets with a single strong
        // keyword (scored at 2) are detected as code.
        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= 2
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
                || trimmed.hasPrefix("guard ") || trimmed.hasPrefix("import Swift") || trimmed.hasPrefix("import Foundation")
                || trimmed.hasPrefix("import UIKit") || trimmed.hasPrefix("import AppKit")
                || trimmed.hasPrefix("import SwiftUI") || trimmed.hasPrefix("import Combine")
                || (trimmed.contains("-> ") && !trimmed.contains("fn ")) || trimmed.hasPrefix("struct ")
                || trimmed.hasPrefix("@Observable") || trimmed.hasPrefix("@MainActor")
                || trimmed.hasPrefix("@State") || trimmed.hasPrefix("@Binding")
                || trimmed.contains("try await ") || trimmed.contains("async throws")
            {
                scores[.swift, default: 0] += 2
            }

            // Python
            if trimmed.hasPrefix("def ") || trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ")
                || (trimmed.hasPrefix("class ") && trimmed.hasSuffix(":"))
                || trimmed.hasPrefix("elif ") || trimmed.hasPrefix("print(")
                || trimmed.contains("self.") || trimmed.hasPrefix("return ")
                || trimmed.hasPrefix("for ") && trimmed.contains(" in ") && trimmed.hasSuffix(":")
                || trimmed.hasPrefix("if ") && trimmed.hasSuffix(":")
                || trimmed.hasPrefix("async def ") || trimmed.hasPrefix("await ")
            {
                scores[.python, default: 0] += 2
            }

            // JavaScript/TypeScript
            if trimmed.hasPrefix("const ") || trimmed.hasPrefix("function ")
                || trimmed.contains("=>") || trimmed.contains("console.log")
                || trimmed.hasPrefix("export ") || trimmed.hasPrefix("require(")
                || trimmed.contains(".then(") || trimmed.contains(".catch(")
                || trimmed.hasPrefix("async ") || trimmed.contains("await ")
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
                || (trimmed.contains("::") && trimmed.contains("fn"))
                || trimmed.contains("Vec<") || trimmed.contains("Vec::new")
                || trimmed.contains(": &") || trimmed.contains("-> Result<")
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
            if (trimmed.hasPrefix("def ") && trimmed.hasSuffix(")"))
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
                || (trimmed.hasPrefix("export ") && trimmed.contains("="))
                || trimmed.hasPrefix("if [")
            {
                scores[.shell, default: 0] += 2
            }
        }

        return scores
    }

    // MARK: - Generic Code Detection

    private func looksLikeCode(_ text: String) -> Bool {
        // Strong single indicators that almost certainly mean code
        let strongIndicators = ["func ", "def ", "class ", "const ", "var ", "let ",
                                "import ", "return ", "if (", "for (", "while (",
                                "switch ", "case ", "break;", "continue;",
                                "public ", "private ", "static ", "void ",
                                "async ", "await ", "throw ", "catch ",
                                "println", "printf", "console.", "System."]
        for indicator in strongIndicators {
            if text.contains(indicator) { return true }
        }

        // Structural indicators — need 2+ of these
        let structuralIndicators = ["{", "}", "()", ";", "//", "/*", "*/",
                                     "->", "=>", "!=", "==", "&&", "||",
                                     "+=", "-=", ">=", "<=", "::", "[]"]
        var count = 0
        for indicator in structuralIndicators {
            if text.contains(indicator) { count += 1 }
        }
        return count >= 2
    }

    // MARK: - Prose Detection

    /// Returns true if the text looks like natural language prose.
    /// Checks that the text is mostly words without code-like syntax.
    private func looksLikeProse(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it looks like code, it's not prose
        if looksLikeCode(trimmed) { return false }

        // Count word-like tokens vs symbol-heavy tokens
        let words = trimmed.split(separator: " ")
        guard words.count >= 3 else { return false }

        // Prose typically has longer words with no special chars
        let normalWords = words.filter { word in
            let str = String(word)
            // A "normal" word has mostly letters
            let letterCount = str.filter(\.isLetter).count
            return letterCount > str.count / 2
        }

        // If > 70% of words look like normal English words, it's prose
        return Double(normalWords.count) / Double(words.count) > 0.70
    }
}
