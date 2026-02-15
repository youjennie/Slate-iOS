import SwiftUI
import SwiftData

struct MySlateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isCameraPresented = false
    
    // ── SwiftData에서 실시간 데이터 로딩 ──
    @Query(sort: \PhotoRecord.date) private var allRecords: [PhotoRecord]
    
    // 형님의 컨셉 컬러
    let slateWhite = Color(red: 183/255, green: 194/255, blue: 198/255)
    let slateGreen = Color(red: 186/255, green: 206/255, blue: 156/255)
    let cameraGreen = Color(red: 0.41, green: 0.81, blue: 0.44)
    
    // ── 실시간 계산 (하드코딩 제거) ──
    private var progress: SlateProgress {
        ProgressCalculator.calculate(from: allRecords)
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let screenHeight = proxy.size.height
            
            ZStack {
                // [1] 배경 레이어
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.98)
                    Image("background_paper")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenWidth)
                        .clipped()
                }
                .ignoresSafeArea()

                // [2] 콘텐츠 레이어
                VStack(spacing: 0) {
                    
                    // --- 상단 헤더 ---
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .padding(10)
                                .contentShape(Rectangle())
                        }
                        
                        Spacer()
                        
                        Text("My Slate")
                            .font(.system(size: 18, weight: .bold))
                        
                        Spacer()
                        
                        NavigationLink(destination: MySlateSettingsView()) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .padding(10)
                        }
                    }
                    .padding(.top, 10).padding(.bottom, 10)
                    .padding(.horizontal, 10)
                    .frame(height: 60)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 50) {
                            // 3. 로고 및 타이틀
                            VStack(spacing: 0) {
                                Image("name_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                    .padding(.bottom, -60)
                                    .padding(.top, -10)
                                
                                Text("Your Future-Self Awaits")
                                    .font(.system(size: 26, weight: .bold))
                                    .padding(.top, 5)
                                    .padding(.bottom, 10)
                                
                                Text("Slate turns your moments into\na picture of who you're becoming.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            .padding(.top, 30)

                            // 4. Before & After
                            HStack(spacing: 40) {
                                comparisonCircle(imageName: "user_before", label: "Before")
                                comparisonCircle(imageName: "ai_after", label: "After")
                            }

                            // 5. 프로그레스 섹션 (실시간 계산)
                            VStack(spacing: 20) {
                                // ── 실시간 계산된 Progress % ──
                                Text("\(Int(progress.progressPercent))% closer")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 12) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.black.opacity(0.05)).frame(height: 12)
                                            Capsule()
                                                .fill(slateWhite)
                                                .frame(width: geo.size.width * CGFloat(progress.progressPercent / 100.0), height: 12)
                                        }
                                    }
                                    .frame(height: 12)
                                    
                                    HStack {
                                        Text("Past").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                                        Spacer()
                                        Text("Future").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 30)
                                
                                // ── Streak & Days 표시 ──
                                HStack(spacing: 30) {
                                    statBadge(value: "\(progress.totalDays)", label: "Days")
                                    statBadge(value: "\(progress.currentStreak)", label: "Streak")
                                    statBadge(value: "\(progress.longestStreak)", label: "Best")
                                }
                                .padding(.top, 10)
                            }
                            
                            Spacer().frame(height: 50)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // 원형 이미지 컴포넌트
    private func comparisonCircle(imageName: String, label: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(red: 0.9, green: 0.9, blue: 0.9)).frame(width: 135, height: 135)
                Image(systemName: "photo.fill").font(.system(size: 40)).foregroundColor(.white)
                Image(imageName).resizable().scaledToFill().frame(width: 135, height: 135).clipShape(Circle())
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.08), radius: 8)
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
        }
    }
    
    // 통계 뱃지 컴포넌트
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return NavigationStack {
        MySlateView()
            .modelContainer(container)
            .environmentObject(SpaceManager.shared)
    }
}
