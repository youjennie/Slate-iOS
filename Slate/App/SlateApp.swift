import SwiftUI
import SwiftData

@main
struct SlateApp: App {
    // ── SwiftData 컨테이너: PhotoRecord + Space 모두 등록 ──
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PhotoRecord.self, Space.self])
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
                    MainTabView()
                        .onAppear {
                            cleanupDeletedRecords()
                        }
                } else {
                    LoginView()
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spaceManager.isLoggedIn)
            .modelContainer(sharedModelContainer)
            .environmentObject(spaceManager)
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
