import SwiftUI
import GoogleMobileAds
import UIKit

struct LockedFilterView: View {
    let filter: FilterType
    @StateObject private var unlockManager = FilterUnlockManager.shared
    @StateObject private var rewardedAdManager = RewardedAdManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
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
                // Nếu người dùng là premium, tự động mở khóa
                if profileManager.currentUser?.stats.premiumStatus == true {
                    unlockManager.unlockFilter(filter)
                    return
                }
                
                if rewardedAdManager.isAdReady {
                    showRewardedAd()
                } else {
                    rewardedAdManager.loadRewardedAd() // Tải quảng cáo nếu chưa sẵn sàng
                    showingUnlockAlert = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: profileManager.currentUser?.stats.premiumStatus == true ? "crown.fill" : "play.circle.fill")
                        .font(.system(size: 12))
                    
                    Text(profileManager.currentUser?.stats.premiumStatus == true ? "Mở khóa" : "Xem quảng cáo")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Group {
                        if profileManager.currentUser?.stats.premiumStatus == true {
                            Color.orange.opacity(0.8)
                        } else if rewardedAdManager.isAdReady {
                            Color.blue.opacity(0.8)
                        } else {
                            Color.gray.opacity(0.6)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!rewardedAdManager.isAdReady && profileManager.currentUser?.stats.premiumStatus != true)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(10)
        .background(
            ZStack {
                Color.white.opacity(0.15) // Giống filter bình thường
                
                // Viền cam nhẹ để phân biệt
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .alert("Quảng cáo chưa sẵn sàng", isPresented: $showingUnlockAlert) {
            Button("OK") { }
        } message: {
            Text("Vui lòng đợi một chút để quảng cáo tải xong, sau đó thử lại.")
        }
        .onAppear {
            // Tải quảng cáo khi view xuất hiện
            if !rewardedAdManager.isAdReady && profileManager.currentUser?.stats.premiumStatus != true {
                rewardedAdManager.loadRewardedAd()
            }
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
        
        print("[LockedFilterView] Attempting to show rewarded ad")
        rewardedAdManager.presentAdIfAvailable(from: rootVC) { success in
            if success {
                unlockManager.unlockFilter(filter)
                print("[LockedFilterView] Filter unlocked successfully: \(filter)")
            } else {
                print("[LockedFilterView] Failed to unlock filter: \(filter)")
            }
        }
    }
} 