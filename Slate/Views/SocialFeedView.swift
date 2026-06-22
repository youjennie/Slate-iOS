import SwiftUI

// MARK: - [1] 소셜 피드 메인 화면
struct SocialFeedView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SocialFeedTab = .all

    // 최초 진입 안내 카드 표시 여부 (한 번 닫으면 다시 안 뜸)
    @AppStorage("slate_socialFeedIntroSeen") private var introSeen = false
    // 사진 공유 여부 — Settings ▸ Photo Privacy와 동일 키 공유 (기본: 비공개)
    @AppStorage("slate_photoPrivacyEnabled") private var photoPrivate = true

    // 데이터 공급자 — 백엔드 연결되면 자동으로 RemoteFeedProvider 사용
    private let provider: FeedProvider = FeedProviderFactory.current()

    @State private var items: [FeedItem] = []
    @State private var isLoading = false
    @State private var loadError: String?

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            items = try await provider.feed(for: selectedTab)
        } catch {
            items = []
            loadError = (error as? FeedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    var body: some View {
            VStack(spacing: 0) {
                // 커스텀 상단 헤더
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(SlateColor.ink)
                            .frame(width: 42, height: 42)          // 탭 영역 확보
                            .background(Circle().fill(SlateColor.sand))
                            .contentShape(Circle())
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
                    .background(SlateColor.inkFaint.opacity(0.1))
                    .cornerRadius(20)

                    Spacer()

                    // 우측 밸런스용 투명 아이콘
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(SlateColor.paperSoft)

                // 피드 리스트 (데이터 주도)
                ScrollView {
                    VStack(spacing: 20) {
                        // 최초 오픈 시 1회 안내 카드
                        if !introSeen {
                            introCard
                        }

                        if isLoading {
                            ProgressView()
                                .tint(SlateColor.leafDeep)
                                .padding(.top, 80)
                        } else if let loadError {
                            VStack(spacing: 12) {
                                Spacer(minLength: 140)
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 38))
                                    .foregroundColor(SlateColor.inkFaint.opacity(0.4))
                                Text(loadError)
                                    .font(.slateSans(14))
                                    .foregroundColor(SlateColor.inkSoft)
                                    .multilineTextAlignment(.center)
                                Button("Retry") { Task { await load() } }
                                    .font(.slateSans(14, weight: .bold))
                                    .foregroundColor(SlateColor.leafDeep)
                            }
                        } else if items.isEmpty {
                            VStack(spacing: 12) {
                                Spacer(minLength: 160)
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(SlateColor.inkFaint.opacity(0.3))
                                Text(selectedTab == .following ? "Follow people to see their streaks." : "No moments yet.")
                                    .foregroundColor(SlateColor.inkSoft)
                            }
                        } else {
                            ForEach(items) { item in
                                FeedItemView(item: item)
                            }
                        }
                    }
                    .padding()
                }
                .task(id: selectedTab) { await load() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .slatePaperBackground()
            .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 최초 오픈 안내 카드
    private var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("🌱")
                    .font(.system(size: 22))
                Text("Cheer each other on")
                    .font(.slateSans(17, weight: .bold))
                    .foregroundColor(SlateColor.ink)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) { introSeen = true }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(SlateColor.inkSoft)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(SlateColor.sand))
                }
            }

            Text("This is where you see friends keeping their streaks going — send a 👏 to keep them growing.")
                .font(.slateSans(13))
                .foregroundColor(SlateColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            // 프라이버시 안내 — Photo Privacy 설정과 직접 연결됨
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: photoPrivate ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SlateColor.leafDeep)
                    .padding(.top, 1)
                Text(photoPrivate
                     ? "Your photos stay private. They're only shared here when you turn off **Photo Privacy** in Settings."
                     : "**Photo Privacy is off** — your streak photos can appear in others' feeds. Turn it back on in Settings anytime.")
                    .font(.slateSans(12))
                    .foregroundColor(SlateColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(SlateColor.leafSoft.opacity(0.5)))

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) { introSeen = true }
            }) {
                Text("Got it")
                    .font(.slateSans(14, weight: .bold))
                    .foregroundColor(SlateColor.paperSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(SlateColor.ink))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(SlateColor.paperSoft)
                .shadow(color: SlateColor.ink.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(SlateColor.leaf.opacity(0.35), lineWidth: 1)
        )
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
                    .fill(SlateColor.inkFaint.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Text(item.authorName.prefix(1)).fontWeight(.bold))

                VStack(alignment: .leading) {
                    Text(item.authorName).fontWeight(.bold)
                    Text(item.timeAgo).font(.caption).foregroundColor(SlateColor.inkSoft)
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
                    .background(isFollowing ? SlateColor.leafSoft : SlateColor.ink)
                    .foregroundColor(isFollowing ? SlateColor.leafDeep : SlateColor.paperSoft)
                    .cornerRadius(10)
                }
            }

            Text("\(item.authorName) has completed a \(item.activity) \(item.streakLabel) streak.")
                .font(.system(size: 15))

            // 사진 그리드 (플레이스홀더 — 백엔드 연결 시 실제 썸네일로)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...max(item.photoCount, 1), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SlateColor.inkFaint.opacity(0.1))
                        .frame(height: 65)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(SlateColor.inkFaint.opacity(0.5)),
                            alignment: .center
                        )
                }
            }

            Text("Show your support!")
                .font(.system(size: 13))
                .foregroundColor(SlateColor.inkSoft)

            // 리액션 버튼 섹션 (데이터 주도)
            HStack(spacing: 12) {
                ForEach(item.reactions) { reaction in
                    ReactionButton(emoji: reaction.emoji, count: reaction.count)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlateColor.paperSoft)
        .cornerRadius(20)
        .shadow(color: SlateColor.ink.opacity(0.05), radius: 8, x: 0, y: 4)
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
            .background(isClicked ? SlateColor.inkFaint.opacity(0.2) : SlateColor.inkFaint.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isClicked ? SlateColor.inkFaint.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
            .foregroundColor(isClicked ? SlateColor.ink : SlateColor.inkSoft)
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
                .foregroundColor(isSelected ? SlateColor.ink : SlateColor.inkSoft)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? SlateColor.paperSoft : Color.clear)
                .cornerRadius(18)
                .shadow(color: isSelected ? SlateColor.ink.opacity(0.1) : .clear, radius: 4)
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
