import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            NavigationStack {
                ZStack {
                    // [배경층] 종이 질감 이미지
                    Image("background_paper")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    // [콘텐츠층]
                    VStack(spacing: 15) {
                        Spacer()
                        
                        // 로고 이미지
                        Image("login_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenWidth * 0.8)
                        
                        Spacer()
                        
                        // ── Apple 로그인 (유일한 인증 수단) ──
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleLogin(result: result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(width: screenWidth * 0.8, height: 50)
                        .cornerRadius(16)
                        
                        // ── Google 로그인 제거 → "Coming Soon" 안내 ──
                        // v1.1에서 Firebase Auth Google Provider 추가 예정
                        
                        Text("More sign-in options coming soon")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.top, 5)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 30)
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
            }
        }
    }
    
    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            print("Apple 로그인 성공: \(auth)")
            showOnboarding = true
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
