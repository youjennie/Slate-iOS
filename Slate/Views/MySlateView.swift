import SwiftUI
import SwiftData

struct MySlateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isCameraPresented = false

    // ── AI 미래자아 생성 상태 ──
    @State private var futureImage: UIImage? = nil
    @State private var isGenerating = false
    @State private var genErrorMessage = ""
    @State private var showGenError = false

    /// 뒤로가기 시 실행할 동작 (예: 탭바에서 Calendar 탭으로 전환)
    var onBack: (() -> Void)? = nil

    // ── SwiftData에서 실시간 데이터 로딩 ──
    @Query(sort: \PhotoRecord.date) private var allRecords: [PhotoRecord]
    // Before 이미지(시작점) 소스로 사용
    @Query(sort: \Space.createdAt) private var spaces: [Space]

    // 형님의 컨셉 컬러
    let slateWhite = Color(red: 183/255, green: 194/255, blue: 198/255)
    let slateGreen = Color(red: 186/255, green: 206/255, blue: 156/255)
    let cameraGreen = Color(red: 0.41, green: 0.81, blue: 0.44)

    // ── 실시간 계산 (하드코딩 제거) ──
    private var progress: SlateProgress {
        ProgressCalculator.calculate(from: allRecords)
    }

    /// "Before" = 시작점 사진. 기본 Space의 startingPhoto → 없으면 가장 오래된 기록 사진
    private var beforeImage: UIImage? {
        let startingData = spaces.first(where: { $0.isDefault })?.startingPhotoData
            ?? spaces.first?.startingPhotoData
        if let data = startingData, let img = UIImage(data: data) { return img }
        // allRecords는 date 오름차순 → 첫 사진이 가장 오래된 기록
        if let data = allRecords.first(where: { $0.imageData != nil })?.imageData,
           let img = UIImage(data: data) { return img }
        return nil
    }

    /// 미래 목표 문구 — 기본 Space의 futureMemo 사용
    private var futureGoal: String {
        spaces.first(where: { $0.isDefault })?.futureMemo
            ?? spaces.first?.futureMemo
            ?? ""
    }

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let screenHeight = proxy.size.height
            
            ZStack {
                // [1] 배경 레이어
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.98)
                    Image("background_paper")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenWidth)
                        .clipped()
                }
                .ignoresSafeArea()

                // [2] 콘텐츠 레이어
                VStack(spacing: 0) {
                    
                    // --- 상단 헤더 ---
                    HStack {
                        Button(action: { goBackToCalendar() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .padding(10)
                                .contentShape(Rectangle())
                        }
                        
                        Spacer()
                        
                        Text("My Slate")
                            .font(.system(size: 18, weight: .bold))
                        
                        Spacer()
                        
                        NavigationLink(destination: MySlateSettingsView()) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .padding(10)
                        }
                    }
                    .padding(.top, 10).padding(.bottom, 10)
                    .padding(.horizontal, 10)
                    .frame(height: 60)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 50) {
                            // 3. 로고 및 타이틀
                            VStack(spacing: 0) {
                                Image("name_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                    .padding(.bottom, -60)
                                    .padding(.top, -10)
                                
                                Text("Your Future-Self Awaits")
                                    .font(.system(size: 26, weight: .bold))
                                    .padding(.top, 5)
                                    .padding(.bottom, 10)
                                
                                Text("Slate turns your moments into\na picture of who you're becoming.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            .padding(.top, 30)

                            // 4. Before & After
                            HStack(spacing: 40) {
                                comparisonCircle(image: beforeImage, label: "Before", isFuture: false)
                                futureCircle
                            }

                            // 5. 프로그레스 섹션 (실시간 계산)
                            VStack(spacing: 20) {
                                // ── 실시간 계산된 Progress % ──
                                Text("\(Int(progress.progressPercent))% closer")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 12) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.black.opacity(0.05)).frame(height: 12)
                                            Capsule()
                                                .fill(slateWhite)
                                                .frame(width: geo.size.width * CGFloat(progress.progressPercent / 100.0), height: 12)
                                        }
                                    }
                                    .frame(height: 12)
                                    
                                    HStack {
                                        Text("Past").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                                        Spacer()
                                        Text("Future").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 30)
                                
                                // ── Streak & Days 표시 ──
                                HStack(spacing: 30) {
                                    statBadge(value: "\(progress.totalDays)", label: "Days")
                                    statBadge(value: "\(progress.currentStreak)", label: "Streak")
                                    statBadge(value: "\(progress.longestStreak)", label: "Best")
                                }
                                .padding(.top, 10)
                            }
                            
                            Spacer().frame(height: 50)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { futureImage = FutureSelfStore.load() }
        .alert("Couldn't generate", isPresented: $showGenError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(genErrorMessage)
        }
    }

    // ── "After" = AI 미래자아 (탭하면 생성, 결과는 로컬 저장) ──
    private var futureCircle: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(red: 0.9, green: 0.9, blue: 0.9)).frame(width: 135, height: 135)
                if let futureImage {
                    Image(uiImage: futureImage).resizable().scaledToFill()
                        .frame(width: 135, height: 135).clipShape(Circle())
                } else if isGenerating {
                    ProgressView().scaleEffect(1.2)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 30)).foregroundColor(slateGreen)
                        Text(SlateConfig.isImageGenerationAvailable ? "Tap to generate" : "Coming soon")
                            .font(.system(size: 11)).foregroundColor(.gray)
                    }
                }
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.08), radius: 8)
            .onTapGesture {
                if !isGenerating && SlateConfig.isImageGenerationAvailable {
                    generateFutureSelf()
                }
            }
            Text("After").font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
        }
    }

    // ── AI 미래자아 생성 실행 ──
    private func generateFutureSelf() {
        guard let base = beforeImage else {
            genErrorMessage = "먼저 시작점 사진(Before)을 추가해 주세요."
            showGenError = true
            return
        }
        let goal = futureGoal
        isGenerating = true
        Task {
            do {
                let result = try await ImageGenerationService.shared
                    .generateFutureSelf(from: base, futureGoal: goal)
                FutureSelfStore.save(result)
                await MainActor.run {
                    futureImage = result
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    genErrorMessage = error.localizedDescription
                    showGenError = true
                    isGenerating = false
                }
            }
        }
    }

    // ── 뒤로가기: 주입된 onBack 실행, 없으면 dismiss 폴백 ──
    private func goBackToCalendar() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    // 원형 이미지 컴포넌트 (실제 이미지 / 미래자아 플레이스홀더 대응)
    private func comparisonCircle(image: UIImage?, label: String, isFuture: Bool) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(red: 0.9, green: 0.9, blue: 0.9)).frame(width: 135, height: 135)
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 135, height: 135).clipShape(Circle())
                } else if isFuture {
                    // AI 미래자아 이미지 생성은 다음 단계 → 안내 플레이스홀더
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 34)).foregroundColor(slateGreen)
                        Text("Coming soon").font(.system(size: 11)).foregroundColor(.gray)
                    }
                } else {
                    // 시작점 사진을 아직 안 찍은 상태
                    Image(systemName: "camera.fill").font(.system(size: 40)).foregroundColor(.white)
                }
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.08), radius: 8)
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
        }
    }
    
    // 통계 뱃지 컴포넌트
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return NavigationStack {
        MySlateView()
            .modelContainer(container)
            .environmentObject(SpaceManager.shared)
    }
}
