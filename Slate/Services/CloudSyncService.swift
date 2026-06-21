import Foundation

/// 사진/스페이스의 클라우드 동기화 추상화.
///
/// 현재는 **로컬 전용(no-op)** 구현만 존재하므로 앱은 SwiftData를 단일 소스로 동작한다.
/// Firebase를 붙일 때는 아래 단계만 따르면 이 프로토콜의 구현체만 갈아끼우면 된다:
///
/// 1) Xcode → File ▸ Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk`
///    (FirebaseAuth, FirebaseFirestore, FirebaseStorage 선택)
/// 2) Firebase 콘솔에서 iOS 앱 등록 후 `GoogleService-Info.plist`를 Slate/ 에 추가
/// 3) SlateApp 진입점에서 `FirebaseApp.configure()` 호출
/// 4) 아래 `FirebaseCloudSyncService`(주석 참고)를 구현해서 `LocalCloudSyncService` 대신 주입
///
/// PhotoRecord에는 이미 `remoteURL`, `createdAt` 필드가 준비돼 있어 업로드 결과를 바로 저장할 수 있다.
protocol CloudSyncService {
    /// 동기화 활성 여부
    var isEnabled: Bool { get }
    /// 단일 레코드 업로드 → 반환값은 원격 URL(remoteURL에 저장)
    func upload(record: PhotoRecord) async throws -> String?
    /// 원격 파일 삭제
    func deleteRemote(urlString: String) async throws
    /// 전체 동기화 (앱 시작 시 등)
    func syncAll(records: [PhotoRecord]) async throws
}

/// 기본 구현: 아무것도 하지 않는 로컬 전용 모드.
/// Firebase 연결 전까지 앱이 정상 동작하도록 보장한다.
final class LocalCloudSyncService: CloudSyncService {
    static let shared = LocalCloudSyncService()
    private init() {}

    var isEnabled: Bool { false }
    func upload(record: PhotoRecord) async throws -> String? { nil }
    func deleteRemote(urlString: String) async throws {}
    func syncAll(records: [PhotoRecord]) async throws {}
}

// MARK: - Firebase 연결 시 참고용 골격 (SDK 추가 후 주석 해제하여 구현)
//
// import FirebaseStorage
// import FirebaseFirestore
//
// final class FirebaseCloudSyncService: CloudSyncService {
//     var isEnabled: Bool { true }
//
//     func upload(record: PhotoRecord) async throws -> String? {
//         guard let data = record.imageData else { return nil }
//         let ref = Storage.storage().reference().child("photos/\(record.id.uuidString).jpg")
//         _ = try await ref.putDataAsync(data)
//         let url = try await ref.downloadURL().absoluteString
//         record.remoteURL = url
//         return url
//     }
//
//     func deleteRemote(urlString: String) async throws {
//         try await Storage.storage().reference(forURL: urlString).delete()
//     }
//
//     func syncAll(records: [PhotoRecord]) async throws {
//         for record in records where record.remoteURL == nil && record.imageData != nil {
//             _ = try await upload(record: record)
//         }
//     }
// }
