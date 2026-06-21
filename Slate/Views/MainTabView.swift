import SwiftUI
import SwiftData

struct MainTabView: View {
    // 테스트 인자 `-startMySlate`로 My Slate 탭에서 시작 (릴리즈 영향 없음)
    @State private var selectedTab = ProcessInfo.processInfo.arguments.contains("-startMySlate") ? 1 : 0
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
        Group {
            if selectedTab == 0 {
                NavigationStack { CalendarView() }
            } else {
                NavigationStack { MySlateView(onBack: { selectedTab = 0 }) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 다크 pill 내비를 safeAreaInset으로 → 어떤 화면도 가려지거나 짤리지 않음
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 0) {
                tabButton(icon: "calendar", index: 0)
                cameraButtonView
                tabButton(icon: "person.fill", index: 1)
            }
            .padding(.horizontal, 30)
            .frame(height: 60)
            .background(
                Capsule()
                    .fill(SlateColor.navBar)
                    .shadow(color: SlateColor.ink.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 28)
            .padding(.top, 18)   // 가운데 카메라 버튼이 위로 떠도 공간 확보
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
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(SlateColor.paper, lineWidth: 5))
                    .shadow(color: SlateColor.ink.opacity(0.30), radius: 10, x: 0, y: 5)
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(SlateColor.ink)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(y: -22)
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
