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

/// 피드 데이터 공급자 추상화.
/// 백엔드(Firebase) 연결 시 `RemoteFeedProvider`로 교체하면 View는 그대로 둘 수 있다.
protocol FeedProvider {
    func feed(for tab: SocialFeedTab) -> [FeedItem]
}

/// 백엔드 연결 전 임시 샘플 데이터.
/// ⚠️ 실제 소셜 기능은 Firebase(또는 별도 백엔드) 연동이 필요 — CloudSyncService 참고.
struct SampleFeedProvider: FeedProvider {
    func feed(for tab: SocialFeedTab) -> [FeedItem] {
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
