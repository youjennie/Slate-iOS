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
