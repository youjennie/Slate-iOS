import SwiftUI
import SwiftData
import PhotosUI

// MARK: - [1] 설정 메인 뷰
struct MySlateSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var spaceManager = SpaceManager.shared // 전역 상태 참조
    
    let slateWhite = Color(red: 183/255, green: 194/255, blue: 198/255)
    let slateGreen = Color(red: 186/255, green: 206/255, blue: 156/255)

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedBio = "아름다운 과정, 따라오는 결과"
    @State private var currentBio = "아름다운 과정, 따라오는 결과"
    
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var notificationsEnabled = true
    @State private var photoPrivacyEnabled = true // ⭐️ 누락되었던 상태값 복구

    private var initials: String {
        let name = spaceManager.userName.isEmpty ? "User" : spaceManager.userName
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            // [1] 배경 레이어 - 고정 배경 (틀어짐 방지용 ignoresSafeArea)
            Group {
                Color(red: 0.98, green: 0.98, blue: 0.98)
                Image("background_paper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 393, height: 852) // ⭐️ 형님과 맞춘 아이폰 표준 규격
                    .opacity(0.4)
            }
            .ignoresSafeArea()

            // [2] 콘텐츠 레이어 - 상단 헤더 고정 및 내부 패딩
            VStack(spacing: 0) {
                // 커스텀 상단 헤더 (높이 60 고정하여 상단 짤림 방지)
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
                .padding(.top,30)
                .frame(height: 90)
                .background(Color.white.opacity(0.9))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        // 1. 프로필 헤더
                        profileHeaderSection
                        
                        // 2. 키워드 섹션
                        keywordSection
                        
                        // 3. 설정 리스트 (누락됐던 PRIVACY 포함)
                        settingListSection
                        
                        // 4. 푸터
                        footerSection
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100) // ⭐️ 하단 공백 및 짤림 방지용 여유 공간
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar) // ⭐️ 이 한 줄이 하단바를 즉시 삭제합니다!
        .onAppear {
            editedName = spaceManager.userName
            editedBio = currentBio
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

            // ⭐️ 형님이 찾으시던 PRIVACY 섹션 정확히 복구했습니다!
            settingGroup(title: "PRIVACY") {
                settingToggleRow(title: "Photo Privacy", subtitle: "Only visible to you", isOn: $photoPrivacyEnabled)
                settingRow(title: "Delete Account", isDestructive: true)
            }
        }.padding(.horizontal, 25)
    }

    private var footerSection: some View {
            VStack(spacing: 10) {
                Button(action: {
                    // ⭐️ 로그아웃 처리
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        // 1. 로그인 상태 해제 -> SlateApp이 감지하여 OnboardingView로 즉시 전환
                        spaceManager.isLoggedIn = false
                        
                        // 2. (선택) 로그아웃 시 유저 정보도 초기화하고 싶다면 주석 해제
                        // spaceManager.userName = ""
                    }
                    
                    // 햅틱 피드백 추가
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    Text("Sign out")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                    
                }
                .padding(.top, 20)
                
                Text("Slate v0.0.5")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.4))
            }
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
    NavigationStack {
        MySlateSettingsView()
    }
}
