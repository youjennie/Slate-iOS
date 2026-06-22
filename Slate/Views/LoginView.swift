import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var spaceManager: SpaceManager
    @State private var showOnboarding = false
    @State private var prefillName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Spacer()

                // 로고 이미지
                Image("login_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .padding(.horizontal, 40)

                Spacer()

                // ── Apple 로그인 (유일한 인증 수단) ──
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleLogin(result: result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .frame(maxWidth: 320)
                .cornerRadius(16)

                // ── Google 로그인 제거 → "Coming Soon" 안내 ──
                // v1.1에서 Firebase Auth Google Provider 추가 예정
                Text("More sign-in options coming soon")
                    .font(.slateSans(13))
                    .foregroundColor(SlateColor.inkSoft)
                    .padding(.top, 5)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .slatePaperBackground()
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(prefillName: prefillName)
            }
        }
    }
    
    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                showOnboarding = true
                return
            }

            // ── 안정적 사용자 식별자 저장 (재로그인/revoke 감지용) ──
            spaceManager.appleUserID = credential.user

            // ── Apple은 fullName/email을 '최초 1회'만 제공 → 있으면 이름 prefill ──
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { prefillName = name }
            }

            // ── 이미 온보딩을 끝낸(이름이 있는) 재로그인 사용자는 바로 입장 ──
            if !spaceManager.userName.isEmpty {
                withAnimation(.easeInOut(duration: 0.6)) {
                    spaceManager.isLoggedIn = true
                }
            } else {
                showOnboarding = true
            }
        case .failure(let error):
            print("Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 프리뷰
#Preview {
    LoginView()
        .environmentObject(SpaceManager.shared)
}
