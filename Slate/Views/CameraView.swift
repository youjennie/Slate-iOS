import SwiftUI
import SwiftData
import Photos

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilterIndex = 0
    @State private var autoSave = true
    @State private var showingSaveAlert = false
    
    // ⭐️ 핵심: 현재 선택된 비율 상태 (기본 3:4)
    @State private var currentAspectRatio: CGFloat = 3 / 4
    
    private let dateStr = "January 25, 2026"
    private let timeStr = "8:44 PM"
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            // 비율에 따라 실시간으로 계산되는 높이
            let cameraHeight = screenWidth / currentAspectRatio
            
            ZStack {
                Color.white.ignoresSafeArea() // 하얀 배경
                
                VStack(spacing: 0) {
                    // (1) 상단 헤더
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Text("Auto Save").font(.system(size: 14)).foregroundColor(.black)
                            Toggle("", isOn: $autoSave).labelsHidden().tint(Color(red: 0.41, green: 0.81, blue: 0.44))
                        }
                    }
                    .padding(.horizontal, 20).frame(height: 50)
                    
                    Spacer()
                    
                    // (2) 가변 비율 캡쳐 영역 (이 뷰가 사진이 됨)
                    captureAreaView(screenWidth: screenWidth, cameraHeight: cameraHeight)
                        .clipped()
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentAspectRatio)
                    
                    Spacer()
                    
                    // (3) 필터 선택 리스트
                    filterSelectorSection
                    
                    // (4) 하단 촬영 및 비율 컨트롤
                    shutterControlSection
                }
            }
        }
        .navigationBarHidden(true)
        .alert("저장 완료", isPresented: $showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("선택하신 비율과 필터가 적용되어 앨범에 저장되었습니다.")
        }
    }
    
    // MARK: - [렌더링용] 캡쳐 영역 뷰
    @ViewBuilder
    private func captureAreaView(screenWidth: CGFloat, cameraHeight: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: screenWidth, height: cameraHeight)
            
            filterOverlayView(index: selectedFilterIndex)
                .frame(width: screenWidth, height: cameraHeight)
        }
    }

    // MARK: - [핵심] 사진 촬영 및 렌더링 저장 함수
    @MainActor
    private func takePhotoAndSave() {
        let screenWidth = UIScreen.main.bounds.width
        let cameraHeight = screenWidth / currentAspectRatio // ⭐️ 현재 비율 반영
        
        let renderer = ImageRenderer(content: captureAreaView(screenWidth: screenWidth, cameraHeight: cameraHeight))
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            // 앨범 저장
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            // SwiftData 기록
            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                let newRecord = PhotoRecord(date: Date(), imageData: imageData, spaceTag: "Daily")
                modelContext.insert(newRecord)
            }
            showingSaveAlert = true
        }
    }

    // MARK: - 서브 UI 컴포넌트
    private var filterSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(0..<4) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(selectedFilterIndex == index ? Color.black : Color.gray.opacity(0.1)).frame(width: 55, height: 55)
                            Text("\(index + 1)").font(.system(size: 16, weight: .bold)).foregroundColor(selectedFilterIndex == index ? .white : .black)
                        }
                        Text("Style \(index + 1)").font(.system(size: 10)).foregroundColor(.black.opacity(selectedFilterIndex == index ? 1 : 0.4))
                    }
                    .onTapGesture { withAnimation { selectedFilterIndex = index } }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
    }

    private var shutterControlSection: some View {
        HStack {
            // 1:1 비율 전환 버튼
            Button(action: { withAnimation { currentAspectRatio = 1 / 1 } }) {
                Image(systemName: "square")
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(currentAspectRatio == 1/1 ? 1 : 0.2))
            }
            
            Spacer()
            
            // 셔터 버튼
            Button(action: { takePhotoAndSave() }) {
                Circle()
                    .fill(Color(red: 0.0, green: 0.85, blue: 0.45))
                    .frame(width: 75, height: 75)
                    .overlay(Image(systemName: "plus").font(.system(size: 28, weight: .bold)).foregroundColor(.white))
            }
            
            Spacer()
            
            // 3:4 비율 전환 버튼
            Button(action: { withAnimation { currentAspectRatio = 3 / 4 } }) {
                Image(systemName: "rectangle.portrait")
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(currentAspectRatio == 3/4 ? 1 : 0.2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(currentAspectRatio == 3/4 ? 1 : 0.2), lineWidth: 2).frame(width: 16, height: 22))
            }
        }
        .padding(.horizontal, 60).padding(.bottom, 30)
    }

    @ViewBuilder
    private func filterOverlayView(index: Int) -> some View {
        VStack {
            if index == 0 {
                VStack(spacing: 5) {
                    Text(dateStr).font(.system(size: 28, weight: .bold))
                    Text(timeStr).font(.system(size: 24, weight: .medium))
                    Spacer(); HStack { Spacer(); Text("Slate").font(.custom("AvenirNext-BoldItalic", size: 40)) }
                }
            } else if index == 1 {
                VStack(alignment: .leading) {
                    Text(dateStr).font(.system(size: 18, weight: .bold))
                    Text(timeStr).font(.system(size: 16)); Spacer()
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else if index == 2 {
                VStack { Spacer(); VStack(alignment: .leading) {
                    Text(dateStr).font(.system(size: 20, weight: .black))
                    Text(timeStr).font(.system(size: 18, weight: .bold))
                }.frame(maxWidth: .infinity, alignment: .leading) }
            } else {
                VStack(alignment: .trailing) {
                    Text(dateStr).font(.system(size: 22).italic())
                    Text(timeStr).font(.system(size: 18).italic()); Spacer()
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .foregroundColor(.white).padding(30)
    }
}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([PhotoRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    return CameraView()
        .modelContainer(container)
        .environmentObject(SpaceManager.shared)
}
