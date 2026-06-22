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
    let slateWhite = SlateColor.leafDeep
    let slateGreen = SlateColor.leaf
    let cameraGreen = SlateColor.leaf

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

    /// 포커스 게이지용: Space별 활동 비중 (생성 순서대로 안정 색상)
    private var focusSegments: [FocusSegment] {
        let active = allRecords.filter { !$0.isDeleted }
        guard !active.isEmpty else { return [] }
        var result: [FocusSegment] = []
        for (index, space) in spaces.enumerated() {
            let count = active.filter { $0.spaceTag == space.name }.count
            if count > 0 {
                result.append(FocusSegment(name: space.name,
                                           value: Double(count),
                                           color: SlateColor.forSpace(index)))
            }
        }
        return result
    }

    /// 주간 활동 차트용: 최근 7일 기록 수
    private var weeklyBars: [ActivityBar] {
        let cal = Calendar.current
        let active = allRecords.filter { !$0.isDeleted }
        let today = cal.startOfDay(for: Date())
        let symbols = cal.veryShortWeekdaySymbols
        var bars: [ActivityBar] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = active.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            let wd = cal.component(.weekday, from: day) - 1
            let label = symbols.indices.contains(wd) ? symbols[wd] : ""
            bars.append(ActivityBar(label: label, value: count,
                                    color: count == 0 ? SlateColor.leafSoft : SlateColor.leaf))
        }
        return bars
    }

    /// 포커스 게이지 범례 칩
    @ViewBuilder
    private func legendChip(_ seg: FocusSegment) -> some View {
        let total = max(focusSegments.reduce(0) { $0 + $1.value }, 1)
        let pct = Int((seg.value / total * 100).rounded())
        HStack(spacing: 6) {
            Circle().fill(seg.color).frame(width: 9, height: 9)
            Text("\(seg.name) \(pct)%")
                .font(.slateSans(11, weight: .semibold))
                .foregroundColor(SlateColor.inkSoft)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(SlateColor.paperSoft))
    }

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
                // [1] 배경 레이어 (종이 질감)
                PaperBackground()

                // [2] 콘텐츠 레이어
                VStack(spacing: 0) {
                    
                    // --- 상단 헤더 ---
                    HStack {
                        Button(action: { goBackToCalendar() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(SlateColor.ink)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(SlateColor.sand))
                                .contentShape(Rectangle())
                        }

                        Spacer()

                        Text("My Slate")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(SlateColor.ink)

                        Spacer()

                        NavigationLink(destination: MySlateSettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 17))
                                .foregroundColor(SlateColor.ink)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(SlateColor.sand))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(height: 56)
                    .background(SlateColor.paperSoft)
                    .shadow(color: SlateColor.ink.opacity(0.05), radius: 5, y: 2)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            // 3. 로고 및 타이틀
                            VStack(spacing: 0) {
                                Image("name_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150)
                                    .padding(.bottom, -45)
                                    .padding(.top, -4)

                                Text("Your Future-Self Awaits")
                                    .font(.slateSans(21, weight: .bold))
                                    .foregroundColor(SlateColor.ink)
                                    .padding(.top, 4)
                                    .padding(.bottom, 8)

                                Text("Slate turns your moments into\na picture of who you're becoming.")
                                    .font(.system(size: 13))
                                    .foregroundColor(SlateColor.inkSoft)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            .padding(.top, 14)

                            // 4. Before & After
                            HStack(spacing: 28) {
                                comparisonCircle(image: beforeImage, label: "Before", isFuture: false)
                                futureCircle
                            }

                            // 5. 포커스 게이지 — 어디에 집중하는지
                            VStack(spacing: 10) {
                                Text("Where you're focusing")
                                    .font(.slateSans(17, weight: .bold))
                                    .foregroundColor(SlateColor.ink)
                                Text("\(Int(progress.progressPercent))% closer to your future self")
                                    .font(.slateSans(12))
                                    .foregroundColor(SlateColor.inkSoft)

                                FocusGaugeView(
                                    segments: focusSegments,
                                    centerValue: "\(progress.totalDays)",
                                    centerLabel: "days with Slate",
                                    size: 158
                                )

                                if !focusSegments.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(focusSegments) { seg in
                                                legendChip(seg)
                                            }
                                        }
                                        .padding(.horizontal, 30)
                                    }
                                }
                            }

                            // 6. 주간 활동 — 인터랙티브
                            VStack(spacing: 10) {
                                HStack {
                                    Text("This week")
                                        .font(.slateSans(17, weight: .bold))
                                        .foregroundColor(SlateColor.ink)
                                    Spacer()
                                }
                                ActivityChartView(bars: weeklyBars, maxHeight: 104)
                            }
                            .padding(.horizontal, 30)

                            // 7. 통계
                            HStack(spacing: 30) {
                                statBadge(value: "\(progress.totalDays)", label: "Days")
                                statBadge(value: "\(progress.currentStreak)", label: "Streak")
                                statBadge(value: "\(progress.longestStreak)", label: "Best")
                            }

                            Spacer().frame(height: 16)
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
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(SlateColor.sand).frame(width: 108, height: 108)
                if let futureImage {
                    Image(uiImage: futureImage).resizable().scaledToFill()
                        .frame(width: 108, height: 108).clipShape(Circle())
                } else if isGenerating {
                    ProgressView()
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 24)).foregroundColor(slateGreen)
                        Text(SlateConfig.isImageGenerationAvailable ? "Tap to generate" : "Coming soon")
                            .font(.system(size: 10)).foregroundColor(SlateColor.inkSoft)
                    }
                }
            }
            .overlay(Circle().stroke(SlateColor.paperSoft, lineWidth: 3))
            .shadow(color: SlateColor.ink.opacity(0.10), radius: 7)
            .onTapGesture {
                if !isGenerating && SlateConfig.isImageGenerationAvailable {
                    generateFutureSelf()
                }
            }
            Text("After").font(.system(size: 13, weight: .medium)).foregroundColor(SlateColor.inkSoft)
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
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(SlateColor.sand).frame(width: 108, height: 108)
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 108, height: 108).clipShape(Circle())
                } else if isFuture {
                    VStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 26)).foregroundColor(slateGreen)
                        Text("Coming soon").font(.system(size: 10)).foregroundColor(SlateColor.inkSoft)
                    }
                } else {
                    // 시작점 사진을 아직 안 찍은 상태
                    Image(systemName: "camera.fill").font(.system(size: 30)).foregroundColor(SlateColor.inkFaint)
                }
            }
            .overlay(Circle().stroke(SlateColor.paperSoft, lineWidth: 3))
            .shadow(color: SlateColor.ink.opacity(0.10), radius: 7)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(SlateColor.inkSoft)
        }
    }

    // 통계 뱃지 컴포넌트
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(SlateColor.ink)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(SlateColor.inkSoft)
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
