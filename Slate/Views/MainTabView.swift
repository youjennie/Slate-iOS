import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isCameraPresented = false
    @StateObject private var spaceManager = SpaceManager.shared
    
    @ViewBuilder
    private func tabButton(icon: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(selectedTab == index ? SlateColor.paper : Color.white.opacity(0.45))
                .frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. 콘텐츠 영역
            Group {
                if selectedTab == 0 {
                    NavigationStack { CalendarView() }
                } else {
                    NavigationStack { MySlateView(onBack: { selectedTab = 0 }) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 90)

            // 2. 다크 pill 플로팅 내비
            HStack(spacing: 0) {
                tabButton(icon: "calendar", index: 0)
                cameraButtonView
                tabButton(icon: "person.fill", index: 1)
            }
            .padding(.horizontal, 30)
            .frame(height: 62)
            .background(
                Capsule()
                    .fill(SlateColor.navBar)
                    .shadow(color: SlateColor.ink.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 28)
            .padding(.bottom, 14)
        }
        .slatePaperBackground()
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView()
        }
        .environmentObject(spaceManager)
    }

    private var cameraButtonView: some View {
        Button(action: { isCameraPresented = true }) {
            ZStack {
                Circle()
                    .fill(SlateColor.leaf)
                    .frame(width: 56, height: 56)
                Image(systemName: "camera.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(SlateColor.leafDeep)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(y: -12)
    }
}

// MARK: - [Preview]
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        return MainTabView()
            .modelContainer(container)
            .environmentObject(SpaceManager.shared)
    } catch {
        return Text("Failed to load Preview")
    }
}
