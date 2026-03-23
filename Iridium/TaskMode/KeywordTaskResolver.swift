//
//  KeywordTaskResolver.swift
//  Iridium
//
//  Always-available keyword-based task resolver.
//  Maps common task descriptions to app category weights using a static dictionary.
//  No AI required — runs synchronously in <1ms.
//

import Foundation

struct KeywordTaskResolver: TaskResolver {
    /// Static keyword → category weight mappings.
    /// Each keyword maps to one or more categories with weights.
    private static let keywordMap: [(keywords: [String], categories: [AppCategory: Double])] = [
        // Development
        (["code", "coding", "programming", "software", "debug", "debugging", "refactor",
          "compile", "build", "deploy", "devops", "api", "backend", "frontend",
          "fullstack", "pull request", "merge", "git", "repository"],
         [.development: 1.0, .research: 0.3]),

        // Web development
        (["web", "website", "webapp", "html", "css", "javascript", "react", "vue",
          "angular", "node", "nextjs", "svelte"],
         [.development: 0.9, .research: 0.4, .creativity: 0.2]),

        // Mobile development
        (["ios", "android", "swift", "kotlin", "mobile", "app development", "xcode",
          "flutter", "react native"],
         [.development: 1.0]),

        // Video editing / production
        (["video", "film", "editing", "premiere", "final cut", "davinci", "render",
          "animation", "motion graphics", "vfx", "color grading", "footage"],
         [.media: 0.9, .creativity: 0.8]),

        // Music / Audio
        (["music", "audio", "podcast", "recording", "mixing", "mastering", "sound",
          "logic pro", "garageband", "ableton"],
         [.media: 0.8, .creativity: 0.9]),

        // Design
        (["design", "ui", "ux", "figma", "sketch", "prototype", "wireframe",
          "mockup", "layout", "typography", "branding", "logo", "graphic"],
         [.creativity: 1.0, .productivity: 0.2]),

        // Photography
        (["photo", "photography", "lightroom", "photoshop", "retouching", "raw",
          "image editing"],
         [.creativity: 0.9, .media: 0.3]),

        // Writing
        (["write", "writing", "essay", "article", "blog", "content", "copywriting",
          "documentation", "technical writing", "manuscript", "novel", "story"],
         [.productivity: 0.9, .research: 0.4]),

        // Academic / Research
        (["research", "thesis", "dissertation", "paper", "academic", "study",
          "literature review", "citation", "bibliography", "journal", "science"],
         [.research: 1.0, .productivity: 0.5]),

        // Presentation
        (["presentation", "slides", "keynote", "powerpoint", "pitch", "deck",
          "talk", "conference"],
         [.productivity: 0.8, .creativity: 0.4]),

        // Spreadsheet / Data
        (["spreadsheet", "data", "analysis", "excel", "numbers", "charts",
          "dashboard", "metrics", "reporting", "csv", "database", "sql"],
         [.productivity: 0.9, .research: 0.3]),

        // Communication
        (["email", "meeting", "call", "conference call", "zoom", "teams",
          "slack", "chat", "message", "correspondence", "outreach"],
         [.communication: 1.0]),

        // Project management
        (["project", "planning", "roadmap", "sprint", "agile", "kanban",
          "jira", "trello", "asana", "todoist", "task", "milestone"],
         [.productivity: 0.9, .communication: 0.3]),

        // Note-taking / Knowledge management
        (["notes", "note-taking", "obsidian", "notion", "knowledge base",
          "wiki", "second brain", "zettelkasten", "journal", "diary"],
         [.productivity: 0.7, .research: 0.6]),

        // System administration
        (["server", "infrastructure", "docker", "kubernetes", "aws", "cloud",
          "linux", "terminal", "ssh", "networking", "monitoring"],
         [.development: 0.7, .utility: 0.6]),

        // 3D / CAD
        (["3d", "blender", "cad", "modeling", "rendering", "texture",
          "sculpting", "architecture"],
         [.creativity: 1.0, .media: 0.4]),
    ]

    func resolve(description: String) async -> [AppCategory: Double] {
        let lower = description.lowercased()
        var categoryScores: [AppCategory: Double] = [:]
        var matchCount = 0

        for entry in Self.keywordMap {
            let matched = entry.keywords.contains { keyword in
                lower.contains(keyword)
            }
            if matched {
                matchCount += 1
                for (category, weight) in entry.categories {
                    categoryScores[category] = max(categoryScores[category] ?? 0, weight)
                }
            }
        }

        // If no keywords matched, return empty (no bias)
        guard matchCount > 0 else { return [:] }

        return categoryScores
    }
}
