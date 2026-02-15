import Foundation
import SwiftData

@Model
final class PhotoRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var memo: String
    @Attribute(.externalStorage) var imageData: Data?
    var spaceTag: String
    
    init(date: Date = Date(), memo: String = "", imageData: Data? = nil, spaceTag: String = "General") {
        self.id = UUID()
        self.date = date
        self.memo = memo
        self.imageData = imageData
        self.spaceTag = spaceTag
    }
}

// Preview를 위한 Mock 데이터 생성기
extension PhotoRecord {
    static var mock: PhotoRecord {
        PhotoRecord(date: Date(), memo: "오늘의 웰니스 기록!", spaceTag: "Daily")
    }
}
