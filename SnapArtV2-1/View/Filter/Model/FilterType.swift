import Foundation
import UIKit

// Định nghĩa FilterType cho toàn bộ ứng dụng
public enum FilterType: Int, CaseIterable {
    case none = 0
    case dogFace = 1
    case glasses = 2
    case mustache = 3
    case hat = 4
    case beauty = 5
    // Funny distortion filters
    case funnyBigEyes = 6
    case funnyTinyNose = 7
    case funnyWideMouth = 8
    case funnyPuffyCheeks = 9
    case funnySwirl = 10
    case funnyLongChin = 11
    case funnyMegaFace = 12
    case funnyAlienHead = 13
    case funnyWarp = 14
    // Christmas filters
    case xmasWarm = 15
    // case xmasHat = 16  // removed
    case xmasSanta = 17
    case xmasBeard = 18
    
    // Lấy tên hiển thị của filter
    var displayName: String {
        switch self {
        case .none: return NSLocalizedString("Không có filter", comment: "No filter")
        case .dogFace: return NSLocalizedString("Mặt chó(disable)", comment: "Dog face (disabled)")
        case .glasses: return NSLocalizedString("Kính", comment: "Glasses")
        case .mustache: return NSLocalizedString("Râu", comment: "Mustache")
        case .hat: return NSLocalizedString("Mũ", comment: "Hat")
        case .beauty: return NSLocalizedString("Beauty", comment: "Beauty")
        case .funnyBigEyes: return NSLocalizedString("Mắt to", comment: "Big eyes")
        case .funnyTinyNose: return NSLocalizedString("Mũi nhỏ", comment: "Tiny nose")
        case .funnyWideMouth: return NSLocalizedString("Miệng rộng", comment: "Wide mouth")
        case .funnyPuffyCheeks: return NSLocalizedString("Mắt hí", comment: "Squinty eyes")
        case .funnySwirl: return NSLocalizedString("Xoáy mặt", comment: "Face swirl")
        case .funnyLongChin: return NSLocalizedString("Mặt vuông", comment: "Square face")
        case .funnyMegaFace: return NSLocalizedString("Mắt & miệng khổng lồ", comment: "Giant eyes & mouth")
        case .funnyAlienHead: return NSLocalizedString("Mặt xấu", comment: "Ugly face")
        case .funnyWarp: return NSLocalizedString("Kéo méo (tay)(disable)", comment: "Face warp (hand) (disabled)")
        case .xmasWarm: return NSLocalizedString("Noel ấm áp", comment: "Warm Christmas")
        // case .xmasHat: return NSLocalizedString("Mũ Noel", comment: "Christmas hat")
        case .xmasSanta: return NSLocalizedString("Ông già Noel", comment: "Santa Claus")
        case .xmasBeard: return NSLocalizedString("Râu Noel", comment: "Christmas beard")
        }
    }
    
    // Lấy icon đại diện cho filter
    var icon: String {
        switch self {
        case .none: return "❌"
        case .dogFace: return "🐕"
        case .glasses: return "👓"
        case .mustache: return "👨"
        case .hat: return "🎩"
        case .beauty: return "✨"
        case .funnyBigEyes: return "👀"
        case .funnyTinyNose: return "👃"
        case .funnyWideMouth: return "👄"
        case .funnyPuffyCheeks: return "🐹"
        case .funnySwirl: return "🌀"
        case .funnyLongChin: return "🧔"
        case .funnyMegaFace: return "🤪"
        case .funnyAlienHead: return "👽"
        case .funnyWarp: return "✋"
        case .xmasWarm: return "🎄"
        // case .xmasHat: return "🎄"
        case .xmasSanta: return "🎅"
        case .xmasBeard: return "🧔"
        }
    }
    
    // Lấy tên ảnh filter (đối với filter overlay dùng ảnh). Với filter biến dạng/beauty/giáng sinh không cần asset => để trống
    var imageName: String {
        switch self {
            case .none: return ""
            case .dogFace: return "filter_dogface"
            case .glasses: return "filter_glasses"
            case .mustache: return "filter_mustache"
            case .hat: return "filter_hat"
            // case .xmasHat: return "filter_chrismas_hat"
            case .xmasSanta: return "filter_chrismas_santa-hat"
            case .xmasBeard: return "filter_chrismas_santa-claus"
            case .beauty, .funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp, .xmasWarm:
                return "" // không dùng ảnh overlay
        }
    }
} 
