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

// MARK: - 브랜드 상수 (한국적 헤리티지 × 자연)
enum SlateBrand {
    /// 슬로건 (KR 원문 / EN)
    static let taglineKR = "차곡차곡 쌓이는 정갈한 나의 하루"
    static let taglineEN = "Your days, neatly stacked."
    /// 컨셉: 한옥 툇마루처럼 차분하고 정갈한 기록 공간 (modern heritage minimal × nature)
}

// MARK: - 선택 가능한 포인트(액센트) 컬러 — 자연 × 한국 헤리티지
/// 브랜드 가이드라인의 헤리티지 베이스(백회색 배경·고목재색 잉크·기와먹색 네비)는
/// 모든 테마 공통으로 고정하고, "포인트 컬러"만 자연에서 온 헤리티지 색으로 바꾼다.
/// (CTA·카메라 버튼·게이지·선택 상태가 이 컬러로 칠해진다.)
enum SlateThemeID: String, CaseIterable, Identifiable {
    case straw, moss, clay, indigo
    var id: String { rawValue }
    var label: String {
        switch self {
        case .straw:  return "Straw"    // 짚방석색
        case .moss:   return "Moss"     // 이끼·자연 초록
        case .clay:   return "Clay"     // 기와·흙
        case .indigo: return "Indigo"   // 쪽빛
        }
    }
    /// 설정 칩에 표시할 대표 포인트 컬러
    var accent: Color { palette.leaf }
    /// 미리보기 칩에 쓸 대표 3색 (포인트/포인트딥/잉크)
    var swatch: [Color] { [palette.leaf, palette.leafDeep, palette.ink] }

    var palette: SlatePalette {
        // ── 헤리티지 베이스(브랜드 가이드라인, 전 테마 공통) ──
        let paper     = Color(hex: "#F7F5F0")   // 백회색 Traditional Plaster — 앱 전체 배경
        let paperSoft = Color(hex: "#FCFBF7")   // 카드/헤더용 살짝 밝은 회벽
        let paperDeep = Color(hex: "#EAE6DF")   // 초가은빛 Soft Stone White — 빈 셀/비활성
        let sand      = Color(hex: "#EAE6DF")
        let sandDeep  = Color(hex: "#DAD3C6")
        let ink       = Color(hex: "#5A3B28")   // 고목재색 Deep Timber — 메인 텍스트·1px 라인
        let inkSoft   = Color(hex: "#8A6F5C")
        let inkFaint  = Color(hex: "#B3A594")
        let navBar    = Color(hex: "#33363B")   // 기와먹색 Tile Charcoal — 하단 내비

        // 카테고리 구분용 보조색(자연×헤리티지, 전 테마 공통)
        let honey = Color(hex: "#DDA261"); let honeyDeep = Color(hex: "#B87F3E")  // 짚
        let pink  = Color(hex: "#C0794F"); let pinkDeep  = Color(hex: "#8E5230")  // 기와/흙
        let sky   = Color(hex: "#7FA88F"); let skyDeep   = Color(hex: "#4E7361")  // 청자
        let lilac = Color(hex: "#9CA36B"); let lilacDeep = Color(hex: "#6B7344")  // 이끼

        // ── 포인트(액센트) 컬러만 테마별로 달라진다 ──
        let leaf, leafDeep, leafSoft: Color
        switch self {
        case .straw:   // 짚방석색 (브랜드 기본 CTA색)
            leaf = Color(hex: "#DDA261"); leafDeep = Color(hex: "#B87F3E"); leafSoft = Color(hex: "#F2DEC1")
        case .moss:    // 이끼·자연 초록
            leaf = Color(hex: "#8B9B5A"); leafDeep = Color(hex: "#5E6B38"); leafSoft = Color(hex: "#DEE3C8")
        case .clay:    // 기와·흙
            leaf = Color(hex: "#C0794F"); leafDeep = Color(hex: "#8E5230"); leafSoft = Color(hex: "#EAD3C2")
        case .indigo:  // 쪽빛
            leaf = Color(hex: "#5B7C99"); leafDeep = Color(hex: "#3B546E"); leafSoft = Color(hex: "#CFDCE6")
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
        let raw = UserDefaults.standard.string(forKey: "slate_themeID") ?? SlateThemeID.straw.rawValue
        themeID = SlateThemeID(rawValue: raw) ?? .straw
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
