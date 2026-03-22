//
//  LanguageDetector.swift
//  Iridium
//

import Foundation
import NaturalLanguage

struct LanguageDetector: Sendable {
    /// Attempts to detect the programming language from a code sample.
    /// Uses more sophisticated analysis than Tier 1's keyword matching.
    func detect(sample: String) -> ProgrammingLanguage? {
        let lines = sample.split(separator: "\n", omittingEmptySubsequences: false)
        guard !lines.isEmpty else { return nil }

        var scores: [ProgrammingLanguage: Double] = [:]

        // Analyze indentation style
        let usesTabIndentation = lines.contains { $0.hasPrefix("\t") }
        let usesSpaceIndentation = lines.contains { $0.hasPrefix("    ") || $0.hasPrefix("  ") }

        // Python: space indentation is strong signal
        if usesSpaceIndentation && !sample.contains("{") && sample.contains(":") {
            scores[.python, default: 0] += 3
        }

        // Analyze line endings
        let semicolonLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasSuffix(";") }
        let semicolonRatio = Double(semicolonLines.count) / Double(lines.count)

        // High semicolon usage: C-family, Java, PHP
        if semicolonRatio > 0.4 {
            scores[.java, default: 0] += 1
            scores[.cPlusPlus, default: 0] += 1
            scores[.php, default: 0] += 1
        }

        // Check for distinctive syntax patterns
        analyzePatterns(sample, scores: &scores)

        // Check file-type hints in content
        analyzeShebang(lines.first.map(String.init) ?? "", scores: &scores)

        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= 2.0
        else {
            return nil
        }
        return best.key
    }

    private func analyzePatterns(_ text: String, scores: inout [ProgrammingLanguage: Double]) {
        // Swift-specific
        if text.contains("@Observable") || text.contains("@Published") || text.contains("some View")
            || text.contains("SwiftUI")
        {
            scores[.swift, default: 0] += 5
        }

        // TypeScript-specific (vs JavaScript)
        if text.contains(": string") || text.contains(": number") || text.contains(": boolean")
            || text.contains("interface ") || text.contains("<T>")
        {
            scores[.typescript, default: 0] += 3
        }

        // Rust-specific
        if text.contains("fn main()") || text.contains("let mut ") || text.contains("&self")
            || text.contains("impl ") || text.contains("pub fn")
        {
            scores[.rust, default: 0] += 4
        }

        // Go-specific
        if text.contains("package main") || text.contains("func main()") && text.contains("fmt.")
            || text.contains(":= ")
        {
            scores[.go, default: 0] += 4
        }

        // Kotlin-specific
        if text.contains("fun ") && text.contains(": ") && text.contains("val ")
            || text.contains("companion object")
        {
            scores[.kotlin, default: 0] += 4
        }
    }

    private func analyzeShebang(_ firstLine: String, scores: inout [ProgrammingLanguage: Double]) {
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#!") else { return }

        if trimmed.contains("python") { scores[.python, default: 0] += 5 }
        if trimmed.contains("node") { scores[.javascript, default: 0] += 5 }
        if trimmed.contains("ruby") { scores[.ruby, default: 0] += 5 }
        if trimmed.contains("bash") || trimmed.contains("/sh") { scores[.shell, default: 0] += 5 }
        if trimmed.contains("php") { scores[.php, default: 0] += 5 }
    }
}
