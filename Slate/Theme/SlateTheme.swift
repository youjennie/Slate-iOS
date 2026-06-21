import SwiftUI

// MARK: - Color hex helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Slate "Soft Mist" palette (v4)
/// 쿨한 라이트 미스트 바탕 + 소프트 민트·버터·아쿠아 파스텔.
/// 토큰 이름은 의미 기준으로 유지(leaf=초록, honey=노랑, sky=청록 등),
/// 값만 Soft Mist 톤으로. 모든 화면은 하드코딩 색 대신 이 토큰을 쓴다.
enum SlateColor {
    // 베이스 (미스트/카드)
    static let paper      = Color(hex: "#ECEFE7")   // mist 바탕
    static let paperSoft  = Color(hex: "#F8F9F3")   // cloud 카드(거의 흰색)
    static let paperDeep  = Color(hex: "#E2E6DC")
    static let sand       = Color(hex: "#DDE2D6")   // 중립 라이트(원형/구분선)
    static let sandDeep   = Color(hex: "#C9CFBE")

    // 잉크 (텍스트)
    static let ink        = Color(hex: "#33352D")
    static let inkSoft    = Color(hex: "#797C6C")
    static let inkFaint   = Color(hex: "#A9AB9C")

    // 주 액센트 — 민트(연두)
    static let leaf       = Color(hex: "#C2DBA7")
    static let leafDeep   = Color(hex: "#88AC60")
    static let leafSoft   = Color(hex: "#DDE9CB")

    // 보조 액센트 — 버터(노랑)
    static let honey      = Color(hex: "#EFE7A6")
    static let honeyDeep  = Color(hex: "#BBAB52")

    // 스티커 파스텔
    static let pink       = Color(hex: "#EBC3B4")   // blush
    static let pinkDeep   = Color(hex: "#BE7C66")
    static let sky        = Color(hex: "#A8D7CE")   // aqua
    static let skyDeep    = Color(hex: "#579E90")
    static let lilac      = Color(hex: "#CFC6E2")
    static let lilacDeep  = Color(hex: "#8A79B5")

    // 다크 pill 내비
    static let navBar     = Color(hex: "#2E332B")

    /// Space/카테고리 → 대표 색 (월렛 카드·포커스 링·스티커 공통)
    static let spacePalette: [Color] = [leaf, honey, pink, sky, lilac]
    static func forSpace(_ index: Int) -> Color {
        let count = spacePalette.count
        return spacePalette[((index % count) + count) % count]
    }
    /// 카테고리 이름을 안정적으로 같은 색에 매핑 (해시 기반)
    static func forSpace(named name: String) -> Color {
        forSpace(abs(name.hashValue))
    }

    /// 색 면 위에 올릴 텍스트용 진한 동색 (대비 확보)
    static func onAccentText(for color: Color) -> Color {
        switch color {
        case leaf, leafSoft: return leafDeep
        case honey:          return honeyDeep
        case pink:           return pinkDeep
        case sky:            return skyDeep
        case lilac:          return lilacDeep
        default:             return ink
        }
    }
}

// MARK: - Typography
extension Font {
    /// 손글씨 — 종이 낙서 컨셉. 브랜드/헤드라인의 "개성" 보이스 (로고 톤과 매칭)
    static func slateHand(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Bradley Hand", size: size).weight(weight)
    }
    /// 에디토리얼 세리프 (보조)
    static func slateSerif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// 본문·UI 산세리프
    static func slateSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - Corner radii
enum SlateRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - 종이 질감 배경 (낙서 컨셉)
/// 미스트 색 위에 구겨진 종이 결을 은은하게 깐다.
struct PaperBackground: View {
    var body: some View {
        ZStack {
            SlateColor.paper
            Image("background_paper")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .blendMode(.multiply)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// 종이 질감 표준 배경
    func slatePaperBackground() -> some View {
        background(PaperBackground())
    }
}

// MARK: - 손그림 밑줄 (doodle)
/// 살짝 흔들리는 손으로 그은 듯한 밑줄
struct DoodleUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        let w = rect.width
        let amp = rect.height * 0.5
        p.move(to: CGPoint(x: 0, y: y))
        p.addCurve(to: CGPoint(x: w * 0.5, y: y),
                   control1: CGPoint(x: w * 0.18, y: y - amp),
                   control2: CGPoint(x: w * 0.32, y: y + amp))
        p.addCurve(to: CGPoint(x: w, y: y),
                   control1: CGPoint(x: w * 0.70, y: y - amp),
                   control2: CGPoint(x: w * 0.86, y: y + amp * 0.8))
        return p
    }
}

extension View {
    /// 텍스트 아래 손그림 밑줄을 깐다
    func doodleUnderline(_ color: Color = SlateColor.leafDeep, width: CGFloat = 3) -> some View {
        overlay(alignment: .bottom) {
            DoodleUnderline()
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .frame(height: 7)
                .offset(y: 9)
        }
    }
}

// MARK: - 자연 이모지 (풀·해·달·잎·물결…)
/// 앱에서 쓰는 모든 이모지는 자연에서 온 요소로 통일한다.
enum SlateEmoji {
    /// 기본 카테고리 → 자연 이모지
    static func forSpace(named name: String) -> String {
        switch name.lowercased() {
        case "daily":    return "🌿"   // 풀
        case "workout":  return "☀️"   // 해 (에너지)
        case "reading":  return "🍃"   // 잎
        case "study":    return "🌙"   // 달 (밤 공부)
        case "project":  return "🌳"   // 나무 (키워나감)
        case "medicine": return "🌱"   // 새싹 (회복)
        case "couple":   return "🌸"   // 꽃
        case "baby":     return "🌷"   // 튤립
        default:
            // 커스텀 Space는 자연 이모지 풀에서 이름 해시로 안정 배정
            let pool = ["🌿","☀️","🍃","🌙","🌊","🌻","🍄","🪴","🌷","⭐️","🌳","🌾","🐚","🏔️"]
            return pool[abs(name.hashValue) % pool.count]
        }
    }

    /// 시간대에 따른 해/달 (인사말 등)
    static var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "☀️"   // 아침 해
        case 12..<17: return "🌤️"   // 낮
        case 17..<21: return "🌇"   // 노을
        default:      return "🌙"   // 밤 달
        }
    }

    static let streak = "🔥"        // 대체 가능
    static let leaf   = "🌿"
    static let sun    = "☀️"
    static let moon   = "🌙"
    static let sprout = "🌱"
    static let wave   = "🌊"
    static let star   = "⭐️"
}
