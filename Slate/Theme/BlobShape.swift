import SwiftUI

/// 유기적인 블롭(불규칙 원형) Shape — 스티커 뱃지용.
/// radii(꼭지점별 반지름 비율)로 매번 색다른 형태를 만든다. Catmull-Rom 스플라인으로 부드럽게.
struct BlobShape: Shape {
    var radii: [CGFloat]

    func path(in rect: CGRect) -> Path {
        let n = radii.count
        guard n >= 3 else { return Path(ellipseIn: rect) }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseR = min(rect.width, rect.height) / 2

        var pts: [CGPoint] = []
        for i in 0..<n {
            let angle = (Double(i) / Double(n)) * 2 * Double.pi - Double.pi / 2
            let r = baseR * radii[i]
            pts.append(CGPoint(x: center.x + CGFloat(cos(angle)) * r,
                               y: center.y + CGFloat(sin(angle)) * r))
        }

        // 닫힌 Catmull-Rom → 큐빅 베지어
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}

extension BlobShape {
    /// 서로 확연히 다른 블롭 프리셋들 (꼭지점 수·반지름 다름 → "색다른" 모양)
    static let variants: [[CGFloat]] = [
        [1.00, 0.78, 0.98, 0.82, 1.00, 0.80],
        [0.90, 1.00, 0.76, 0.96, 0.84, 1.00, 0.80],
        [1.00, 0.84, 0.92, 1.00, 0.74, 0.94],
        [0.86, 1.00, 0.82, 0.98, 0.76, 1.00, 0.84, 0.93],
        [1.00, 0.88, 1.00, 0.75, 0.97, 0.86, 0.80],
        [0.95, 0.78, 1.00, 0.85, 0.72, 1.00, 0.88],
    ]
    static func variant(_ i: Int) -> BlobShape {
        let count = variants.count
        return BlobShape(radii: variants[((i % count) + count) % count])
    }
}

/// 자연 이모지 + 라벨을 담은 색다른 블롭 스티커 뱃지.
struct StickerBadge: View {
    let emoji: String
    let label: String
    let color: Color
    var variant: Int = 0
    var rotation: Double = -6
    var size: CGFloat = 86

    var body: some View {
        ZStack {
            BlobShape.variant(variant)
                .fill(color)
                .shadow(color: SlateColor.ink.opacity(0.10), radius: 6, x: 0, y: 4)
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: size * 0.30))
                if !label.isEmpty {
                    Text(label)
                        .font(.slateSans(size * 0.145, weight: .bold))
                        .foregroundColor(SlateColor.onAccentText(for: color))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6)
                }
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    let items: [(String, String, Color)] = [
        ("🌿", "Daily", SlateColor.leaf),
        ("☀️", "Workout", SlateColor.honey),
        ("🍃", "Reading", SlateColor.sky),
        ("🌙", "Study", SlateColor.lilac),
        ("🌸", "Couple", SlateColor.pink),
    ]
    return HStack(spacing: -6) {
        ForEach(Array(items.enumerated()), id: \.offset) { i, it in
            StickerBadge(emoji: it.0, label: it.1, color: it.2,
                         variant: i, rotation: Double(i % 2 == 0 ? -8 : 7))
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SlateColor.paper)
}
