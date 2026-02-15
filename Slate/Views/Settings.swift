import SwiftUI
import SwiftData
import PhotosUI

// MARK: - [1] 설정 메인 뷰
struct MySlateSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var spaceManager = SpaceManager.shared
    
    let slateWhite = Color(red: 183/255, green: 194/255, blue: 198/255)
    let slateGreen = Color(red: 186/255, green: 206/255, blue: 156/255)

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedBio = "아름다운 과정, 따라오는 결과"
    @State private var currentBio = "아름다운 과정, 따라오는 결과"
    
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var notificationsEnabled = true
    @State private var photoPrivacyEnabled = true
    
    // ── 계정 삭제 확인 다이얼로그 ──
    @State private var showDeleteConfirmation = false

    private var initials: String {
        let name = spaceManager.userName.isEmpty ? "User" : spaceManager.userName
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            Group {
                Color(red: 0.98, green: 0.98, blue: 0.98)
                Image("background_paper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 393, height: 852)
                    .opacity(0.4)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    Spacer()
                    Text("Settings").font(.system(size: 18, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0).padding(10)
                }
                .padding(.top, 30)
                .frame(height: 90)
                .background(Color.white.opacity(0.9))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        profileHeaderSection
                        keywordSection
                        settingListSection
                        footerSection
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            editedName = spaceManager.userName
            editedBio = currentBio
        }
        // ── 계정 삭제 확인 Alert ──
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("This will permanently delete all your photos, spaces, and account data. This action cannot be undone.")
        }
    }
    
    // MARK: - 하위 뷰 컴포넌트들
    
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            Button(action: { showImagePicker = true }) {
                ZStack {
                    Circle().fill(slateGreen).frame(width: 100, height: 100)
                    if let image = profileImage {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 100, height: 100).clipShape(Circle())
                    } else {
                        Text(initials).font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            
            if isEditing {
                VStack(spacing: 12) {
                    TextField("Name", text: $editedName)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    TextField("Bio", text: $editedBio)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    Button("Save Changes") {
                        spaceManager.userName = editedName
                        currentBio = editedBio
                        isEditing = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    .font(.headline).foregroundColor(slateWhite)
                }.frame(width: 300)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Text(spaceManager.userName.isEmpty ? "User Name" : spaceManager.userName).font(.system(size: 24, weight: .bold))
                        Button(action: { isEditing = true }) { Image(systemName: "pencil").foregroundColor(.gray) }
                    }
                    Text(currentBio).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                    Text("Slate started on January 1, 2026").font(.system(size: 12)).foregroundColor(.gray.opacity(0.5))
                }
            }
        }
    }

    private var keywordSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("My Slate Keyword").font(.system(size: 15, weight: .bold)).padding(.horizontal, 25)
            HStack(spacing: 12) {
                tagView(title: "#Wellness")
                tagView(title: "#Career")
                tagView(title: "#Relationship", isInactive: true)
            }.padding(.horizontal, 25)
        }
    }

    private var settingListSection: some View {
        VStack(spacing: 25) {
            settingGroup(title: "MY SLATE") {
                settingToggleRow(title: "Notifications", isOn: $notificationsEnabled)
            }
            
            settingGroup(title: "GROWTH DATA") {
                settingRow(title: "AI Images")
                settingRow(title: "Regenerate Future Image")
            }

            settingGroup(title: "PRIVACY") {
                settingToggleRow(title: "Photo Privacy", subtitle: "Only visible to you", isOn: $photoPrivacyEnabled)
                // ── 계정 삭제 → 확인 다이얼로그 연결 ──
                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete Account").font(.system(size: 16)).foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.gray)
                    }.padding(18)
                }
            }
        }.padding(.horizontal, 25)
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    spaceManager.logout()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("Sign out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            Text("Slate v1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.4))
        }
    }
    
    // ── 실제 계정 삭제 로직 ──
    private func performAccountDeletion() {
        // 1. SwiftData 전체 삭제
        do {
            let allRecords = try modelContext.fetch(FetchDescriptor<PhotoRecord>())
            for record in allRecords {
                modelContext.delete(record)
            }
            let allSpaces = try modelContext.fetch(FetchDescriptor<Space>())
            for space in allSpaces {
                modelContext.delete(space)
            }
            try modelContext.save()
        } catch {
            print("Account deletion error: \(error)")
        }
        
        // 2. UserDefaults 전체 초기화
        UserDefaults.standard.removeObject(forKey: "slate_joinDate")
        
        // 3. SpaceManager 초기화 + 로그아웃
        spaceManager.deleteAccount()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // --- 공통 부품 함수들 ---
    private func tagView(title: String, isInactive: Bool = false) -> some View {
        Text(title).font(.system(size: 14, weight: .medium)).padding(.horizontal, 18).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 22).stroke(isInactive ? Color.gray.opacity(0.3) : Color.black, lineWidth: 1.2))
            .foregroundColor(isInactive ? .gray.opacity(0.4) : .black)
    }

    private func settingGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.gray).padding(.leading, 5)
            VStack(spacing: 0) { content() }.background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.7)))
        }
    }

    private func settingRow(title: String, isDestructive: Bool = false) -> some View {
        HStack {
            Text(title).font(.system(size: 16)).foregroundColor(isDestructive ? .red : .black)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.gray)
        }.padding(18)
    }

    private func settingToggleRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16))
                if let sub = subtitle { Text(sub).font(.system(size: 12)).foregroundColor(.gray) }
            }
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(SwitchToggleStyle(tint: slateGreen)).labelsHidden()
        }.padding(18)
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return NavigationStack {
        MySlateSettingsView()
            .modelContainer(container)
    }
}
