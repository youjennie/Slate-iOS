import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var spaceManager: SpaceManager
    @State private var userName: String = ""
    
    let slateOlive = Color(hex: "#BACE9C") // 핵심 컬러 활용
    let slateWhite = Color(red: 183/255, green: 194/255, blue: 198/255)

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            ZStack {
                // 1. 배경 이미지
                Image("background_paper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth)
                    .ignoresSafeArea()

                // 2. 콘텐츠 층
                VStack(spacing: 40) {
                    Spacer()
                    
                    Image("name_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenWidth * 0.7)
                    
                    VStack(spacing: 20) {
                        Text("What should we call you?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.5))
                        
                        // 입력 필드와 버튼 섹션
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
                                    .foregroundColor(userName.isEmpty ? .gray.opacity(0.3) : slateOlive)
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
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        
                        Text("You can change this anytime.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
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
            // 애니메이션과 함께 메인 화면으로 전환
            withAnimation(.easeInOut(duration: 0.6)) {
                spaceManager.isLoggedIn = true
            }
        }
    }
}

// 편리한 사용을 위한 Color Hex 확장
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
    }
}
