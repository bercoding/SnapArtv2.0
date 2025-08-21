import AVFoundation
import CoreData
import SwiftUI
import UIKit

import class SnapArtV2_1.CameraViewController

// Import các View khác cần thiết
import struct SnapArtV2_1.MediaPipeTestButton
import struct SnapArtV2_1.FilterView

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.authState == .signedIn {
                    HomePage()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(authViewModel)
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
        }
        .onAppear {
            print("ContentView xuất hiện - Auth State: \(authViewModel.authState)")
        }
    }
}


 
