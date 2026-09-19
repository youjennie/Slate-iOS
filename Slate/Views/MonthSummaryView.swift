import SwiftUI

struct MonthSummaryView: View {
    let month: Date
    let records: [PhotoRecord]
    let category: String
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    /// 공유 카드 고정 폭 — 화면 표시·이미지 렌더 양쪽에서 동일 값 사용 (불일치 클리핑 방지)
    static let cardWidth: CGFloat = 390
    
    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: month)?.count ?? 30
    }
    
    var recordedDaysCount: Int {
        // ── isDeleted 필터링 추가 ──
        let activeRecords = records.filter { !$0.isDeleted }
        let uniqueDays = Set(activeRecords.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // (A) 워드마크 및 월 타이틀 섹션 (컴팩트)
            VStack(spacing: 2) {
                SlateWordmark(size: 22)
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.slateSans(36, weight: .black))
                    .foregroundColor(SlateColor.ink)
                Text("\(SpaceManager.shared.userName.isEmpty ? "My" : SpaceManager.shared.userName) Slate Moments")
                    .font(.system(size: 15))
                    .foregroundColor(SlateColor.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // (B) 5열 그리드 요약 (셀 축소)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    if let date = Calendar.current.date(byAdding: .day, value: day-1, to: month) {
                        let record = records.first {
                            Calendar.current.isDate($0.date, inSameDayAs: date) && !$0.isDeleted
                        }
                        SummaryCell(day: day, image: record?.thumbnail(maxPixel: 120), emoji: record?.emoji)
                    }
                }
            }
            .padding(.horizontal, 52)
            .padding(.top, 10)
            .padding(.bottom, 20)

            // (C) 하단 데이터 정보 & 프로그레스 바
            VStack(spacing: 10) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text("\(recordedDaysCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SlateColor.inkSoft)
                    Text("/\(daysInMonth) Days with Slate")
                        .font(.system(size: 16))
                        .foregroundColor(SlateColor.inkSoft)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(SlateColor.inkFaint.opacity(0.15)).frame(height: 10)
                        Capsule().fill(SlateColor.leafDeep)
                            .frame(width: geo.size.width * CGFloat(recordedDaysCount) / CGFloat(max(daysInMonth, 1)), height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 52)
            }
            .padding(.bottom, 26)
        }
        .frame(width: Self.cardWidth)
        .background(Color.white)   // 공유 이미지용 — 테마와 무관하게 항상 흰 배경
    }
}

// 요약 카드용 작은 셀 (유동 정사각 — 그리드 폭에 맞춤, 오버플로 없음)
struct SummaryCell: View {
    let day: Int
    let image: UIImage?
    var emoji: String? = nil

    private var hasEmoji: Bool { image == nil && (emoji?.isEmpty == false) }

    var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if hasEmoji {
                RoundedRectangle(cornerRadius: 12)
                    .fill(SlateColor.leafSoft)
                    .overlay(Text(emoji ?? "").font(.system(size: 22)))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(SlateColor.inkFaint.opacity(0.05))
                    .overlay(Circle().fill(SlateColor.inkFaint.opacity(0.2)).frame(width: 4, height: 4))
            }

            Text("\(day)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(image != nil ? .white : SlateColor.inkSoft)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(6)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - [Preview] MonthSummaryView
#Preview {
    let today = Date()
    let calendar = Calendar.current
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
    
    let sampleRecords = [
        PhotoRecord(date: monthStart, memo: "Day 1", spaceTag: "Daily"),
        PhotoRecord(date: calendar.date(byAdding: .day, value: 2, to: monthStart)!, memo: "Day 3", spaceTag: "Daily"),
        PhotoRecord(date: calendar.date(byAdding: .day, value: 4, to: monthStart)!, memo: "Day 5", spaceTag: "Daily")
    ]
    
    return MonthSummaryView(
        month: monthStart,
        records: sampleRecords,
        category: "Daily"
    )
    .background(SlateColor.inkFaint.opacity(0.1))
}
