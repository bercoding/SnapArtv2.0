import Foundation

struct Language: Identifiable, Codable {
    let id = UUID()
    let code: String
    let name: String
    let englishName: String
    let flag: String
}
