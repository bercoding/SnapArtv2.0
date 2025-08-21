import Foundation

struct FilterConfiguration {
    // Các chỉ số landmark cho đường viền khuôn mặt
    static let faceContourIndices: [Int] = [
        10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288,
        397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136,
        172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109
    ]
    
    // Các chỉ số landmark cho mắt trái
    static let leftEyeIndices: [Int] = [
        33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246
    ]
    
    // Các chỉ số landmark cho mắt phải
    static let rightEyeIndices: [Int] = [
        362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398
    ]
    
    // Các chỉ số landmark cho miệng
    static let mouthIndices: [Int] = [
        61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146
    ]
} 