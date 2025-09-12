//
//  DetailGallery.swift
//  SnapArtV2-1
//
//  Created by Le Thanh Nhan on 6/8/25.
//

import Foundation
import SwiftUI

struct DetailImage: View {
    let image: UIImage
    let dateCreated: Date
    let filterType: String?
    let onDelete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("Thời gian chụp:", comment: "Capture time"))
                            .fontWeight(.medium)
                        Spacer()
                        Text(dateFormatter.string(from: dateCreated))
                    }
                    
                    if let filterType = filterType {
                        HStack {
                            Text(NSLocalizedString("Bộ lọc:", comment: "Filter"))
                                .fontWeight(.medium)
                            Spacer()
                            Text(filterType)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(NSLocalizedString("Chi tiết ảnh", comment: "Image details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(NSLocalizedString("Đóng", comment: "Close"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveImageToPhotoLibrary()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .alert(NSLocalizedString("Xóa ảnh này?", comment: "Delete this image?"), isPresented: $showDeleteConfirmation) {
                Button(NSLocalizedString("Hủy", comment: "Cancel"), role: .cancel) { }
                Button(NSLocalizedString("Xóa", comment: "Delete"), role: .destructive) {
                    onDelete()
                }
            } message: {
                Text(NSLocalizedString("Ảnh sẽ bị xóa vĩnh viễn khỏi ứng dụng.", comment: "Image will be permanently deleted from the app"))
            }
        }
    }
    
    // Lưu ảnh vào thư viện ảnh của thiết bị
    private func saveImageToPhotoLibrary() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // Định dạng ngày giờ
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }
}
