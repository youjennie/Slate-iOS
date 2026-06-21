import UIKit
import SwiftData

/// 로컬 테스트용 샘플 데이터.
/// - 인앱: Settings의 DEBUG 섹션 버튼으로 Load/Clear
/// - 커맨드라인: 스킴에 `-seedSampleData` 인자를 주면 실행 시 자동 시드 (`-clearData`로 비움)
enum SampleData {

    /// 더미 사진 1장 생성 (단색 배경 + 자연 이모지). 실제 사진 대용.
    static func placeholderImage(_ color: UIColor, emoji: String, size: CGFloat = 600) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let font = UIFont.systemFont(ofSize: size * 0.42)
            let str = emoji as NSString
            let textSize = str.size(withAttributes: [.font: font])
            str.draw(at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2),
                     withAttributes: [.font: font])
        }
        return image.jpegData(compressionQuality: 0.8)
    }

    private static let specs: [(name: String, current: String, future: String, color: UIColor, emoji: String)] = [
        ("Daily",   "Feeling a little stuck lately.", "Calm, consistent, present every day.",
         UIColor(red: 0.76, green: 0.76, blue: 0.47, alpha: 1), "🌿"),
        ("Workout", "Out of shape and low energy.",   "Strong, light, energetic.",
         UIColor(red: 0.80, green: 0.72, blue: 0.42, alpha: 1), "☀️"),
        ("Reading", "No time to read these days.",    "A book a week, a quiet mind.",
         UIColor(red: 0.78, green: 0.57, blue: 0.47, alpha: 1), "🍃"),
    ]

    /// 기존 데이터를 비우고 샘플을 채운다. (로그인/온보딩도 우회)
    @MainActor
    static func seed(into context: ModelContext) {
        clear(into: context)

        // 로그인/온보딩 우회 + joinDate
        UserDefaults.standard.set(true, forKey: "slate_isLoggedIn")
        if (UserDefaults.standard.string(forKey: "slate_userName") ?? "").isEmpty {
            UserDefaults.standard.set("YouJung", forKey: "slate_userName")
        }
        let cal = Calendar.current
        if let join = cal.date(byAdding: .day, value: -75, to: Date()) {
            UserDefaults.standard.set(join, forKey: "slate_joinDate")
        }

        // Spaces
        for (i, spec) in specs.enumerated() {
            let space = Space(name: spec.name, category: spec.name,
                              currentMemo: spec.current, futureMemo: spec.future,
                              startingPhotoData: placeholderImage(spec.color, emoji: spec.emoji),
                              isDefault: i == 0)
            context.insert(space)
        }

        // 지난 60일치 기록 (약 2/3 날짜에 기록 → streak/heatmap/gauge 채움)
        for dayOffset in 0..<60 {
            guard dayOffset % 3 != 2 else { continue }
            guard let baseDate = cal.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let spec = specs[dayOffset % specs.count]
            let count = (dayOffset % 5 == 0) ? 2 : 1
            for k in 0..<count {
                let date = cal.date(byAdding: .hour, value: 9 + k * 3, to: cal.startOfDay(for: baseDate)) ?? baseDate
                let record = PhotoRecord(
                    date: date,
                    memo: dayOffset % 7 == 0 ? "A good \(spec.name.lowercased()) day." : "",
                    imageData: placeholderImage(spec.color, emoji: spec.emoji),
                    spaceTag: spec.name
                )
                context.insert(record)
            }
        }
        try? context.save()
    }

    /// 모든 로컬 데이터 비우기
    @MainActor
    static func clear(into context: ModelContext) {
        for record in (try? context.fetch(FetchDescriptor<PhotoRecord>())) ?? [] {
            context.delete(record)
        }
        for space in (try? context.fetch(FetchDescriptor<Space>())) ?? [] {
            context.delete(space)
        }
        try? context.save()
        FutureSelfStore.clear()
    }
}
