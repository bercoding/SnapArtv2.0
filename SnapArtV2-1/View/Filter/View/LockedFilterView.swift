import SwiftUI
import GoogleMobileAds

struct LockedFilterView: View {
    let filter: FilterType
    @StateObject private var unlockManager = FilterUnlockManager.shared
    @StateObject private var rewardedAdManager = RewardedAdManager.shared
    @State private var showingUnlockAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Filter name với icon khóa nhỏ
            HStack(spacing: 6) {
                Text(filter.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Icon khóa nhỏ
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
            
            // Nút unlock nhỏ gọn
            Button(action: {
                if rewardedAdManager.isAdReady {
                    showRewardedAd()
                } else {
                    showingUnlockAlert = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 12))
                    
                    Text("Unlock")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    rewardedAdManager.isAdReady ? 
                    Color.blue.opacity(0.8) :
                    Color.gray.opacity(0.6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!rewardedAdManager.isAdReady)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(10)
        .background(
            Color.white.opacity(0.15) // Giống filter bình thường
                .overlay(
                    // Viền cam nhẹ để phân biệt
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .alert("Ad Not Ready", isPresented: $showingUnlockAlert) {
            Button("OK") { }
        } message: {
            Text("Please wait a moment for the ad to load, then try again.")
        }
    }
    
    private func showRewardedAd() {
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        
        guard let rootVC = rootVC else { 
            print("[LockedFilterView] Could not find root view controller")
            return 
        }
        
        rewardedAdManager.showAd(from: rootVC) { [weak unlockManager] success in
            if success {
                unlockManager?.unlockFilter(filter)
                print("[LockedFilterView] Filter unlocked successfully: \(filter)")
            } else {
                print("[LockedFilterView] Failed to unlock filter: \(filter)")
            }
        }
    }
} 