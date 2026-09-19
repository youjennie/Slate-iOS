import SwiftUI
import UIKit

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

/// 텍스트 워드마크 — 손글씨 로고 대신 고딕 텍스트로 통일.
struct SlateWordmark: View {
    var size: CGFloat = 34
    var color: Color = SlateColor.ink
    var body: some View {
        Text("Slate")
            .font(.slateSans(size, weight: .bold))
            .tracking(-size * 0.01)
            .foregroundColor(color)
    }
}

// MARK: - 색 후보 A/B/C (자연 × 한국 헤리티지, 밝고 깨끗하게)
/// 브라운 잉크 폐기. 셋 다 밝은 배경 + 딥그린/차콜 잉크 + 자연 포인트.
/// 사용자가 하나 고르면 그걸 기본으로 확정한다.
enum SlateThemeID: String, CaseIterable, Identifiable {
    case freshOlive, hanjiMoss, celadon
    var id: String { rawValue }
    var label: String {
        switch self {
        case .freshOlive: return "A · Fresh Olive"
        case .hanjiMoss:  return "B · Hanji Moss"
        case .celadon:    return "C · Celadon"
        }
    }
    /// 설정 칩에 표시할 대표 포인트 컬러
    var accent: Color { palette.leaf }
    /// 미리보기 칩에 쓸 대표 3색 (포인트/포인트딥/잉크)
    var swatch: [Color] { [palette.leaf, palette.leafDeep, palette.ink] }

    var palette: SlatePalette {
        // 카테고리 보조색은 공통(자연×헤리티지)
        let honey = Color(hex: "#E4C06A"); let honeyDeep = Color(hex: "#B2933C")  // 노랑/짚
        let pink  = Color(hex: "#C0794F"); let pinkDeep  = Color(hex: "#8E5230")  // 기와/흙
        let sky   = Color(hex: "#7FA88F"); let skyDeep   = Color(hex: "#4E7361")  // 청자
        let lilac = Color(hex: "#9CA36B"); let lilacDeep = Color(hex: "#6B7344")  // 이끼

        let paper, paperSoft, paperDeep, sand, sandDeep: Color
        let ink, inkSoft, inkFaint, navBar: Color
        let leaf, leafDeep, leafSoft: Color

        switch self {
        case .freshOlive:   // A — 크림 배경 · 딥올리브 잉크 · 연두+노랑
            paper = Color(hex: "#FBFAF3"); paperSoft = Color(hex: "#FFFFFF"); paperDeep = Color(hex: "#EDECDD")
            sand = Color(hex: "#ECEBDD"); sandDeep = Color(hex: "#D9D8C2")
            ink = Color(hex: "#2E3A21"); inkSoft = Color(hex: "#6E7A55"); inkFaint = Color(hex: "#A7AE92"); navBar = Color(hex: "#2E3A21")
            leaf = Color(hex: "#AEBE5A"); leafDeep = Color(hex: "#7C8A3C"); leafSoft = Color(hex: "#E1E4C4")
        case .hanjiMoss:    // B — 한지 아이보리 · 차콜그린 잉크 · 이끼+기와
            paper = Color(hex: "#F6F2E9"); paperSoft = Color(hex: "#FCFAF4"); paperDeep = Color(hex: "#E7E0D0")
            sand = Color(hex: "#E6E0D2"); sandDeep = Color(hex: "#D3CBB6")
            ink = Color(hex: "#33382E"); inkSoft = Color(hex: "#7C7A64"); inkFaint = Color(hex: "#ABA891"); navBar = Color(hex: "#33363B")
            leaf = Color(hex: "#8B9B5A"); leafDeep = Color(hex: "#5E6B38"); leafSoft = Color(hex: "#DEE3C8")
        case .celadon:      // C — 쿨 오프화이트 · 딥파인 잉크 · 청자+짚
            paper = Color(hex: "#F5F6F1"); paperSoft = Color(hex: "#FFFFFF"); paperDeep = Color(hex: "#E4E7DF")
            sand = Color(hex: "#E4E7DF"); sandDeep = Color(hex: "#CFD6CC")
            ink = Color(hex: "#29332E"); inkSoft = Color(hex: "#6B7770"); inkFaint = Color(hex: "#A2ADA6"); navBar = Color(hex: "#2B3330")
            leaf = Color(hex: "#7FA88F"); leafDeep = Color(hex: "#4E7361"); leafSoft = Color(hex: "#CFE0D5")
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
        // 로컬 테스트용: 런치 인자 `-slateTheme <id>`로 테마 강제 (릴리즈 영향 없음)
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-slateTheme"), i + 1 < args.count,
           let forced = SlateThemeID(rawValue: args[i + 1]) {
            themeID = forced
            return
        }
        let raw = UserDefaults.standard.string(forKey: "slate_themeID") ?? SlateThemeID.freshOlive.rawValue
        themeID = SlateThemeID(rawValue: raw) ?? .freshOlive
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

// MARK: - Typography (브랜드: Pretendard, 없으면 시스템 고딕 폴백)
extension Font {
    /// Pretendard 번들 여부 (Regular 등록 확인). 미번들이면 시스템 폰트 사용.
    /// Xcode에 Pretendard-Regular/Medium/Bold(.otf) 추가 + Info.plist UIAppFonts 등록 시 자동 활성화.
    private static let pretendardAvailable: Bool = UIFont(name: "Pretendard-Regular", size: 12) != nil

    private static func pretendardName(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy:        return "Pretendard-Bold"
        case .bold:                 return "Pretendard-Bold"
        case .semibold:             return "Pretendard-SemiBold"
        case .medium:               return "Pretendard-Medium"
        case .light, .thin, .ultraLight: return "Pretendard-Light"
        default:                    return "Pretendard-Regular"
        }
    }

    /// 본문·UI 기본 폰트 (Pretendard → 시스템 고딕)
    static func slateSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if pretendardAvailable { return .custom(pretendardName(weight), size: size) }
        return .system(size: size, weight: weight)
    }

    /// 헤드라인/타이틀 보이스 — 브랜드는 고딕 전용. Pretendard 우선, 폴백도 고딕(세리프 미사용).
    static func slateSerif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        slateSans(size, weight: weight)
    }

    /// (레거시) 손글씨 — 브랜드 고딕 전환으로 사실상 미사용. Pretendard/시스템으로 폴백.
    static func slateHand(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        slateSans(size, weight: weight)
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
