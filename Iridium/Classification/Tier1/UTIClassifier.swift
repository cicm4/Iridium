//
//  UTIClassifier.swift
//  Iridium
//

import Foundation

struct UTIClassifier: Sendable {
    func classify(uti: String) -> ContentType? {
        let lower = uti.lowercased()

        // Source code types
        if lower.contains("source-code") || lower.contains("sourcecode") {
            return .code
        }

        // URL types
        if lower.contains("public.url") || lower == "public.file-url" {
            return .url
        }

        // Image types
        if lower.hasPrefix("public.image") || lower.contains("png") || lower.contains("jpeg")
            || lower.contains("gif") || lower.contains("tiff") || lower.contains("heic")
        {
            return .image
        }

        // File types
        if lower.contains("public.file") || lower.contains("public.folder") {
            return .file
        }

        // Text types (broad category — refined by PatternMatcher)
        if lower.contains("public.plain-text") || lower.contains("public.utf8-plain-text")
            || lower.contains("public.text")
        {
            return nil  // Defer to pattern matching for more specific classification
        }

        // Rich text
        if lower.contains("public.rtf") || lower.contains("public.html") {
            return .prose
        }

        return nil
    }
}
