import SwiftUI

enum FilterCategory: CaseIterable, Hashable {
    case overlay
    case funny
    case beauty
    case christmas
    
    var title: String {
        switch self {
        case .overlay: return "Overlay"
        case .funny: return "Funny"
        case .beauty: return "Beauty"
        case .christmas: return "Christmas"
        }
    }
    
    var icon: String {
        switch self {
        case .overlay: return "🧩"
        case .funny: return "🤣"
        case .beauty: return "✨"
        case .christmas: return "🎄"
        }
    }
    
    var filters: [FilterType] {
        switch self {
        case .overlay:
            return [.dogFace, .glasses, .mustache, .hat]
        case .funny:
            return [.funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp]
        case .beauty:
            return [.beauty]
        case .christmas:
            return [.xmasWarm, .xmasSanta]
        }
    }
} 