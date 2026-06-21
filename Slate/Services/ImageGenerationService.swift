import UIKit

enum ImageGenerationError: LocalizedError {
    case missingAPIKey
    case encodingFailed
    case requestFailed(String)
    case noImageInResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API 키가 설정되지 않았어요. Info.plist에 GEMINI_API_KEY를 추가하면 미래자아 생성이 켜집니다."
        case .encodingFailed:
            return "사진을 인코딩하지 못했어요."
        case .requestFailed(let message):
            return "이미지 생성 요청이 실패했어요: \(message)"
        case .noImageInResponse:
            return "응답에서 이미지를 찾지 못했어요."
        }
    }
}

/// Google Gemini 이미지 생성 API로 '미래의 나' 이미지를 생성하는 서비스
/// - 실제 네트워크 호출 코드까지 구현되어 있으며, GEMINI_API_KEY만 채우면 동작
/// - 키가 없으면 .missingAPIKey 를 throw (앱은 안내 문구로 graceful 처리)
final class ImageGenerationService {
    static let shared = ImageGenerationService()
    private init() {}

    /// Before 사진 + 사용자의 미래 목표 문구로 '미래의 나' 이미지를 생성
    func generateFutureSelf(from baseImage: UIImage, futureGoal: String) async throws -> UIImage {
        let apiKey = SlateConfig.geminiAPIKey
        guard !apiKey.isEmpty else { throw ImageGenerationError.missingAPIKey }
        guard let jpeg = baseImage.jpegData(compressionQuality: 0.85) else {
            throw ImageGenerationError.encodingFailed
        }

        let model = SlateConfig.geminiImageModel
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: endpoint) else {
            throw ImageGenerationError.requestFailed("잘못된 endpoint")
        }

        let goal = futureGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = """
        This is a photo of a person documenting a personal wellness and growth journey. \
        Generate a realistic, uplifting "future self" portrait that imagines this same person \
        after achieving their goal, while keeping their identity clearly recognizable. \
        Goal: \(goal.isEmpty ? "becoming a healthier, more confident version of themselves" : goal)
        """

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": jpeg.base64EncodedString()]]
                ]
            ]],
            "generationConfig": ["responseModalities": ["IMAGE"]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ImageGenerationError.requestFailed(message)
        }

        // 응답 파싱: candidates[0].content.parts[].inlineData.data (base64 이미지)
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else { throw ImageGenerationError.noImageInResponse }

        for part in parts {
            // 카멜/스네이크 케이스 양쪽 대응
            let inline = (part["inlineData"] ?? part["inline_data"]) as? [String: Any]
            if let base64 = inline?["data"] as? String,
               let imageData = Data(base64Encoded: base64),
               let image = UIImage(data: imageData) {
                return image
            }
        }
        throw ImageGenerationError.noImageInResponse
    }
}
