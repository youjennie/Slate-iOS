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
    /// Firebase SDK가 링크되어 있고 GoogleService-Info.plist가 번들에 있으면 true.
    /// → 이 조건이 충족되면 자동으로 RemoteFeedProvider를 쓴다. (수동 토글 불필요)
    static var isConfigured: Bool {
        #if canImport(FirebaseFirestore)
        return Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil
        #else
        return false
        #endif
    }

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

// MARK: - 원격(Firestore) 공급자
/// Firebase 연결 절차:
///  3) Xcode ▸ Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk`
///     (FirebaseFirestore, FirebaseStorage, FirebaseAuth 체크)
///  4) Firebase 콘솔에서 `GoogleService-Info.plist` 받아 앱 타깃에 추가
///     (SlateApp.init이 plist 감지 시 자동 FirebaseApp.configure())
///  5) → 아래 코드가 `#if canImport(FirebaseFirestore)`로 자동 활성화된다.
///
/// Firestore 스키마(권장):
///   posts/{postId}      : authorUid, authorName, activity, streakLabel,
///                         photoCount, photoURLs[], isPublic, createdAt, reactions{emoji:count}
///   follows/{myUid}/list/{targetUid} : (팔로우 그래프)
struct RemoteFeedProvider: FeedProvider {
    func feed(for tab: SocialFeedTab) async throws -> [FeedItem] {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let myUid = Auth.auth().currentUser?.uid
        let following = (myUid != nil) ? try await followedUids(of: myUid!, db: db) : []

        var query: Query = db.collection("posts").order(by: "createdAt", descending: true).limit(to: 50)
        switch tab {
        case .following:
            guard !following.isEmpty else { return [] }
            // Firestore `in`은 최대 30개 → 우선 30개로 제한(추후 페이징/팬아웃)
            query = query.whereField("authorUid", in: Array(following.prefix(30)))
        case .all:
            query = query.whereField("isPublic", isEqualTo: true)
        }

        let snap = try await query.getDocuments()
        let followSet = Set(following)
        return snap.documents.compactMap { FeedItem(doc: $0.data(), following: followSet) }
        #else
        throw FeedError.notConfigured
        #endif
    }

    #if canImport(FirebaseFirestore)
    private func followedUids(of uid: String, db: Firestore) async throws -> [String] {
        let snap = try await db.collection("follows").document(uid).collection("list").getDocuments()
        return snap.documents.map { $0.documentID }
    }
    #endif
}

// MARK: - 피드 발행(업로드) — 프라이버시 게이트 적용 지점
/// 스트릭 달성 시 호출. Photo Privacy가 켜져 있으면(=비공개) 사진 없이/비공개로 올린다.
enum FeedPublisher {
    static func publishStreak(activity: String,
                              streakLabel: String,
                              authorName: String,
                              photoData: [Data]) async {
        guard FeedBackend.isConfigured else { return }   // 백엔드 없으면 no-op
        let isPrivate = FeedBackend.isPhotoPrivate

        #if canImport(FirebaseFirestore)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        var photoURLs: [String] = []
        // 공개일 때만 사진 업로드 (비공개면 사진 없이 기록만)
        if !isPrivate {
            #if canImport(FirebaseStorage)
            for (i, data) in photoData.enumerated() {
                let ref = Storage.storage().reference()
                    .child("posts/\(uid)/\(Int(Date().timeIntervalSince1970))_\(i).jpg")
                do {
                    _ = try await ref.putDataAsync(data)
                    photoURLs.append(try await ref.downloadURL().absoluteString)
                } catch { /* 업로드 실패 사진은 스킵 */ }
            }
            #endif
        }

        let doc: [String: Any] = [
            "authorUid": uid,
            "authorName": authorName,
            "activity": activity,
            "streakLabel": streakLabel,
            "photoCount": photoData.count,
            "photoURLs": photoURLs,
            "isPublic": !isPrivate,
            "reactions": [:],
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("posts").addDocument(data: doc)
        #else
        _ = (activity, streakLabel, authorName, photoData, isPrivate)
        #endif
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

extension FeedItem {
    /// Firestore posts 문서 → FeedItem 매핑
    init?(doc: [String: Any], following: Set<String>) {
        guard let authorUid = doc["authorUid"] as? String,
              let activity = doc["activity"] as? String else { return nil }
        let authorName = doc["authorName"] as? String ?? "Someone"
        let streakLabel = doc["streakLabel"] as? String ?? ""
        let photoCount = doc["photoCount"] as? Int ?? 0

        // createdAt(Timestamp) → "3 hours ago"
        var timeAgo = ""
        if let ts = doc["createdAt"] as? Timestamp {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .full
            timeAgo = f.localizedString(for: ts.dateValue(), relativeTo: Date())
        }

        // reactions{emoji:count} → [FeedReaction]
        let raw = doc["reactions"] as? [String: Int] ?? [:]
        let reactions = raw.map { FeedReaction(emoji: $0.key, count: $0.value) }

        self.init(authorName: authorName,
                  timeAgo: timeAgo,
                  activity: activity,
                  streakLabel: streakLabel,
                  isFollowing: following.contains(authorUid),
                  reactions: reactions,
                  photoCount: photoCount)
    }
}
#endif
