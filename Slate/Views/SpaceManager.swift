import SwiftUI

// ⭐️ 프로젝트 전체에서 이 클래스는 '딱 한 번'만 정의되어야 합니다.
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()
    
    // 1. 사용자 정보 및 상태
    @Published var userName: String = ""
    @Published var isLoggedIn: Bool = true // 로그아웃 상태 관리
    
    // 2. 카테고리(스페이스) 리스트
    @Published var categories = ["Daily"]
    
    // 3. 싱글톤 패턴을 위한 private init
    private init() {}
    
    // 4. 새 Space 추가 함수
    func addNewSpace(_ name: String) {
        // 빈 값 방지 및 중복 체크
        guard !name.isEmpty && !categories.contains(name) else { return }
        categories.append(name)
    }
}
