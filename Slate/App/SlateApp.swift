import SwiftUI
import SwiftData
import AuthenticationServices

@main
struct SlateApp: App {
    // ── SwiftData 컨테이너: PhotoRecord + Space 모두 등록 ──
    // ⚠️ 기존 DB와 호환성을 위해 실패 시 DB 리셋 후 재생성
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PhotoRecord.self, Space.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 기존 DB 스키마와 충돌 시 → DB 파일 삭제 후 재생성
            print("⚠️ SwiftData migration failed: \(error). Resetting database...")
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            // .store-shm, .store-wal 파일도 삭제
            try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "default.store-shm"))
            try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "default.store-wal"))
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    @StateObject var spaceManager = SpaceManager.shared
    @StateObject var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("-openFeed") {
                    // 로컬 테스트용: 소셜 피드 바로 열기 (릴리즈 영향 없음)
                    FeedTestHarness()
                } else if spaceManager.isLoggedIn {
                    MainTabView()
                        .onAppear {
                            cleanupDeletedRecords()
                            verifyAppleCredential()
                        }
                } else {
                    LoginView()
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spaceManager.isLoggedIn)
            .modelContainer(sharedModelContainer)
            .environmentObject(spaceManager)
            .environmentObject(themeManager)
            .task { handleLaunchArguments() }
        }
    }

    /// 커맨드라인 인자 처리 — 로컬 테스트용
    /// Scheme ▸ Run ▸ Arguments에 `-seedSampleData` 또는 `-clearData` 추가
    @MainActor
    private func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-seedSampleData") {
            SampleData.seed(into: sharedModelContainer.mainContext)
            spaceManager.isLoggedIn = true
            spaceManager.userName = UserDefaults.standard.string(forKey: "slate_userName") ?? "YouJung"
        } else if args.contains("-clearData") {
            SampleData.clear(into: sharedModelContainer.mainContext)
        }
    }
    
    /// 앱 실행 시 Apple ID 자격 상태 확인 — 사용자가 설정에서 Apple 로그인을
    /// 해지(revoked)했거나 계정을 찾을 수 없으면 자동 로그아웃 처리
    private func verifyAppleCredential() {
        guard let userID = spaceManager.appleUserID else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
            DispatchQueue.main.async {
                if state == .revoked || state == .notFound {
                    spaceManager.logout()
                }
            }
        }
    }

    /// 30일 이상 지난 soft-deleted 레코드 영구 삭제
    private func cleanupDeletedRecords() {
        let context = sharedModelContainer.mainContext
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        
        let descriptor = FetchDescriptor<PhotoRecord>(
            predicate: #Predicate<PhotoRecord> {
                $0.isDeleted == true
            }
        )
        
        do {
            let deletedRecords = try context.fetch(descriptor)
            for record in deletedRecords {
                if let deletedAt = record.deletedAt, deletedAt < thirtyDaysAgo {
                    context.delete(record)
                }
            }
            try context.save()
        } catch {
            print("Cleanup error: \(error)")
        }
    }
}

/// 로컬 테스트 하니스 — `-openFeed`로 실행. 실제 앱(Calendar→벨)과 똑같이
/// NavigationLink로 피드를 push하므로 뒤로가기(dismiss→pop)도 그대로 검증된다.
private struct FeedTestHarness: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Feed Test Harness")
                    .font(.slateSans(15, weight: .bold))
                    .foregroundColor(SlateColor.inkSoft)
                NavigationLink(destination: SocialFeedView()) {
                    Text("Open Feed")
                        .font(.slateSans(16, weight: .bold))
                        .foregroundColor(SlateColor.paperSoft)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(Capsule().fill(SlateColor.ink))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .slatePaperBackground()
        }
    }
}
