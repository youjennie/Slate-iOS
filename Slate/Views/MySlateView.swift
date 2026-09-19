import SwiftUI
import SwiftData

struct MySlateView: View {
    @Environment(\.dismiss) var dismiss

    /// 뒤로가기 시 실행할 동작 (예: 탭바에서 Calendar 탭으로 전환)
    var onBack: (() -> Void)? = nil

    // ── SwiftData에서 실시간 데이터 로딩 ──
    @Query(sort: \PhotoRecord.date) private var allRecords: [PhotoRecord]
    @Query(sort: \Space.createdAt) private var spaces: [Space]

    // ── 실시간 계산 ──
    private var progress: SlateProgress {
        ProgressCalculator.calculate(from: allRecords)
    }

    private var currentMonthStart: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
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
        .overlay(Capsule().stroke(SlateColor.ink.opacity(0.08), lineWidth: 1))
    }

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        // 배경은 .slatePaperBackground() modifier로 (ZStack+ignoresSafeArea는 가장자리 잘림 유발)
        VStack(spacing: 0) {

            // --- 상단 헤더 ---
            Text("My Slate")
                .font(.slateSans(18, weight: .bold))
                .foregroundColor(SlateColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay(alignment: .leading) {
                    Button(action: { goBackToCalendar() }) {
                        ZStack {
                            Circle().fill(SlateColor.sand).frame(width: 42, height: 42)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(SlateColor.ink)
                        }
                    }
                    .padding(.leading, 16)
                }
                .overlay(alignment: .trailing) {
                    NavigationLink(destination: MySlateSettingsView()) {
                        ZStack {
                            Circle().fill(SlateColor.sand).frame(width: 42, height: 42)
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(SlateColor.ink)
                        }
                    }
                    .padding(.trailing, 16)
                }
                .background(SlateColor.paperSoft)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(SlateColor.ink.opacity(0.08)).frame(height: 1)
                }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {

                    // 1. 브랜드 히어로 — 로고 + 슬로건 (헤리티지 톤)
                    VStack(spacing: 10) {
                        Image("name_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 148)
                            .padding(.bottom, -44)
                            .padding(.top, -4)

                        Text(SlateBrand.taglineEN)
                            .font(.slateSerif(19, weight: .semibold))
                            .foregroundColor(SlateColor.ink)

                        Text("A calm record of the days you keep.")
                            .font(.slateSans(13))
                            .foregroundColor(SlateColor.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // 2. 포커스 게이지 — 어디에 집중하는지
                    VStack(spacing: 10) {
                        Text("Where you're focusing")
                            .font(.slateSans(17, weight: .bold))
                            .foregroundColor(SlateColor.ink)
                        Text(focusSegments.isEmpty ? "Start recording to see your focus"
                                                   : "\(progress.totalDays) days kept so far")
                            .font(.slateSans(12))
                            .foregroundColor(SlateColor.inkSoft)

                        FocusGaugeView(
                            segments: focusSegments,
                            centerValue: "\(progress.totalDays)",
                            centerLabel: "days kept",
                            size: 158
                        )

                        if !focusSegments.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(focusSegments) { seg in
                                        legendChip(seg)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    // 3. 주간 활동 — 인터랙티브
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

                    // 4. 통계
                    HStack(spacing: 30) {
                        statBadge(value: "\(progress.totalDays)", label: "Days")
                        statBadge(value: "\(progress.currentStreak)", label: "Streak")
                        statBadge(value: "\(progress.longestStreak)", label: "Best")
                    }

                    // 5. Monthly Memory 진입 (UC-05)
                    NavigationLink(destination: MonthShareDetailView(
                        month: currentMonthStart,
                        records: allRecords.filter { !$0.isDeleted },
                        category: spaces.first(where: { $0.isDefault })?.name ?? spaces.first?.name ?? "Daily"
                    )) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SlateColor.leafDeep)
                            Text("Monthly Memory")
                                .font(.slateSans(15, weight: .bold))
                                .foregroundColor(SlateColor.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(SlateColor.inkFaint)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: SlateRadius.md).fill(SlateColor.paperSoft))
                        .overlay(RoundedRectangle(cornerRadius: SlateRadius.md).stroke(SlateColor.ink.opacity(0.12), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)

                    // 떠있는 카메라 버튼(-22 offset)에 마지막 줄이 가려지지 않도록 하단 여백
                    Spacer().frame(height: 52)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slatePaperBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    // ── 뒤로가기: 주입된 onBack 실행, 없으면 dismiss 폴백 ──
    private func goBackToCalendar() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    // 통계 뱃지 컴포넌트
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.slateSans(21, weight: .bold))
                .foregroundColor(SlateColor.ink)
            Text(label)
                .font(.slateSans(11))
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
