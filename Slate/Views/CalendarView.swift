import SwiftUI
import SwiftData

// MARK: - [1] 메인 캘린더 화면 (CalendarView)
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var inputImages: [UIImage] = []
    @State private var showCustomCamera = false
    
    // ── isDeleted == false인 레코드만 표시 ──
    @Query(
        filter: #Predicate<PhotoRecord> { $0.isDeleted == false },
        sort: \PhotoRecord.date
    ) private var activeRecords: [PhotoRecord]
    
    // ── Space 목록 로딩 (SwiftData) ──
    @Query(sort: \Space.createdAt) private var spaces: [Space]
    
    @ObservedObject var spaceManager = SpaceManager.shared
    
    @State private var selectedCategory = "Daily"
    @State private var navigateToCreateSpace = false
    @State private var showWallet = false
    @State private var showImagePicker = false
    @State private var photoDate: Date?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var currentTime = Date()
    @State private var showActionSheet = false
    @State private var targetDate: Date = Date()
    // ── UC-04: 과거 날짜 편집 게이트 대상 (광고 3회 후 편집 허용) ──
    @State private var pastEditTarget: PastEditTarget? = nil

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // ── 동적 월 범위: 오늘 ±6개월 기본 + 기록이 있는 달은 범위 밖이라도 무조건 포함 ──
    private var monthInterval: [Date] {
        let calendar = Calendar.current
        func monthStart(_ date: Date) -> Date {
            calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        }
        // 기본 윈도우: 입력이 없어도 앞뒤 6개월
        var start = monthStart(calendar.date(byAdding: .month, value: -6, to: Date())!)
        var end   = monthStart(calendar.date(byAdding: .month, value: 6, to: Date())!)
        // 기록이 있는 달까지 확장 (6개월을 넘어가도)
        let recordMonths = activeRecords.map { monthStart($0.date) }
        if let earliest = recordMonths.min(), earliest < start { start = earliest }
        if let latest = recordMonths.max(), latest > end { end = latest }

        var months: [Date] = []
        var current = start
        while current <= end {
            months.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }
        return months
    }

    private var currentMonthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        GeometryReader { outerGeometry in
            let totalWidth = outerGeometry.size.width
            
            VStack(spacing: 0) {
                // (A) 헤더 섹션
                CalendarHeaderView(currentTime: currentTime)
                
                // (B) 카테고리 선택 섹션
                CalendarCategorySelector(selectedCategory: $selectedCategory,
                                        navigateToCreateSpace: $navigateToCreateSpace,
                                        showWallet: $showWallet,
                                        spaceManager: spaceManager)
                
                // (C) 메인 캘린더 리스트
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 45) {
                            ForEach(monthInterval, id: \.self) { month in
                                MonthSectionView(month: month,
                                                 showActionSheet: $showActionSheet,
                                                 targetDate: $targetDate,
                                                 pastEditTarget: $pastEditTarget,
                                                 allRecords: activeRecords,
                                                 totalWidth: totalWidth,
                                                 selectedCategory: selectedCategory)
                                    .id(month)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 150)
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo(currentMonthStart, anchor: .top)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToCreateSpace) {
                CreateSpaceView()
            }
            .confirmationDialog("Add your moment", isPresented: $showActionSheet, titleVisibility: .visible) {
                Button("Take a Photo") { showCustomCamera = true }
                Button("Choose from Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $inputImages, detectedDate: photoDate ?? targetDate)
                    .onDisappear {
                        saveSelectedImages()
                    }
            }
            .fullScreenCover(isPresented: $showCustomCamera) {
                NavigationStack {
                    CameraView(selectedCategory: selectedCategory)
                        .environmentObject(SpaceManager.shared)
                }
            }
            // ── UC-04: 과거 날짜 편집 게이트 (광고 3회 → 편집 허용) ──
            .fullScreenCover(item: $pastEditTarget) { target in
                AdGateView(date: target.date) {
                    // 광고 3회 완료 → 해당 과거 날짜 추가 플로우 진행
                    targetDate = target.date
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        showActionSheet = true
                    }
                }
            }
            .sheet(isPresented: $showWallet) {
                SpacesWalletView(selectedCategory: $selectedCategory) {
                    navigateToCreateSpace = true
                }
                .presentationDetents([.large, .medium])
            }
        }
        .slatePaperBackground()
        .onReceive(timer) { currentTime = $0 }
        .onAppear {
            // ── Space 카테고리 동기화 ──
            spaceManager.syncCategories(from: spaces)
            // ── joinDate 기록 (최초 1회) ──
            if UserDefaults.standard.object(forKey: "slate_joinDate") == nil {
                UserDefaults.standard.set(Date(), forKey: "slate_joinDate")
            }
        }
        .onChange(of: spaces) { _, newSpaces in
            spaceManager.syncCategories(from: newSpaces)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // 사진 저장 로직
    private func saveSelectedImages() {
        for img in inputImages {
            let data = img.jpegData(compressionQuality: 0.7)
            let newRecord = PhotoRecord(
                date: targetDate,
                memo: "",
                imageData: data,
                spaceTag: selectedCategory
            )
            modelContext.insert(newRecord)
        }
        try? modelContext.save()
        inputImages = []
    }
}

