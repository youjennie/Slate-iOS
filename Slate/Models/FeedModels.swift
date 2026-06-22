import Foundation

/// 소셜 피드 한 건의 리액션 (이모지 + 개수)
struct FeedReaction: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var count: Int
}

/// 소셜 피드 아이템 (백엔드 응답을 그대로 매핑할 수 있는 형태)
struct FeedItem: Identifiable, Equatable {
    let id = UUID()
    let authorName: String
    let timeAgo: String
    let activity: String        // 예: "Yoga"
    let streakLabel: String      // 예: "one-week"
    var isFollowing: Bool
    var reactions: [FeedReaction]
    let photoCount: Int
}

enum SocialFeedTab {
    case following, all
}

/// 피드 로딩 에러
enum FeedError: Error, LocalizedError {
    case notConfigured
    case network(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Social feed isn't connected yet."
        case .network(let m): return m
        }
    }
}

/// 피드 데이터 공급자 추상화 (async).
/// 백엔드(Firebase) 연결 시 `RemoteFeedProvider`로 교체하면 View는 그대로 둘 수 있다.
protocol FeedProvider {
    func feed(for tab: SocialFeedTab) async throws -> [FeedItem]
}

/// 백엔드 연결 전 임시 샘플 데이터.
/// ⚠️ 실제 소셜 기능은 Firebase(또는 별도 백엔드) 연동이 필요 — CloudSyncService 참고.
struct SampleFeedProvider: FeedProvider {
    func feed(for tab: SocialFeedTab) async throws -> [FeedItem] {
        try? await Task.sleep(nanoseconds: 250_000_000)   // 네트워크 지연 흉내
        switch tab {
        case .following:
            return [
                FeedItem(authorName: "Lin", timeAgo: "3 hours ago", activity: "Yoga",
                         streakLabel: "one-week", isFollowing: true,
                         reactions: [FeedReaction(emoji: "👍", count: 24),
                                     FeedReaction(emoji: "👏", count: 1250),
                                     FeedReaction(emoji: "🎉", count: 8)],
                         photoCount: 5),
                FeedItem(authorName: "Mina", timeAgo: "1 day ago", activity: "Yoga",
                         streakLabel: "one-month", isFollowing: true,
                         reactions: [FeedReaction(emoji: "👍", count: 40),
                                     FeedReaction(emoji: "👏", count: 12),
                                     FeedReaction(emoji: "🎉", count: 3)],
                         photoCount: 5)
            ]
        case .all:
            return [
                FeedItem(authorName: "Global User", timeAgo: "Just now", activity: "Yoga",
                         streakLabel: "three-day", isFollowing: false,
                         reactions: [FeedReaction(emoji: "👍", count: 24),
                                     FeedReaction(emoji: "👏", count: 1250),
                                     FeedReaction(emoji: "🎉", count: 8)],
                         photoCount: 5)
            ]
        }
    }
}

// MARK: - 백엔드 연결 상태
enum FeedBackend {
    /// 백엔드(Firebase 등)가 연결되면 true. 그 전까지는 SampleFeedProvider 사용.
    /// Firebase 설정(2단계)을 끝내면 이 값을 true로 바꾼다.
    static var isConfigured: Bool { false }

    /// 사진 공유 여부 (Settings ▸ Photo Privacy와 동일 키). 기본 true=비공개.
    static var isPhotoPrivate: Bool {
        UserDefaults.standard.object(forKey: "slate_photoPrivacyEnabled") as? Bool ?? true
    }
}

/// 현재 환경에 맞는 공급자 (연결 전엔 샘플, 연결되면 원격)
enum FeedProviderFactory {
    static func current() -> FeedProvider {
        FeedBackend.isConfigured ? RemoteFeedProvider() : SampleFeedProvider()
    }
}

// MARK: - 원격(백엔드) 공급자 — Firebase 연결 지점
/// Firebase 연결 절차:
///  1) Xcode ▸ Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk`
///     (FirebaseFirestore, FirebaseStorage, FirebaseAuth 선택)
///  2) Firebase 콘솔에서 `GoogleService-Info.plist` 받아 프로젝트에 추가 +
///     SlateApp init에서 `FirebaseApp.configure()` 호출
///  3) `FeedBackend.isConfigured`를 true로, 아래 TODO를 Firestore 쿼리로 구현
struct RemoteFeedProvider: FeedProvider {
    func feed(for tab: SocialFeedTab) async throws -> [FeedItem] {
        guard FeedBackend.isConfigured else { throw FeedError.notConfigured }

        // TODO(Firebase): Firestore 조회 → FeedItem 매핑
        // import FirebaseFirestore
        // let db = Firestore.firestore()
        // let q: Query
        // switch tab {
        // case .following:
        //   // 내 팔로우 목록의 글: posts where authorUid in myFollowedUids
        //   q = db.collection("posts")
        //         .whereField("authorUid", in: try await myFollowedUids())
        //         .order(by: "createdAt", descending: true).limit(to: 50)
        // case .all:
        //   q = db.collection("posts")
        //         .whereField("isPublic", isEqualTo: true)
        //         .order(by: "createdAt", descending: true).limit(to: 50)
        // }
        // let snap = try await q.getDocuments()
        // return snap.documents.map { FeedItem(from: $0.data()) }
        throw FeedError.notConfigured
    }
}

// MARK: - 피드 발행(업로드) — 프라이버시 게이트 적용 지점
/// 스트릭 달성 시 호출. Photo Privacy가 켜져 있으면(=비공개) 사진 없이/비공개로 올린다.
enum FeedPublisher {
    static func publishStreak(activity: String,
                              streakLabel: String,
                              photoData: [Data]) async {
        guard FeedBackend.isConfigured else { return }   // 백엔드 없으면 no-op
        let isPrivate = FeedBackend.isPhotoPrivate

        // TODO(Firebase): posts 문서 작성
        //  - 공통: authorUid, activity, streakLabel, createdAt
        //  - isPrivate == true  → isPublic=false, photoURLs=[]  (사진 업로드 스킵)
        //  - isPrivate == false → Storage에 photoData 업로드 후 photoURLs 채우고 isPublic=true
        _ = (activity, streakLabel, photoData, isPrivate)
    }
}
