import SwiftUI   // App, Scene, WindowGroup, StateObject 등을 사용하기 위해 필요
import SwiftData // ModelContainer, Schema 등을 사용하기 위해 필요

@main
struct SlateApp: App {
    // 1. SwiftData 컨테이너 설정 (기존 유지)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PhotoRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject var spaceManager = SpaceManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if spaceManager.isLoggedIn {
                    // ⭐️ 수정: CalendarView가 아니라 하단바를 포함한 MainTabView를 불러야 합니다!
                    MainTabView()
                } else {
                    // 로그인 안 됨 -> 온보딩/로그인 화면
                    LoginView() 
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spaceManager.isLoggedIn)
            .modelContainer(sharedModelContainer)
            .environmentObject(spaceManager)
        }
    }
}
