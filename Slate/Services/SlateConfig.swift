import Foundation

/// 앱 전역 설정값 (Info.plist에서 로딩)
/// - API 키는 코드/깃에 하드코딩하지 말고 Info.plist 또는 xcconfig로 주입할 것
enum SlateConfig {
    /// Gemini API 키. Info.plist의 "GEMINI_API_KEY"에서 읽음 (없으면 빈 문자열 → 기능 비활성)
    static var geminiAPIKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
    }

    /// 이미지 생성 모델명. Info.plist "GEMINI_IMAGE_MODEL"로 override 가능
    static var geminiImageModel: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "GEMINI_IMAGE_MODEL") as? String
        return (value?.isEmpty == false) ? value! : "gemini-2.5-flash-image"
    }

    /// AI 미래자아 기능 사용 가능 여부 (키가 채워졌는지)
    static var isImageGenerationAvailable: Bool { !geminiAPIKey.isEmpty }
}

// MARK: - 광고 설정 (AdMob) — UC-04 과거 편집 리워드 광고
/// 광고 유닛 ID는 Info.plist 빌드세팅으로 주입(없으면 Google 공식 '테스트' ID 사용).
/// 릴리즈 전: AdMob 콘솔에서 앱 등록 → 리워드 광고 유닛 생성 → 아래 키로 실제 ID 주입.
///   INFOPLIST_KEY_GADApplicationIdentifier = ca-app-pub-XXXX~YYYY   (앱 ID)
///   INFOPLIST_KEY_SLATE_REWARDED_UNIT_ID   = ca-app-pub-XXXX/ZZZZ   (리워드 유닛)
enum SlateAdConfig {
    /// Google 공식 테스트 ID (개발 중 항상 채워짐 — 실수로 실광고 클릭 방지)
    static let testAppID        = "ca-app-pub-3940256099942544~1458002511"
    static let testRewardedUnit = "ca-app-pub-3940256099942544/1712485313"

    /// AdMob 앱 ID (Info.plist GADApplicationIdentifier → 없으면 테스트)
    static var appID: String {
        (Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String) ?? testAppID
    }

    /// 리워드 광고 유닛 ID (Info.plist SLATE_REWARDED_UNIT_ID → 없으면 테스트)
    static var rewardedUnitID: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "SLATE_REWARDED_UNIT_ID") as? String
        return (v?.isEmpty == false) ? v! : testRewardedUnit
    }

    /// 과거 편집 잠금 해제에 필요한 광고 시청 횟수 (사업계획서 UC-04 = 3회)
    static let rewardedCountForPastEdit = 3
}
