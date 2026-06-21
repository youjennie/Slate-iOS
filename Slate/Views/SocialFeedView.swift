import SwiftUI

// MARK: - [1] 소셜 피드 메인 화면
struct SocialFeedView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SocialFeedTab = .all

    // 데이터 공급자 — 백엔드 연결 시 RemoteFeedProvider로 교체
    private let provider: FeedProvider = SampleFeedProvider()

    private var items: [FeedItem] { provider.feed(for: selectedTab) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 커스텀 상단 헤더
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    // Following / All 토글
                    HStack(spacing: 0) {
                        TabButton(title: "Following", isSelected: selectedTab == .following) {
                            selectedTab = .following
                        }
                        TabButton(title: "All", isSelected: selectedTab == .all) {
                            selectedTab = .all
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                    Spacer()

                    // 우측 밸런스용 투명 아이콘
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.9))

                // 피드 리스트 (데이터 주도)
                ScrollView {
                    VStack(spacing: 20) {
                        if items.isEmpty {
                            VStack(spacing: 12) {
                                Spacer(minLength: 160)
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text(selectedTab == .following ? "Follow people to see their streaks." : "No moments yet.")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(items) { item in
                                FeedItemView(item: item)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - [2] 개별 피드 카드 뷰
struct FeedItemView: View {
    let item: FeedItem

    @State private var isFollowing: Bool

    init(item: FeedItem) {
        self.item = item
        _isFollowing = State(initialValue: item.isFollowing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더: 프로필 & 이름 & 팔로우 버튼
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Text(item.authorName.prefix(1)).fontWeight(.bold))

                VStack(alignment: .leading) {
                    Text(item.authorName).fontWeight(.bold)
                    Text(item.timeAgo).font(.caption).foregroundColor(.gray)
                }

                Spacer()

                // 팔로우 토글 버튼
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFollowing.toggle()
                    }
                    if isFollowing {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFollowing ? Color.gray.opacity(0.1) : Color.black)
                    .foregroundColor(isFollowing ? .black : .white)
                    .cornerRadius(10)
                }
            }

            Text("\(item.authorName) has completed a \(item.activity) \(item.streakLabel) streak.")
                .font(.system(size: 15))

            // 사진 그리드 (플레이스홀더 — 백엔드 연결 시 실제 썸네일로)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...max(item.photoCount, 1), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 65)
                        .overlay(
                            Text("\(i)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6),
                            alignment: .topLeading
                        )
                }
            }

            Text("Show your support!")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            // 리액션 버튼 섹션 (데이터 주도)
            HStack(spacing: 12) {
                ForEach(item.reactions) { reaction in
                    ReactionButton(emoji: reaction.emoji, count: reaction.count)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - [3] 리액션 버튼 (K 단위 변환 포함)
struct ReactionButton: View {
    let emoji: String
    @State var count: Int
    @State private var isClicked: Bool = false

    var formattedCount: String {
        if count >= 1000 {
            let kValue = Double(count) / 1000.0
            return String(format: kValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fk" : "%.1fk", kValue)
        } else {
            return "\(count)"
        }
    }

    var body: some View {
        Button(action: {
            if isClicked {
                count -= 1
            } else {
                count += 1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            isClicked.toggle()
        }) {
            HStack(spacing: 4) {
                Text(emoji)
                Text(formattedCount)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isClicked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isClicked ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
            .foregroundColor(isClicked ? .black : .gray)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }
}

// MARK: - [4] 헤더 토글 버튼
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(18)
                .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 4)
                .padding(2)
        }
    }
}

// MARK: - [5] Preview
#Preview {
    NavigationStack {
        SocialFeedView()
    }
}
