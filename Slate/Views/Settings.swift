import SwiftUI
import SwiftData
import PhotosUI

// MARK: - [1] 설정 메인 뷰
struct MySlateSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var spaceManager = SpaceManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Query(sort: \Space.createdAt) private var spaces: [Space]
    @Query private var allRecords: [PhotoRecord]

    /// Space별 기록 수 (삭제 제외)
    private func momentCount(_ space: Space) -> Int {
        allRecords.filter { !$0.isDeleted && $0.spaceTag == space.name }.count
    }

    let slateWhite = SlateColor.leafDeep
    let slateGreen = SlateColor.leaf

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedBio = "아름다운 과정, 따라오는 결과"
    @State private var currentBio = "아름다운 과정, 따라오는 결과"
    
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var pickedImages: [UIImage] = []
    @State private var notificationsEnabled = true
    @State private var photoPrivacyEnabled = true
    
    // ── 계정 삭제 확인 다이얼로그 ──
    @State private var showDeleteConfirmation = false
    // ── 알림 권한 거부 안내 다이얼로그 ──
    @State private var showNotificationDeniedAlert = false
    // ── 미래자아 재생성 안내 다이얼로그 ──
    @State private var showRegenerateConfirm = false

    private var initials: String {
        let name = spaceManager.userName.isEmpty ? "User" : spaceManager.userName
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        // ⚠️ 배경은 modifier로 (ZStack+ignoresSafeArea는 콘텐츠에 무한 폭을 줘 가장자리가 잘림)
        VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(SlateColor.ink)
                            .padding(10)
                    }
                    Spacer()
                    Text("Settings").font(.system(size: 18, weight: .bold))
                        .foregroundColor(SlateColor.ink)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0).padding(10)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(SlateColor.paperSoft)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        profileHeaderSection
                        keywordSection
                        appearanceSection
                        settingListSection
                        footerSection
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slatePaperBackground()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            editedName = spaceManager.userName
            editedBio = currentBio
            profileImage = Self.loadProfileImage()
            notificationsEnabled = UserDefaults.standard.bool(forKey: "slate_notificationsEnabled")
        }
        // ── 프로필 사진 선택 (아바타 1장) ──
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $pickedImages, detectedDate: Date(), selectionLimit: 1)
        }
        .onChange(of: pickedImages) { _, newImages in
            if let img = newImages.first {
                profileImage = img
                Self.saveProfileImage(img)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        // ── 알림 토글 → 권한 요청 + 매일 리마인더 예약/취소 ──
        .onChange(of: notificationsEnabled) { _, enabled in
            UserDefaults.standard.set(enabled, forKey: "slate_notificationsEnabled")
            if enabled {
                NotificationService.shared.requestAuthorization { granted in
                    if granted {
                        NotificationService.shared.scheduleDailyReminder()
                    } else {
                        // 권한 거부 시 토글 원복 + 설정 이동 안내
                        notificationsEnabled = false
                        showNotificationDeniedAlert = true
                    }
                }
            } else {
                NotificationService.shared.cancelDailyReminder()
            }
        }
        .alert("Notifications Off", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enable notifications in Settings to get your daily Slate reminder.")
        }
        .alert("Future Image Reset", isPresented: $showRegenerateConfirm) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Open My Slate and tap the 'After' circle to generate a fresh future-self image.")
        }
        // ── 계정 삭제 확인 Alert ──
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("This will permanently delete all your photos, spaces, and account data. This action cannot be undone.")
        }
    }
    
    // MARK: - 하위 뷰 컴포넌트들
    
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            Button(action: { showImagePicker = true }) {
                ZStack {
                    Circle().fill(slateGreen).frame(width: 100, height: 100)
                    if let image = profileImage {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 100, height: 100).clipShape(Circle())
                    } else {
                        Text(initials).font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            
            if isEditing {
                VStack(spacing: 12) {
                    TextField("Name", text: $editedName)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    TextField("Bio", text: $editedBio)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    Button("Save Changes") {
                        spaceManager.userName = editedName
                        currentBio = editedBio
                        isEditing = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    .font(.headline).foregroundColor(slateWhite)
                }.frame(width: 300)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Text(spaceManager.userName.isEmpty ? "User Name" : spaceManager.userName).font(.system(size: 24, weight: .bold))
                        Button(action: { isEditing = true }) { Image(systemName: "pencil").foregroundColor(SlateColor.inkSoft) }
                    }
                    Text(currentBio).font(.system(size: 15)).foregroundColor(SlateColor.inkSoft).multilineTextAlignment(.center).padding(.horizontal, 40)
                    Text("Slate started on January 1, 2026").font(.system(size: 12)).foregroundColor(SlateColor.inkFaint.opacity(0.5))
                }
            }
        }
    }

    private var keywordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더: 타이틀 + 개수 pill
            HStack(spacing: 8) {
                Text("Your Spaces")
                    .font(.slateSans(16, weight: .bold))
                    .foregroundColor(SlateColor.ink)
                if !spaces.isEmpty {
                    Text("\(spaces.count)")
                        .font(.slateSans(12, weight: .bold))
                        .foregroundColor(SlateColor.leafDeep)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Capsule().fill(SlateColor.leafSoft))
                }
                Spacer()
            }
            .padding(.horizontal, 25)

            if spaces.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .font(.system(size: 18))
                        .foregroundColor(SlateColor.leafDeep)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(SlateColor.leafSoft))
                    Text("Create a space to start\ngrowing your collection.")
                        .font(.slateSans(13))
                        .foregroundColor(SlateColor.inkSoft)
                    Spacer()
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(SlateColor.paperSoft))
                .padding(.horizontal, 25)
            } else {
                // 스티커 셸프: 블롭 + 이름 + moments 카운트
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
                            spaceCard(space, index: index)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 6)
                }
            }
        }
    }

    /// Your Spaces 카드 — 블롭 스티커 + 이름 + moments 수
    private func spaceCard(_ space: Space, index: Int) -> some View {
        let color = SlateColor.forSpace(index)
        let count = momentCount(space)
        return VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                StickerBadge(
                    emoji: SlateEmoji.forSpace(named: space.name),
                    label: "",
                    color: color,
                    variant: index,
                    rotation: index % 2 == 0 ? -7 : 6,
                    size: 78
                )
                // 기록 수 버블
                Text("\(count)")
                    .font(.slateSans(11, weight: .bold))
                    .foregroundColor(SlateColor.paperSoft)
                    .frame(minWidth: 22, minHeight: 22)
                    .padding(.horizontal, 3)
                    .background(Circle().fill(SlateColor.ink))
                    .overlay(Circle().stroke(SlateColor.paperSoft, lineWidth: 2))
                    .offset(x: 6, y: -2)
            }
            VStack(spacing: 2) {
                Text(space.name)
                    .font(.slateSans(13, weight: .semibold))
                    .foregroundColor(SlateColor.ink)
                    .lineLimit(1)
                Text(count == 1 ? "1 moment" : "\(count) moments")
                    .font(.slateSans(10))
                    .foregroundColor(SlateColor.inkFaint)
            }
        }
        .frame(width: 96)
    }

    // ── 컬러 테마 선택 ──
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Point Color")
                .font(.slateSans(15, weight: .bold))
                .foregroundColor(SlateColor.ink)
                .padding(.horizontal, 25)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(SlateThemeID.allCases) { t in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { theme.themeID = t }
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            VStack(spacing: 8) {
                                HStack(spacing: 0) {
                                    ForEach(Array(t.swatch.enumerated()), id: \.offset) { _, c in
                                        Rectangle().fill(c).frame(width: 24, height: 48)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(theme.themeID == t ? SlateColor.ink : SlateColor.inkFaint.opacity(0.25),
                                                lineWidth: theme.themeID == t ? 2.5 : 1)
                                )
                                Text(t.label)
                                    .font(.slateSans(11, weight: theme.themeID == t ? .bold : .regular))
                                    .foregroundColor(theme.themeID == t ? SlateColor.ink : SlateColor.inkSoft)
                            }
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 2)
            }
        }
    }

    private var settingListSection: some View {
        VStack(spacing: 25) {
            settingGroup(title: "MY SLATE") {
                settingToggleRow(title: "Notifications", isOn: $notificationsEnabled)
            }
            
            settingGroup(title: "GROWTH DATA") {
                // AI 미래자아 사용 가능 여부 (Gemini 키 설정 상태)
                HStack {
                    Text("AI Future Self").font(.system(size: 16))
                    Spacer()
                    Text(SlateConfig.isImageGenerationAvailable ? "On" : "Set API key")
                        .font(.system(size: 14)).foregroundColor(SlateColor.inkSoft)
                }.padding(18)

                // 캐시를 비워 다음 My Slate 방문 시 재생성되도록
                Button(action: {
                    FutureSelfStore.clear()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showRegenerateConfirm = true
                }) {
                    HStack {
                        Text("Regenerate Future Image").font(.system(size: 16)).foregroundColor(SlateColor.ink)
                        Spacer()
                        Image(systemName: "arrow.clockwise").font(.system(size: 14)).foregroundColor(SlateColor.inkSoft)
                    }.padding(18)
                }
            }

            settingGroup(title: "PRIVACY") {
                settingToggleRow(title: "Photo Privacy", subtitle: "Only visible to you", isOn: $photoPrivacyEnabled)
                // ── 계정 삭제 → 확인 다이얼로그 연결 ──
                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete Account").font(.system(size: 16)).foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(SlateColor.inkSoft)
                    }.padding(18)
                }
            }

            #if DEBUG
            // ── 로컬 테스트용 (DEBUG 빌드에서만 보임) ──
            settingGroup(title: "DEBUG · LOCAL TEST") {
                Button(action: {
                    SampleData.seed(into: modelContext)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    HStack {
                        Text("Load sample data").font(.system(size: 16)).foregroundColor(SlateColor.leafDeep)
                        Spacer()
                        Image(systemName: "wand.and.stars").font(.system(size: 14)).foregroundColor(SlateColor.inkSoft)
                    }.padding(18)
                }
                Button(action: {
                    SampleData.clear(into: modelContext)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }) {
                    HStack {
                        Text("Clear all data").font(.system(size: 16)).foregroundColor(.red)
                        Spacer()
                        Image(systemName: "trash").font(.system(size: 14)).foregroundColor(SlateColor.inkSoft)
                    }.padding(18)
                }
            }
            #endif
        }.padding(.horizontal, 25)
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    spaceManager.logout()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("Sign out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            Text("Slate v1.0.0")
                .font(.system(size: 12))
                .foregroundColor(SlateColor.inkFaint.opacity(0.4))
        }
    }
    
    // ── 실제 계정 삭제 로직 ──
    private func performAccountDeletion() {
        // 1. SwiftData 전체 삭제
        do {
            let allRecords = try modelContext.fetch(FetchDescriptor<PhotoRecord>())
            for record in allRecords {
                modelContext.delete(record)
            }
            let allSpaces = try modelContext.fetch(FetchDescriptor<Space>())
            for space in allSpaces {
                modelContext.delete(space)
            }
            try modelContext.save()
        } catch {
            print("Account deletion error: \(error)")
        }
        
        // 2. UserDefaults 전체 초기화
        UserDefaults.standard.removeObject(forKey: "slate_joinDate")

        // 2-1. 프로필 이미지 / 미래자아 이미지 파일 삭제
        try? FileManager.default.removeItem(at: Self.profileImageURL)
        FutureSelfStore.clear()
        profileImage = nil

        // 3. SpaceManager 초기화 + 로그아웃
        spaceManager.deleteAccount()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // ── 프로필 이미지 영속화 (Application Support에 jpg로 저장) ──
    private static var profileImageURL: URL {
        URL.applicationSupportDirectory.appending(path: "slate_profile.jpg")
    }

    private static func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: profileImageURL)
    }

    private static func loadProfileImage() -> UIImage? {
        guard let data = try? Data(contentsOf: profileImageURL) else { return nil }
        return UIImage(data: data)
    }

    // --- 공통 부품 함수들 ---

    private func settingGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(SlateColor.inkSoft).padding(.leading, 5)
            VStack(spacing: 0) { content() }.background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.7)))
        }
    }

    private func settingToggleRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16))
                if let sub = subtitle { Text(sub).font(.system(size: 12)).foregroundColor(SlateColor.inkSoft) }
            }
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(SwitchToggleStyle(tint: slateGreen)).labelsHidden()
        }.padding(18)
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return NavigationStack {
        MySlateSettingsView()
            .modelContainer(container)
    }
}
