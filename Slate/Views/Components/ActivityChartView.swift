import SwiftUI

struct ActivityBar: Identifiable {
    let id = UUID()
    let label: String      // 요일 등 짧은 라벨
    let value: Int          // 기록 수
    var color: Color = SlateColor.leaf
}

/// 요일별 막대 차트 — 막대를 탭하면 강조 + 값 표시. 고정폭/베이스라인 정렬로 깨지지 않음.
struct ActivityChartView: View {
    let bars: [ActivityBar]
    var maxHeight: CGFloat = 104
    @State private var selected: Int? = nil

    private var maxValue: Int { max(bars.map { $0.value }.max() ?? 1, 1) }

    private func barHeight(_ value: Int) -> CGFloat {
        value == 0 ? 4 : max(10, CGFloat(value) / CGFloat(maxValue) * maxHeight)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                VStack(spacing: 6) {
                    // 값 라벨 (0이면 숨김, 선택 시 항상 표시)
                    Text("\(bar.value)")
                        .font(.slateSans(10, weight: .bold))
                        .foregroundColor(selected == index ? SlateColor.ink : SlateColor.inkFaint)
                        .opacity(bar.value > 0 || selected == index ? 1 : 0)

                    // 막대
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected == index ? SlateColor.leafDeep : bar.color)
                        .frame(width: 22, height: barHeight(bar.value))

                    // 요일 라벨
                    Text(bar.label)
                        .font(.slateSans(11, weight: selected == index ? .bold : .regular))
                        .foregroundColor(selected == index ? SlateColor.ink : SlateColor.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = (selected == index) ? nil : index
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxHeight + 40, alignment: .bottom)
    }
}

#Preview {
    ActivityChartView(bars: [
        ActivityBar(label: "S", value: 2),
        ActivityBar(label: "M", value: 3),
        ActivityBar(label: "T", value: 1, color: SlateColor.leafSoft),
        ActivityBar(label: "W", value: 4, color: SlateColor.honey),
        ActivityBar(label: "T", value: 2),
        ActivityBar(label: "F", value: 0, color: SlateColor.leafSoft),
        ActivityBar(label: "S", value: 3, color: SlateColor.sky),
    ])
    .padding()
    .frame(maxWidth: .infinity)
    .background(SlateColor.paper)
}
