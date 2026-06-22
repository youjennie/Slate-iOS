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

// MARK: - 선택 가능한 포인트(액센트) 컬러
/// 배경은 항상 흰 종이로 고정하고, "포인트 컬러"만 사용자가 바꾼다.
/// (카메라 버튼·게이지·선택 상태 등 강조 요소가 이 컬러로 칠해진다.)
enum SlateThemeID: String, CaseIterable, Identifiable {
    case olive, forest, clay, dusk
    var id: String { rawValue }
    var label: String {
        switch self {
        case .olive:  return "Olive"
        case .forest: return "Forest"
        case .clay:   return "Clay"
        case .dusk:   return "Dusk"
        }
    }
    /// 설정 칩에 표시할 대표 포인트 컬러
    var accent: Color { palette.leaf }
    /// 미리보기 칩에 쓸 대표 3색 (포인트/포인트딥/잉크)
    var swatch: [Color] { [palette.leaf, palette.leafDeep, palette.ink] }

    var palette: SlatePalette {
        // ── 모든 테마 공통: 흰 종이 배경(살짝 테마톤이 도는 화이트) ──
        let paperSoft = Color(hex: "#FFFFFF")

        // 카테고리 구분용 보조색(테마 공통) — 포인트색과 함께 쓰여 다양성 확보
        let honey = Color(hex: "#CDB86A"); let honeyDeep = Color(hex: "#9A863C")
        let pink  = Color(hex: "#C79279"); let pinkDeep  = Color(hex: "#9A5E42")
        let sky   = Color(hex: "#5E9A8F"); let skyDeep   = Color(hex: "#356F64")
        let lilac = Color(hex: "#A9B589"); let lilacDeep = Color(hex: "#6C7B4C")

        // ── 테마별 정체성: 배경 톤 / 잉크 / 네비바 / 포인트색이 함께 바뀐다 ──
        //    (배경은 흰색을 유지하되 미세한 테마 톤, 네비바·강조는 확실히 달라짐)
        let paper, paperDeep, sand, sandDeep: Color
        let ink, inkSoft, inkFaint, navBar: Color
        let leaf, leafDeep, leafSoft: Color
        switch self {
        case .olive:
            paper = Color(hex: "#FBFBF3"); paperDeep = Color(hex: "#EEEFE0"); sand = Color(hex: "#ECEDDB"); sandDeep = Color(hex: "#D8DABF")
            ink = Color(hex: "#2C3A18"); inkSoft = Color(hex: "#5C6A3C"); inkFaint = Color(hex: "#A2A88C"); navBar = Color(hex: "#46521F")
            leaf = Color(hex: "#C1C177"); leafDeep = Color(hex: "#7C8A3C"); leafSoft = Color(hex: "#E6E6C8")
        case .forest:
            paper = Color(hex: "#F6FAF7"); paperDeep = Color(hex: "#E3EEE6"); sand = Color(hex: "#DEEAE1"); sandDeep = Color(hex: "#C4D7CB")
            ink = Color(hex: "#1E3F31"); inkSoft = Color(hex: "#456B59"); inkFaint = Color(hex: "#92A89B"); navBar = Color(hex: "#2C5141")
            leaf = Color(hex: "#6FA98C"); leafDeep = Color(hex: "#3E7259"); leafSoft = Color(hex: "#CFE2D6")
        case .clay:
            paper = Color(hex: "#FCF8F4"); paperDeep = Color(hex: "#F1E7DF"); sand = Color(hex: "#F0E3D8"); sandDeep = Color(hex: "#DEC8B7")
            ink = Color(hex: "#4A2C1E"); inkSoft = Color(hex: "#7A5544"); inkFaint = Color(hex: "#B49C8E"); navBar = Color(hex: "#6E3B27")
            leaf = Color(hex: "#CC9079"); leafDeep = Color(hex: "#9A5740"); leafSoft = Color(hex: "#EFD7CB")
        case .dusk:
            paper = Color(hex: "#F9F8FC"); paperDeep = Color(hex: "#EBE8F3"); sand = Color(hex: "#E8E5F2"); sandDeep = Color(hex: "#CECAE2")
            ink = Color(hex: "#2E2950"); inkSoft = Color(hex: "#5A5384"); inkFaint = Color(hex: "#A6A1C2"); navBar = Color(hex: "#423A6B")
            leaf = Color(hex: "#9E96C6"); leafDeep = Color(hex: "#655B98"); leafSoft = Color(hex: "#DEDAEF")
        }

        return SlatePalette(
            paper: paper, paperSoft: paperSoft, paperDeep: paperDeep,
            sand: sand, sandDeep: sandDeep,
            ink: ink, inkSoft: inkSoft, inkFaint: inkFaint,
            leaf: leaf, leafDeep: leafDeep, leafSoft: leafSoft,
            honey: honey, honeyDeep: honeyDeep,
            pink: pink, pinkDeep: pinkDeep,
            sky: sky, skyDeep: skyDeep,
            lilac: lilac, lilacDeep: lilacDeep,
            navBar: navBar)
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
        let raw = UserDefaults.standard.string(forKey: "slate_themeID") ?? SlateThemeID.olive.rawValue
        themeID = SlateThemeID(rawValue: raw) ?? .olive
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
                .opacity(0.15)            // 흰 종이 느낌 — 질감만 은은하게
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