// MARK: - [2] 커스텀 헤더 뷰 (CalendarHeaderView)
struct CalendarHeaderView: View {
    let currentTime: Date

    // TODO: 소셜 백엔드(Firebase) 연동 시 실제 미확인 알림 여부로 구동.
    //       그 전까지는 가짜 배지를 띄우지 않도록 false.
    @State private var hasNotification: Bool = false
    @State private var animateGlow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    NavigationLink(destination: SocialFeedView()) {
                        ZStack {
                            if hasNotification {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(white: 0.85).opacity(animateGlow ? 0.8 : 0.1),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 2,
                                            endRadius: 20
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .scaleEffect(animateGlow ? 1.1 : 1.0)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                            animateGlow = true
                                        }
                                    }
                            }
                            
                            Image(systemName: hasNotification ? "bell.badge" : "bell")
                                .font(.system(size: 17))
                                .foregroundColor(SlateColor.ink)
                        }
                        .padding(.leading, 16)
                    }
                    
                    Spacer()
                
                    NavigationLink(destination: RecentlyDeletedView()) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(SlateColor.inkSoft)
                            .padding(.trailing, 16)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(currentTime.formatted(date: .complete, time: .omitted))
                        .font(.system(size: 14, weight: .medium))
                    Text(currentTime.formatted(date: .omitted, time: .shortened) + " PST")
                        .font(.system(size: 11))
                        .foregroundColor(SlateColor.inkSoft)
                }
            }
            .frame(height: 50)
        }
        .padding(.vertical, 5)
        .background(SlateColor.paperSoft)
    }
}

