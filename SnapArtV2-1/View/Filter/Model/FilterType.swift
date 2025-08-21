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
        case .none: return "Không có filter"
        case .dogFace: return "Mặt chó(disable)"
        case .glasses: return "Kính"
        case .mustache: return "Râu"
        case .hat: return "Mũ"
        case .beauty: return "Beauty"
        case .funnyBigEyes: return "Mắt to"
        case .funnyTinyNose: return "Mũi nhỏ"
        case .funnyWideMouth: return "Miệng rộng"
        case .funnyPuffyCheeks: return "Mắt hí"
        case .funnySwirl: return "Xoáy mặt"
        case .funnyLongChin: return "Mặt vuông"
        case .funnyMegaFace: return "Mắt & miệng khổng lồ"
        case .funnyAlienHead: return "Mặt xấu"
        case .funnyWarp: return "Kéo méo (tay)(disable)"
        case .xmasWarm: return "Noel ấm áp"
        // case .xmasHat: return "Mũ Noel"
        case .xmasSanta: return "Ông già Noel"
        case .xmasBeard: return "Râu Noel"
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
