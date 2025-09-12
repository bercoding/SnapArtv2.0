import AVFoundation
import CoreData
import SwiftUI
import UIKit
import FirebaseCrashlytics

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
    var body: some View {
        Group {
            if authViewModel.authState == .signedIn {
                MainTabView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(languageViewModel)
            } else {
                NavigationStack {
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(languageViewModel)
                }
            }
        }
        .onAppear {
            print("ContentView xuất hiện - Auth State: \(authViewModel.authState)")
        }
        .id(languageViewModel.refreshID) // Force reload toàn bộ view khi ngôn ngữ thay đổi
    }
}
