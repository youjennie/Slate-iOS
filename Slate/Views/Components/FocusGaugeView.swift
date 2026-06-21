import SwiftUI

/// 게이지 둘레의 아날로그 눈금 링
struct TickRing: Shape {
    var tickCount: Int = 60
    var tickLength: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer - tickLength
        for i in 0..<tickCount {
            let a = (Double(i) / Double(tickCount)) * 2 * Double.pi
            let dx = CGFloat(cos(a)), dy = CGFloat(sin(a))
            path.move(to: CGPoint(x: center.x + dx * inner, y: center.y + dy * inner))
            path.addLine(to: CGPoint(x: center.x + dx * outer, y: center.y + dy * outer))
        }
        return path
    }
}

/// 포커스 게이지의 한 구간(Space별 활동 비중)
struct FocusSegment: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
}

/// "어디에 집중하고 있는지" 한눈에 보여주는 세그먼트 도넛 + 눈금 링.
struct FocusGaugeView: View {
    let segments: [FocusSegment]
    let centerValue: String
    let centerLabel: String
    var size: CGFloat = 196

    private struct Arc: Identifiable {
        let id = UUID()
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    private var arcs: [Arc] {
        let total = max(segments.reduce(0) { $0 + $1.value }, 0.0001)
        var acc: Double = 0
        return segments.map { seg in
            let start = acc / total
            acc += seg.value
            let end = acc / total
            return Arc(start: CGFloat(start), end: CGFloat(end), color: seg.color)
        }
    }

    var body: some View {
        ZStack {
            TickRing(tickCount: 60, tickLength: 6)
                .stroke(SlateColor.leafDeep.opacity(0.35), lineWidth: 1.5)
                .frame(width: size, height: size)

            if segments.isEmpty {
                Circle()
                    .stroke(SlateColor.sand, style: StrokeStyle(lineWidth: size * 0.12))
                    .frame(width: size * 0.72, height: size * 0.72)
            } else {
                ForEach(arcs) { arc in
                    Circle()
                        .trim(from: arc.start, to: arc.end)
                        .stroke(arc.color, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: size * 0.72, height: size * 0.72)
                }
            }

            VStack(spacing: 2) {
                Text(centerValue)
                    .font(.slateSans(size * 0.19, weight: .bold))
                    .foregroundColor(SlateColor.ink)
                Text(centerLabel)
                    .font(.slateSans(11))
                    .foregroundColor(SlateColor.inkSoft)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 24) {
        FocusGaugeView(
            segments: [
                FocusSegment(name: "Daily", value: 42, color: SlateColor.leaf),
                FocusSegment(name: "Workout", value: 24, color: SlateColor.honey),
                FocusSegment(name: "Reading", value: 20, color: SlateColor.sky),
                FocusSegment(name: "Study", value: 14, color: SlateColor.lilac),
            ],
            centerValue: "42",
            centerLabel: "days with Slate"
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SlateColor.paper)
}
