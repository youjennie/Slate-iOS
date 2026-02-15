import SwiftUI
import AuthenticationServices

// ⭐️ @main SlateApp 부분은 삭제했습니다. (SlateApp.swift에서 통합 관리하기 때문입니다.)

struct LoginView: View {
    // ⭐️ UI 변경 없이 온보딩 시트만 제어하기 위한 변수 추가
    @State private var showOnboarding = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
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
                        
                        // 1. 진짜 애플 로그인 버튼
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleLogin(result: result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(width: screenWidth * 0.8, height: 50)
                        .cornerRadius(16)
                        
                        // 2. 진짜 구글 로그인 버튼
                        Button(action: {
                            handleGoogleLogin()
                        }) {
                            HStack(spacing: 10) {
                                Image("google_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(width: screenWidth * 0.8, height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, 30)
                }
                // ⭐️ UI는 그대로 두고, 로그인이 성공하면 온보딩을 풀스크린으로 띄워줍니다.
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
            // ⭐️ 로그인 성공 시 온보딩 시트를 올립니다.
            showOnboarding = true
        case .failure(let error):
            print("Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
    
    private func handleGoogleLogin() {
        print("Google 로그인 버튼 클릭됨")
        // ⭐️ 구글 로그인 성공 가정 시 온보딩 이동
        showOnboarding = true
    }
}

// MARK: - 프리뷰 (형님이 말씀하신 프리뷰 추가)
#Preview {
    LoginView()
        .environmentObject(SpaceManager.shared)
}
