import SwiftUI
import SwiftData

struct OnboardingView: View {
    @EnvironmentObject var spaceManager: SpaceManager
    @Environment(\.modelContext) private var modelContext
    @State private var userName: String

    /// Apple 로그인에서 받은 이름을 미리 채워 넣을 수 있게 함
    init(prefillName: String = "") {
        _userName = State(initialValue: prefillName)
    }

    let slateDark = Color(hex: "#414141")
    let slateWhite = SlateColor.leafDeep

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            ZStack {
                Image("background_paper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()
                    
                    Image("name_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenWidth * 0.7)
                    
                    VStack(spacing: 20) {
                        Text("What should we call you?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SlateColor.ink.opacity(0.5))
                        
                        HStack {
                            TextField("Your Name", text: $userName)
                                .padding(.leading, 24)
                                .font(.system(size: 18))
                            
                            Button(action: {
                                loginAction()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(userName.isEmpty ? SlateColor.inkFaint.opacity(0.3) : slateDark)
                                    .padding(8)
                            }
                            .disabled(userName.isEmpty)
                        }
                        .frame(width: min(screenWidth * 0.85, 340), height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white.opacity(0.6))
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(SlateColor.inkFaint.opacity(0.2), lineWidth: 1)
                        )
                        
                        Text("You can change this anytime.")
                            .font(.system(size: 13))
                            .foregroundColor(SlateColor.inkSoft)
                    }
                    .padding(.bottom, 60)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func loginAction() {
        if !userName.isEmpty {
            spaceManager.userName = userName
            
            // ── joinDate 기록 (최초 1회) ──
            if UserDefaults.standard.object(forKey: "slate_joinDate") == nil {
                UserDefaults.standard.set(Date(), forKey: "slate_joinDate")
            }
            
            // ── 기본 "Daily" Space 생성 (최초 1회) ──
            let descriptor = FetchDescriptor<Space>()
            let existingSpaces = (try? modelContext.fetch(descriptor)) ?? []
            if existingSpaces.isEmpty {
                let defaultSpace = Space(name: "Daily", category: "Daily", isDefault: true)
                modelContext.insert(defaultSpace)
            }
            
            withAnimation(.easeInOut(duration: 0.6)) {
                spaceManager.isLoggedIn = true
            }
        }
    }
}

// Color(hex:) 확장은 Theme/SlateTheme.swift로 이동

#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return NavigationStack {
        OnboardingView()
            .modelContainer(container)
            .environmentObject(SpaceManager.shared)
    }
}
