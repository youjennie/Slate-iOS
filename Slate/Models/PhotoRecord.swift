import Foundation
import SwiftData
import UIKit
import ImageIO

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
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.createdAt = Date()
        self.remoteURL = remoteURL
    }
}

// Preview를 위한 Mock 데이터 생성기
extension PhotoRecord {
    static var mock: PhotoRecord {
        PhotoRecord(date: Date(), memo: "Today's Slate!", spaceTag: "Daily")
    }
}

// MARK: - 썸네일 (다운샘플 + 캐시) — 스크롤 성능
/// 그리드/달력 셀처럼 작게 보이는 곳에서 풀해상도 원본을 통째로 디코딩하면
/// 메인스레드가 막혀 스크롤이 끊긴다. ImageIO로 '표시 크기만큼만' 디코딩하고
/// NSCache에 담아 재사용한다. (원본 imageData는 그대로 보존)
enum ThumbnailCache {
    static let shared = NSCache<NSString, UIImage>()
}

extension PhotoRecord {
    /// 표시용 다운샘플 썸네일. `maxPixel`은 포인트 기준(내부에서 화면 배율 적용).
    func thumbnail(maxPixel: CGFloat = 220) -> UIImage? {
        guard let data = imageData else { return nil }
        let key = "\(id.uuidString)#\(Int(maxPixel))" as NSString
        if let cached = ThumbnailCache.shared.object(forKey: key) { return cached }
        guard let image = PhotoRecord.downsample(data: data, maxPixel: maxPixel) else { return nil }
        ThumbnailCache.shared.setObject(image, forKey: key)
        return image
    }

    /// ImageIO 기반 다운샘플 — 전체 비트맵 디코딩 없이 썸네일만 생성(빠르고 메모리 적음).
    static func downsample(data: Data, maxPixel: CGFloat) -> UIImage? {
        let scale = UIScreen.main.scale
        let srcOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOptions) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel * scale
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}
