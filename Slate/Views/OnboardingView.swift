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

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image("name_logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 250)

            VStack(spacing: 20) {
                Text("What should we call you?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SlateColor.inkSoft)

                HStack {
                    TextField("Your Name", text: $userName)
                        .padding(.leading, 24)
                        .font(.system(size: 18))
                        .foregroundColor(SlateColor.ink)

                    Button(action: { loginAction() }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(userName.isEmpty ? SlateColor.inkFaint.opacity(0.4) : SlateColor.leafDeep)
                            .padding(8)
                    }
                    .disabled(userName.isEmpty)
                }
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(SlateColor.paperSoft)
                        .shadow(color: SlateColor.ink.opacity(0.06), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(SlateColor.inkFaint.opacity(0.2), lineWidth: 1)
                )
                .frame(maxWidth: 340)
                .padding(.horizontal, 32)

                Text("You can change this anytime.")
                    .font(.system(size: 13))
                    .foregroundColor(SlateColor.inkSoft)
            }
            .padding(.bottom, 60)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slatePaperBackground()
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
