import SwiftUI

struct ActivityBar: Identifiable {
    let id = UUID()
    let label: String      // 요일 등 짧은 라벨
    let value: Int          // 기록 수
    var color: Color = SlateColor.leaf
}

/// 막대를 탭하면 콜아웃이 뜨는 인터랙티브 주간 활동 차트.
struct ActivityChartView: View {
    let bars: [ActivityBar]
    var maxHeight: CGFloat = 130
    @State private var selected: Int? = nil

    private var maxValue: Int { max(bars.map { $0.value }.max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 10) {
            // 콜아웃
            ZStack {
                if let i = selected, bars.indices.contains(i) {
                    Text("\(bars[i].label) · \(bars[i].value) \(bars[i].value == 1 ? "moment" : "moments")")
                        .font(.slateSans(12, weight: .bold))
                        .foregroundColor(SlateColor.paper)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(SlateColor.ink))
                } else {
                    Text("Tap a bar")
                        .font(.slateSans(12))
                        .foregroundColor(SlateColor.inkFaint)
                }
            }
            .frame(height: 24)

            // 막대
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    VStack(spacing: 8) {
                        Spacer(minLength: 0)
                        Capsule()
                            .fill(selected == index ? SlateColor.leafDeep : bar.color)
                            .frame(height: max(10, CGFloat(bar.value) / CGFloat(maxValue) * maxHeight))
                        Text(bar.label)
                            .font(.slateSans(10, weight: selected == index ? .bold : .regular))
                            .foregroundColor(selected == index ? SlateColor.ink : SlateColor.inkFaint)
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
            .frame(height: maxHeight + 24)
        }
    }
}

#Preview {
    ActivityChartView(bars: [
        ActivityBar(label: "M", value: 2),
        ActivityBar(label: "T", value: 3, color: SlateColor.leaf),
        ActivityBar(label: "W", value: 1, color: SlateColor.leafSoft),
        ActivityBar(label: "T", value: 4, color: SlateColor.honey),
        ActivityBar(label: "F", value: 2),
        ActivityBar(label: "S", value: 0, color: SlateColor.leafSoft),
        ActivityBar(label: "S", value: 3, color: SlateColor.sky),
    ])
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SlateColor.paper)
}
