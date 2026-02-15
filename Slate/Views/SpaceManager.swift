import SwiftUI
import SwiftData

/// 프로젝트 전역 상태 관리
/// - userName, isLoggedIn: UserDefaults로 영속화 (앱 재시작 후에도 유지)
/// - categories: Space @Model에서 동적으로 로딩 (SwiftData)
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()
    
    // ── UserDefaults 영속화 (앱 재시작 후에도 유지) ──
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "slate_userName") }
    }
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "slate_isLoggedIn") }
    }
    
    // ── Space 기반 카테고리 (SwiftData에서 로딩) ──
    @Published var categories: [String] = ["Daily"]
    
    private init() {
        // UserDefaults에서 복원
        self.userName = UserDefaults.standard.string(forKey: "slate_userName") ?? ""
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "slate_isLoggedIn")
    }
    
    /// SwiftData의 Space 목록에서 카테고리를 동기화
    func syncCategories(from spaces: [Space]) {
        let spaceNames = spaces.map { $0.name }
        // "Daily"는 항상 첫 번째에 보장
        var result = ["Daily"]
        for name in spaceNames where name != "Daily" && !result.contains(name) {
            result.append(name)
        }
        if categories != result {
            categories = result
        }
    }
    
    /// 새 Space 추가 (SwiftData에 직접 insert하는 것은 View에서 처리)
    func addNewSpace(_ name: String) {
        guard !name.isEmpty && !categories.contains(name) else { return }
        categories.append(name)
    }
    
    /// 로그아웃 처리
    func logout() {
        isLoggedIn = false
        // userName은 유지 (재로그인 시 복원)
    }
    
    /// 계정 삭제 처리 — 모든 로컬 데이터 초기화
    func deleteAccount() {
        userName = ""
        isLoggedIn = false
        categories = ["Daily"]
        UserDefaults.standard.removeObject(forKey: "slate_userName")
        UserDefaults.standard.removeObject(forKey: "slate_isLoggedIn")
    }
}
