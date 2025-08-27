import Foundation
import SwiftUI

final class FilterUnlockManager: ObservableObject {
    static let shared = FilterUnlockManager()
    
    @Published var unlockedFilters: Set<FilterType> = []
    
    // Các filter bị khóa, cần xem Rewarded Ad để unlock
    private let lockedFilters: Set<FilterType> = [
        .funnyBigEyes,      // Giant Eyes
        .funnyWideMouth,    // Giant Mouth
        .funnyMegaFace,     // Ugly Face
        .funnyAlienHead     // Alien Head (thêm vào cho đẹp)
    ]
    
    private let userDefaultsKey = "UnlockedFilters"
    
    private init() {
        loadUnlockedFilters()
    }
    
    // Kiểm tra filter có bị khóa không
    func isFilterLocked(_ filter: FilterType) -> Bool {
        return lockedFilters.contains(filter) && !unlockedFilters.contains(filter)
    }
    
    // Kiểm tra filter có thể unlock được không
    func canUnlockFilter(_ filter: FilterType) -> Bool {
        return lockedFilters.contains(filter)
    }
    
    // Unlock filter sau khi xem Rewarded Ad
    func unlockFilter(_ filter: FilterType) {
        guard canUnlockFilter(filter) else { return }
        
        unlockedFilters.insert(filter)
        saveUnlockedFilters()
        
        print("[FilterUnlock] Unlocked filter: \(filter)")
    }
    
    // Lưu trạng thái unlock vào UserDefaults
    private func saveUnlockedFilters() {
        let filterInts = unlockedFilters.map { $0.rawValue }
        UserDefaults.standard.set(filterInts, forKey: userDefaultsKey)
    }
    
    // Load trạng thái unlock từ UserDefaults
    private func loadUnlockedFilters() {
        guard let filterInts = UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int] else { return }
        
        unlockedFilters = Set(filterInts.compactMap { FilterType(rawValue: $0) })
        print("[FilterUnlock] Loaded \(unlockedFilters.count) unlocked filters")
    }
    
    // Reset tất cả filter về trạng thái khóa (cho testing)
    func resetAllFilters() {
        unlockedFilters.removeAll()
        saveUnlockedFilters()
        print("[FilterUnlock] Reset all filters to locked state")
    }
} 