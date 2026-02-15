import Foundation
import SwiftData

@Model
final class PhotoRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var memo: String
    @Attribute(.externalStorage) var imageData: Data?
    var spaceTag: String
    
    // ── v1.0 추가 필드 ──
    var isDeleted: Bool       // soft delete 플래그
    var deletedAt: Date?      // 삭제 시점 (30일 자동 정리용)
    var createdAt: Date       // 생성 시점 (동기화용)
    var remoteURL: String?    // Firebase Storage URL (서버 백업용)
    
    init(
        date: Date = Date(),
        memo: String = "",
        imageData: Data? = nil,
        spaceTag: String = "Daily",
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        remoteURL: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.memo = memo
        self.imageData = imageData
        self.spaceTag = spaceTag
        self.isDeleted = false
        self.deletedAt = nil
        self.createdAt = Date()
        self.remoteURL = nil
    }
}

// Preview를 위한 Mock 데이터 생성기
extension PhotoRecord {
    static var mock: PhotoRecord {
        PhotoRecord(date: Date(), memo: "Today's Slate!", spaceTag: "Daily")
    }
}