// MARK: - [3] 카테고리 탭 선택기
struct CalendarCategorySelector: View {
    @Binding var selectedCategory: String
    @Binding var navigateToCreateSpace: Bool
    @Binding var showWallet: Bool
    @ObservedObject var spaceManager: SpaceManager
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // 월렛(지갑) 열기
                Button(action: { showWallet = true }) {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundColor(SlateColor.leafDeep)
                        .font(.system(size: 18))
                }
                ForEach(spaceManager.categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 5) {
                            Text(SlateEmoji.forSpace(named: category)).font(.system(size: 13))
                            Text(category)
                                .font(.system(size: 16, weight: selectedCategory == category ? .bold : .medium))
                        }
                        .foregroundColor(selectedCategory == category ? SlateColor.ink : SlateColor.inkFaint)
                        .padding(.bottom, 5)
                        .overlay(Rectangle().fill(selectedCategory == category ? SlateColor.leafDeep : Color.clear).frame(height: 2).offset(y: 5), alignment: .bottom)
                    }
                }
                Button(action: { navigateToCreateSpace = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(SlateColor.inkFaint).font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - [4] 월별 섹션 뷰 (MonthSectionView)
struct MonthSectionView: View {
    let month: Date
    @Binding var showActionSheet: Bool
    @Binding var targetDate: Date
    @Binding var pastEditTarget: PastEditTarget?
    let allRecords: [PhotoRecord]
    let totalWidth: CGFloat
    let selectedCategory: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 10) {
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.slateSans(26, weight: .bold))
                
                NavigationLink(destination: MonthShareDetailView(
                                    month: month,
                                    records: allRecords.filter {
                                        Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) &&
                                        $0.spaceTag == selectedCategory
                                    },
                                    category: selectedCategory
                                )) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundColor(SlateColor.ink)
                                }
            }
            .padding(.horizontal, 24)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...31, id: \.self) { day in
                    if let date = Calendar.current.date(byAdding: .day, value: day-1, to: month),
                       Calendar.current.isDate(date, equalTo: month, toGranularity: .month) {
                        
                        let recordsForDate = allRecords.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.spaceTag == selectedCategory
                        }
                        let cellSize = (totalWidth - 80) / 5
                        
                        if recordsForDate.isEmpty {
                            Button(action: {
                                // UC-04: 과거 날짜는 광고 게이트를 거친 뒤 추가, 오늘/이후는 바로 추가
                                if date < Calendar.current.startOfDay(for: Date()) {
                                    pastEditTarget = PastEditTarget(date: date)
                                } else {
                                    targetDate = date
                                    showActionSheet = true
                                }
                            }) {
                                CalendarCell(day: day, size: cellSize, photoCount: 0, firstImage: nil)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: DailyPhotoView(date: date, selectedCategory: selectedCategory)) {
                                CalendarCell(day: day, size: cellSize, photoCount: recordsForDate.count,
                                            firstImage: recordsForDate.first?.thumbnail(maxPixel: cellSize))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - [5] 캘린더 개별 날짜 셀 (CalendarCell)
struct CalendarCell: View {
    let day: Int
    let size: CGFloat
    let photoCount: Int
    let firstImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let uiImage = firstImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
            } else {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color.white)
                    .overlay(Image(systemName: "photo")
                        .foregroundColor(SlateColor.inkFaint.opacity(0.1))
                        .font(.system(size: size * 0.3)))
            }
            
            Text("\(day)")
                .font(.system(size: size * 0.18, weight: .bold))
                .padding(size * 0.1)
                .foregroundColor(firstImage == nil ? SlateColor.inkFaint.opacity(0.5) : .white)
            
            if photoCount > 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(photoCount)")
                            .font(.system(size: 9, weight: .bold))
                            .padding(5)
                            .background(SlateColor.ink.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: SlateColor.ink.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - [6] 과거 날짜 편집 게이트 (UC-04: 리워드 광고 3회)

/// 과거 날짜 편집 대상 (fullScreenCover item용)
struct PastEditTarget: Identifiable {
    let id = UUID()
    let date: Date
}

/// 리워드 광고 시퀀스 매니저.
/// AdMob SDK(SPM) 추가 전에는 시뮬레이션으로 게이트가 실제 동작한다.
/// SDK를 추가하면 `#if canImport(GoogleMobileAds)` 블록의 실제 광고로 교체하면 된다.
final class RewardedAds {
    static let shared = RewardedAds()
    private init() {}

    /// count개의 리워드 광고를 순차 재생. 각 광고 완료 시 progress(누적 시청수) 호출.
    /// 전부 완료 시 true, 중간 이탈/실패 시 false.
    func showSequence(count: Int, progress: @escaping (Int) async -> Void) async -> Bool {
        #if canImport(GoogleMobileAds)
        // TODO(AdMob): 여기서 GADRewardedAd를 count회 로드→present.
        //   각 onUserEarnedReward에서 progress(누적) 호출, 마지막 성공 시 true.
        //   광고 로드 실패/유저 이탈 시 false 반환(편집 잠금 유지).
        //   SDK 추가 전까지는 아래 시뮬레이션을 사용.
        return await simulate(count: count, progress: progress)
        #else
        return await simulate(count: count, progress: progress)
        #endif
    }

    private func simulate(count: Int, progress: @escaping (Int) async -> Void) async -> Bool {
        for i in 1...count {
            try? await Task.sleep(nanoseconds: 1_200_000_000)   // 광고 1편 재생 흉내
            await progress(i)
        }
        return true
    }
}

/// SCR-06: 과거 기록 추가/수정 안내 + 광고 시청 게이트
struct AdGateView: View {
    let date: Date
    var onUnlock: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var watching = false
    @State private var watched = 0
    private let total = 3

    private var dateText: String {
        date.formatted(.dateTime.month(.wide).day().year())
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 46, weight: .regular))
                .foregroundColor(SlateColor.leafDeep)

            VStack(spacing: 8) {
                Text("Add to a past day")
                    .font(.slateSans(21, weight: .bold))
                    .foregroundColor(SlateColor.ink)
                Text(dateText)
                    .font(.slateSans(13, weight: .semibold))
                    .foregroundColor(SlateColor.inkSoft)
            }

            Text("To add or edit a record on a past day,\nplease watch \(total) short ads.")
                .font(.slateSans(14))
                .foregroundColor(SlateColor.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if watching {
                VStack(spacing: 10) {
                    ProgressView(value: Double(watched), total: Double(total))
                        .tint(SlateColor.leaf)
                        .frame(maxWidth: 220)
                    Text("Ad \(min(watched + 1, total)) of \(total)…")
                        .font(.slateSans(12, weight: .semibold))
                        .foregroundColor(SlateColor.inkSoft)
                }
                .padding(.top, 4)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: start) {
                    Text(watching ? "Watching…" : "Watch \(total) ads & continue")
                        .font(.slateSans(16, weight: .bold))
                        .foregroundColor(SlateColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(watching ? SlateColor.inkFaint : SlateColor.leaf))
                }
                .disabled(watching)

                Button("Not now") { dismiss() }
                    .font(.slateSans(14, weight: .semibold))
                    .foregroundColor(SlateColor.inkSoft)
                    .disabled(watching)
            }
            .padding(.horizontal, 8)

            Spacer().frame(height: 16)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slatePaperBackground()
        .interactiveDismissDisabled(watching)   // 광고 도중 스와이프로 못 닫음(이탈 방지)
    }

    private func start() {
        watching = true
        watched = 0
        Task {
            let ok = await RewardedAds.shared.showSequence(count: total) { done in
                await MainActor.run { watched = done }
            }
            await MainActor.run {
                if ok {
                    onUnlock()
                    dismiss()
                } else {
                    watching = false   // 이탈/실패 → 잠금 유지
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    return MainTabView()
        .modelContainer(container)
        .environmentObject(SpaceManager.shared)
}
