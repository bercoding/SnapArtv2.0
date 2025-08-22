import AVFoundation
import CoreData
import SwiftUI
import UIKit

import class SnapArtV2_1.CameraViewController

import struct SnapArtV2_1.FilterView

// Import các View khác cần thiết
import struct SnapArtV2_1.MediaPipeTestButton

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var languageViewModel: LanguageViewModel

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.authState == .signedIn {
                    HomePage()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(authViewModel)
                        .environmentObject(languageViewModel)

                } else {
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
