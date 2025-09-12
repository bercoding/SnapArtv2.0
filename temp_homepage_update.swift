                NavigationLink {
                    ProfileView()
                        .id(languageViewModel.refreshID)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.white)
                        Text(NSLocalizedString("Profile", comment: "Profile"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                NavigationLink {
                    GalleryView()
                        .id(languageViewModel.refreshID)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white)
                        Text(NSLocalizedString("Thư viện ảnh", comment: "Gallery"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                NavigationLink {
                    LanguageView()
                        .id(languageViewModel.refreshID)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "globe")
                            .foregroundColor(.white)
                        Text(NSLocalizedString("Language", comment: "Language"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                NavigationLink {
                    PremiumView(purchaseManager: InAppPurchaseManager.shared)
                        .id(languageViewModel.refreshID)
                        .onAppear {
                            // Hiện Interstitial Ad khi PremiumView xuất hiện
                            InterstitialAdManager.shared.showAdIfAvailable(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) {
                               // đóng ad 
                            }
                        }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text(NSLocalizedString("Premium", comment: "Premium"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
