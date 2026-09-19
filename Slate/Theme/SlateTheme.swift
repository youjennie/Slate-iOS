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
/// 디자인 시스템: **흰 배경 + 회색 테두리 + 단일 포인트 컬러.**
/// 배경/텍스트/테두리는 전 테마 공통(뉴트럴), 사용자는 "포인트 컬러 하나"만 고른다.
enum SlateThemeID: String, CaseIterable, Identifiable {
    case butter, sage, olive, terracotta, blue
    var id: String { rawValue }
    var label: String {
        switch self {
        case .butter:     return "Butter"
        case .sage:       return "Sage"
        case .olive:      return "Olive"
        case .terracotta: return "Terracotta"
        case .blue:       return "Blue"
        }
    }
    /// 설정 칩에 표시할 대표 포인트 컬러
    var accent: Color { palette.leaf }
    /// 미리보기 칩(포인트색 하나)
    var swatch: [Color] { [palette.leaf] }

    var palette: SlatePalette {
        // ── 공통 뉴트럴: 흰 배경 · 근블랙 텍스트 · 회색 테두리 ──
        let paper     = Color(hex: "#FFFFFF")   // 순백 배경
        let paperSoft = Color(hex: "#FFFFFF")   // 카드
        let paperDeep = Color(hex: "#F4F4F3")   // 아주 옅은 회색 fill
        let sand      = Color(hex: "#F0F0EF")
        let sandDeep  = Color(hex: "#E3E3E1")
        let ink       = Color(hex: "#232322")   // 근블랙 텍스트
        let inkSoft   = Color(hex: "#6E6E6A")   // 보조 텍스트(중간 회색)
        let inkFaint  = Color(hex: "#C7C7C3")   // 테두리·라인·비활성(연회색)
        let navBar    = Color(hex: "#232322")   // 하단 내비(뉴트럴 근블랙)

        // 카테고리 보조색 = 뉴트럴 그레이 (포인트색 하나만 튀게)
        let honey = Color(hex: "#C7C7C3"); let honeyDeep = Color(hex: "#8E8E8A")
        let pink  = Color(hex: "#AEAEA9"); let pinkDeep  = Color(hex: "#7C7C77")
        let sky   = Color(hex: "#D6D6D2"); let skyDeep   = Color(hex: "#9A9A95")
        let lilac = Color(hex: "#9A9A95"); let lilacDeep = Color(hex: "#6E6E69")

        // ── 단일 포인트 컬러만 테마별로 달라진다 ──
        let leaf, leafDeep, leafSoft: Color
        switch self {
        case .butter:   // 밝은 버터 노랑
            leaf = Color(hex: "#F6D96E"); leafDeep = Color(hex: "#C99E2E"); leafSoft = Color(hex: "#FBF2CF")
        case .olive:
            leaf = Color(hex: "#C1C177"); leafDeep = Color(hex: "#8A9440"); leafSoft = Color(hex: "#EDEFDA")
        case .sage:   // 2번 — 살짝 밝게
            leaf = Color(hex: "#9CC096"); leafDeep = Color(hex: "#5E8A57"); leafSoft = Color(hex: "#E3EFE0")
        case .terracotta:
            leaf = Color(hex: "#D08A6A"); leafDeep = Color(hex: "#A05638"); leafSoft = Color(hex: "#F1DACD")
        case .blue:
            leaf = Color(hex: "#6E97C0"); leafDeep = Color(hex: "#3E6690"); leafSoft = Color(hex: "#D6E2EF")
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
        let raw = UserDefaults.standard.string(forKey: "slate_themeID") ?? SlateThemeID.butter.rawValue
        themeID = SlateThemeID(rawValue: raw) ?? .butter
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

// MARK: - 배경 (순백)
/// 흰 배경. (질감 텍스처 제거 — 깨끗한 화이트)
struct PaperBackground: View {
    var body: some View {
        SlateColor.paper.ignoresSafeArea()
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
