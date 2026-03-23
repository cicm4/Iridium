//
//  HTMLUTICodeClassificationTests.swift
//  IridiumTests
//
//  Tests that prove code copied from IDEs (which arrives as public.html UTI)
//  is correctly classified as CODE, not prose.
//
//  ROOT CAUSE: Cursor, VSCode, Xcode, and most IDEs copy code to the clipboard
//  with the first pasteboard type being "public.html" (for syntax highlighting).
//  UTIClassifier sees "public.html" → returns .prose → RuleBasedClassifier never
//  runs PatternMatcher on the actual text → classification is .prose at 0.90
//  confidence → IDE context boost never fires (it checks contentType == .code)
//  → research pack's prose trigger fires → user gets Pages/Word/Notes instead of IDEs.
//

import Testing
@testable import Iridium

// MARK: - Bug #1: UTIClassifier blindly classifies public.html as prose

@Suite("HTML UTI + Code Content Classification")
struct HTMLUTICodeClassificationTests {

    // ──────────────────────────────────────────────────────────────────────
    // These tests MUST FAIL on the current (broken) code.
    // They prove that code copied from an IDE is wrongly classified as prose.
    // ──────────────────────────────────────────────────────────────────────

    @Test("UTIClassifier should NOT classify public.html as prose when content is code")
    func utiClassifierHTMLShouldNotReturnProse() {
        // When an IDE copies code, the first UTI is public.html.
        // UTIClassifier should return nil (defer to content analysis),
        // NOT .prose, because HTML is an AMBIGUOUS container format.
        let classifier = UTIClassifier()
        let result = classifier.classify(uti: "public.html")

        // If this returns .prose, it proves the bug — RuleBasedClassifier
        // will never look at the actual content and always return prose.
        #expect(result != .prose,
                "BUG: UTIClassifier returns .prose for public.html — this causes all IDE-copied code to be misclassified")
    }

    @Test("RuleBasedClassifier: Python code with public.html UTI must classify as code")
    func ruleBasedClassifierHTMLPythonCode() async {
        let pythonCode = """
        def reset(self):
            \"\"\"Resets the game to the initial state\"\"\"
            self.steps = 0
            rnd_indices = np.random.choice(range(1,len(self.rooms)-1), size=len(self.guards), replace=False)
            guard_pos = [self.rooms[i] for i in rnd_indices]
            available_positions = [pos for pos in self.rooms[1:-1] if pos not in guard_pos]
            special_positions = random.sample(available_positions, 2)
            if not possible_starts:
                player_start = (0, 0)
            else:
                player_start = random.choice(possible_starts)
        """

        let classifier = RuleBasedClassifier()
        let result = await classifier.classify(uti: "public.html", sample: pythonCode)

        #expect(result.contentType == .code,
                "BUG: Python code with public.html UTI classified as \(result.contentType.rawValue) instead of code")
        #expect(result.confidence >= 0.80,
                "Code confidence should be >= 0.80, got \(result.confidence)")
    }

    @Test("RuleBasedClassifier: Swift code with public.html UTI must classify as code")
    func ruleBasedClassifierHTMLSwiftCode() async {
        let swiftCode = """
        func viewDidLoad() {
            super.viewDidLoad()
            let tableView = UITableView(frame: view.bounds)
            tableView.delegate = self
            tableView.dataSource = self
            view.addSubview(tableView)
        }
        """

        let classifier = RuleBasedClassifier()
        let result = await classifier.classify(uti: "public.html", sample: swiftCode)

        #expect(result.contentType == .code,
                "BUG: Swift code with public.html UTI classified as \(result.contentType.rawValue) instead of code")
    }

    @Test("RuleBasedClassifier: JavaScript code with public.html UTI must classify as code")
    func ruleBasedClassifierHTMLJavaScriptCode() async {
        let jsCode = """
        const express = require('express');
        const app = express();
        app.get('/api/users', async (req, res) => {
            const users = await User.find({});
            res.json(users);
        });
        app.listen(3000, () => console.log('Server running'));
        """

        let classifier = RuleBasedClassifier()
        let result = await classifier.classify(uti: "public.html", sample: jsCode)

        #expect(result.contentType == .code,
                "BUG: JavaScript code with public.html UTI classified as \(result.contentType.rawValue) instead of code")
    }

    @Test("Full pipeline: Python code from Cursor (public.html) must produce IDE suggestions, not prose suggestions")
    func fullPipelinePythonCodeFromCursor() async {
        let pythonCode = """
        def reset(self):
            self.steps = 0
            rnd_indices = np.random.choice(range(1,len(self.rooms)-1), size=len(self.guards), replace=False)
            guard_pos = [self.rooms[i] for i in rnd_indices]
            if not possible_starts:
                player_start = (0, 0)
            else:
                player_start = random.choice(possible_starts)
        """

        let pipeline = ClassificationPipeline()
        let classification = await pipeline.classify(
            uti: "public.html",
            sample: pythonCode,
            sourceAppBundleID: "com.todesktop.230313mzl4w4u92"  // Cursor
        )

        #expect(classification.contentType == .code,
                "BUG: Full pipeline returns \(classification.contentType.rawValue) for Python code from Cursor with public.html UTI")

        // Now verify the pack evaluator produces IDE suggestions, not prose suggestions
        let signal = ContextSignal(
            clipboardUTI: "public.html",
            clipboardSample: pythonCode,
            frontmostAppBundleID: "com.todesktop.230313mzl4w4u92"
        )
        let fusion = SignalFusion()
        let enriched = fusion.enrich(signal: signal, classification: classification)

        let evaluator = PackEvaluator()
        let loader = PackLoader()
        let allPacks = loader.loadBuiltInPacks()

        let suggestions = evaluator.evaluate(signal: enriched, packs: allPacks)

        let ideBundleIDs: Set<String> = ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode",
                                          "com.microsoft.VSCode", "com.jetbrains.pycharm"]
        let proseBundleIDs: Set<String> = ["com.apple.iWork.Pages", "com.microsoft.Word", "com.apple.Notes"]

        let suggestedBundleIDs = Set(suggestions.map(\.bundleID))

        let hasIDESuggestions = !suggestedBundleIDs.intersection(ideBundleIDs).isEmpty
        let hasOnlyProseSuggestions = suggestedBundleIDs.isSubset(of: proseBundleIDs)

        #expect(hasIDESuggestions,
                "BUG: No IDE suggestions produced. Got: \(suggestedBundleIDs)")
        #expect(!hasOnlyProseSuggestions,
                "BUG: Only prose suggestions produced (\(suggestedBundleIDs)). Should include IDEs.")
    }

    @Test("Full pipeline: code from VSCode (public.html) must classify as code")
    func fullPipelineCodeFromVSCode() async {
        let rustCode = """
        fn main() {
            let mut vec = Vec::new();
            vec.push(1);
            vec.push(2);
            for item in &vec {
                println!("{}", item);
            }
        }
        """

        let pipeline = ClassificationPipeline()
        let classification = await pipeline.classify(
            uti: "public.html",
            sample: rustCode,
            sourceAppBundleID: "com.microsoft.VSCode"
        )

        #expect(classification.contentType == .code,
                "BUG: Rust code from VSCode with public.html UTI classified as \(classification.contentType.rawValue)")
    }

    @Test("IDE context boost must fire even when UTI is public.html")
    func ideContextBoostFiresWithHTMLUTI() async {
        // Ambiguous content that could be prose or code — the IDE boost should tip it
        let ambiguousCode = """
        let x = 5
        let y = 10
        print(x + y)
        """

        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.html",
            sample: ambiguousCode,
            sourceAppBundleID: "com.todesktop.230313mzl4w4u92"  // Cursor
        )

        // With IDE context, this should be classified as code
        #expect(result.contentType == .code,
                "IDE context boost did not fire for public.html UTI — classified as \(result.contentType.rawValue)")
    }

    @Test("Actual HTML prose with public.html UTI should still classify as prose")
    func actualHTMLProseStillClassifiesAsProse() async {
        // Real prose content (not code) that happens to come via HTML
        let htmlProse = "The quick brown fox jumps over the lazy dog. This is a perfectly normal sentence with nothing special about it."

        let classifier = RuleBasedClassifier()
        let result = await classifier.classify(uti: "public.html", sample: htmlProse)

        // Prose should still be classified as prose — we just don't want code to be misclassified
        #expect(result.contentType == .prose,
                "Actual prose with public.html UTI should still be prose, got \(result.contentType.rawValue)")
    }

    @Test("public.rtf with code content must classify as code")
    func rtfWithCodeContent() async {
        let code = """
        import Foundation

        struct User: Codable {
            let name: String
            let email: String
            var isActive: Bool = true
        }
        """

        let classifier = RuleBasedClassifier()
        let result = await classifier.classify(uti: "public.rtf", sample: code)

        #expect(result.contentType == .code,
                "BUG: Code with public.rtf UTI classified as \(result.contentType.rawValue) instead of code")
    }
}
