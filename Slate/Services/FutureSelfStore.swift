import UIKit

/// 생성된 '미래의 나' 이미지를 로컬에 영속화
/// (추후 Firebase Storage 백업은 CloudSyncService 단계에서 연결)
enum FutureSelfStore {
    private static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "slate_future_self.jpg")
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: fileURL)
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
