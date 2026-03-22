//
//  ProgrammingLanguage.swift
//  Iridium
//

import Foundation

enum ProgrammingLanguage: String, Sendable, Codable, CaseIterable {
    case swift
    case python
    case javascript
    case typescript
    case go
    case rust
    case java
    case ruby
    case cPlusPlus = "c++"
    case cSharp = "c#"
    case c
    case html
    case css
    case json
    case yaml
    case shell
    case sql
    case kotlin
    case php
    case unknown
}
