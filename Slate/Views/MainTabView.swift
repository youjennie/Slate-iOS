import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isCameraPresented = false
    @StateObject private var spaceManager = SpaceManager.shared
    
    // ⭐️ [수정 포인트 1] 함수의 닫는 중괄호를 정확히 추가했습니다.
    @ViewBuilder
    private func tabButton(icon: String, title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == index ? .black : .gray)
            .padding(.bottom, 10)
        }
    } 
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. 콘텐츠 영역
            Group {
                if selectedTab == 0 {
                    NavigationStack { CalendarView() }
                } else {
                    NavigationStack { MySlateView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80) // 탭바 높이만큼 여백 확보
            
            // 2. 커스텀 하단 바
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom) {
                    tabButton(icon: "calendar", title: "Calendar", index: 0)
                    
                    cameraButtonView // 중앙 카메라 버튼
                    
                    tabButton(icon: "person.fill", title: "My Slate", index: 1)
                }
                .padding(.horizontal)
                .frame(height: 70)
                .background(Color.white)
            }
            // 홈 인디케이터 공간을 위해 배경색만 바닥까지 채움
            .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView()
        }
        .environmentObject(spaceManager)
    }
    
    private var cameraButtonView: some View {
        Button(action: { isCameraPresented = true }) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.41, green: 0.81, blue: 0.44))
                    .frame(width: 74, height: 74)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
        }
        .offset(y: -25)
    }
}

// MARK: - [Preview]
#Preview {
    let schema = Schema([PhotoRecord.self])
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
