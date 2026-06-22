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

// MARK: - 팔레트 정의 (한 테마의 모든 색)
struct SlatePalette {
    let paper, paperSoft, paperDeep, sand, sandDeep: Color
    let ink, inkSoft, inkFaint: Color
    let leaf, leafDeep, leafSoft: Color
    let honey, honeyDeep: Color
    let pink, pinkDeep, sky, skyDeep, lilac, lilacDeep: Color
    let navBar: Color
}

// MARK: - 선택 가능한 테마 프리셋
enum SlateThemeID: String, CaseIterable, Identifiable {
    case pineOlive, softMist, warmBotanic
    var id: String { rawValue }
    var label: String {
        switch self {
        case .pineOlive:   return "Pine & Olive"
        case .softMist:    return "Soft Mist"
        case .warmBotanic: return "Warm Botanic"
        }
    }
    /// 미리보기 칩에 쓸 대표 3색 (바탕/주액센트/잉크)
    var swatch: [Color] { [palette.paper, palette.leaf, palette.ink] }

    var palette: SlatePalette {
        switch self {
        case .pineOlive:
            return SlatePalette(
                paper: Color(hex: "#E5E2CE"), paperSoft: Color(hex: "#F1EFE2"), paperDeep: Color(hex: "#D8D4B8"),
                sand: Color(hex: "#D8D4B8"), sandDeep: Color(hex: "#C5C0A0"),
                ink: Color(hex: "#214944"), inkSoft: Color(hex: "#4E6962"), inkFaint: Color(hex: "#8C988F"),
                leaf: Color(hex: "#C1C177"), leafDeep: Color(hex: "#7C8A3C"), leafSoft: Color(hex: "#D7D6A7"),
                honey: Color(hex: "#CDB86A"), honeyDeep: Color(hex: "#9A863C"),
                pink: Color(hex: "#C79279"), pinkDeep: Color(hex: "#9A5E42"),
                sky: Color(hex: "#5E9A8F"), skyDeep: Color(hex: "#214944"),
                lilac: Color(hex: "#A9B589"), lilacDeep: Color(hex: "#6C7B4C"),
                navBar: Color(hex: "#214944"))
        case .softMist:
            return SlatePalette(
                paper: Color(hex: "#ECEFE7"), paperSoft: Color(hex: "#F8F9F3"), paperDeep: Color(hex: "#E2E6DC"),
                sand: Color(hex: "#DDE2D6"), sandDeep: Color(hex: "#C9CFBE"),
                ink: Color(hex: "#33352D"), inkSoft: Color(hex: "#797C6C"), inkFaint: Color(hex: "#A9AB9C"),
                leaf: Color(hex: "#C2DBA7"), leafDeep: Color(hex: "#88AC60"), leafSoft: Color(hex: "#DDE9CB"),
                honey: Color(hex: "#EFE7A6"), honeyDeep: Color(hex: "#BBAB52"),
                pink: Color(hex: "#EBC3B4"), pinkDeep: Color(hex: "#BE7C66"),
                sky: Color(hex: "#A8D7CE"), skyDeep: Color(hex: "#579E90"),
                lilac: Color(hex: "#CFC6E2"), lilacDeep: Color(hex: "#8A79B5"),
                navBar: Color(hex: "#2E332B"))
        case .warmBotanic:
            return SlatePalette(
                paper: Color(hex: "#F6EEDD"), paperSoft: Color(hex: "#FCF7EC"), paperDeep: Color(hex: "#EFE4CC"),
                sand: Color(hex: "#E9DCC0"), sandDeep: Color(hex: "#DBC9A2"),
                ink: Color(hex: "#34372B"), inkSoft: Color(hex: "#75735E"), inkFaint: Color(hex: "#A6A28C"),
                leaf: Color(hex: "#A8C66C"), leafDeep: Color(hex: "#6F8F38"), leafSoft: Color(hex: "#C9DAA1"),
                honey: Color(hex: "#EAC44C"), honeyDeep: Color(hex: "#C99B2E"),
                pink: Color(hex: "#F2A7C3"), pinkDeep: Color(hex: "#C25C84"),
                sky: Color(hex: "#9FC8E8"), skyDeep: Color(hex: "#3F79A6"),
                lilac: Color(hex: "#C9B6E8"), lilacDeep: Color(hex: "#7C5DB0"),
                navBar: Color(hex: "#26271F"))
        }
    }
}

// MARK: - 테마 매니저 (앱 전역, 사용자가 설정에서 변경)
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var themeID: SlateThemeID {
        didSet { UserDefaults.standard.set(themeID.rawValue, forKey: "slate_themeID") }
    }
    var palette: SlatePalette { themeID.palette }
    private init() {
        let raw = UserDefaults.standard.string(forKey: "slate_themeID") ?? SlateThemeID.pineOlive.rawValue
        themeID = SlateThemeID(rawValue: raw) ?? .pineOlive
    }
}

// MARK: - 색 토큰 (현재 테마에서 동적으로 읽음)
/// 화면은 하드코딩 색 대신 이 토큰을 쓴다. 테마가 바뀌면 값이 따라 바뀐다.
enum SlateColor {
    private static var p: SlatePalette { ThemeManager.shared.palette }

    static var paper: Color     { p.paper }
    static var paperSoft: Color { p.paperSoft }
    static var paperDeep: Color { p.paperDeep }
    static var sand: Color      { p.sand }
    static var sandDeep: Color  { p.sandDeep }

    static var ink: Color       { p.ink }
    static var inkSoft: Color   { p.inkSoft }
    static var inkFaint: Color  { p.inkFaint }

    static var leaf: Color      { p.leaf }
    static var leafDeep: Color  { p.leafDeep }
    static var leafSoft: Color  { p.leafSoft }

    static var honey: Color     { p.honey }
    static var honeyDeep: Color { p.honeyDeep }

    static var pink: Color      { p.pink }
    static var pinkDeep: Color  { p.pinkDeep }
    static var sky: Color       { p.sky }
    static var skyDeep: Color   { p.skyDeep }
    static var lilac: Color     { p.lilac }
    static var lilacDeep: Color { p.lilacDeep }

    static var navBar: Color    { p.navBar }

    /// Space/카테고리 → 대표 색 (월렛 카드·포커스 링·스티커 공통)
    static var spacePalette: [Color] { [leaf, honey, pink, sky, lilac] }
    static func forSpace(_ index: Int) -> Color {
        let count = spacePalette.count
        return spacePalette[((index % count) + count) % count]
    }
    static func forSpace(named name: String) -> Color {
        forSpace(abs(name.hashValue))
    }

    /// 색 면 위에 올릴 텍스트용 진한 동색 (대비 확보)
    static func onAccentText(for color: Color) -> Color {
        if color == leaf || color == leafSoft { return leafDeep }
        if color == honey { return honeyDeep }
        if color == pink  { return pinkDeep }
        if color == sky   { return skyDeep }
        if color == lilac { return lilacDeep }
        return ink
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
