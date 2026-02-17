import SwiftUI
import SwiftData
import Photos

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var spaceManager: SpaceManager
    
    // ── 실제 카메라 서비스 ──
    @StateObject private var cameraService = CameraService()
    
    @State private var selectedFilterIndex = 0
    @State private var autoSave = true
    @State private var showingSaveAlert = false
    @State private var currentAspectRatio: CGFloat = 3 / 4
    
    // ── 실시간 날짜/시간 (하드코딩 제거) ──
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var dateStr: String {
        currentTime.formatted(.dateTime.month(.wide).day().year())
    }
    private var timeStr: String {
        currentTime.formatted(date: .omitted, time: .shortened)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let cameraHeight = screenWidth / currentAspectRatio
            
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // (1) 상단 헤더
                    headerSection
                    
                    Spacer()
                    
                    // (2) 실제 카메라 프리뷰 + 필터 오버레이
                    ZStack {
                        if cameraService.isCameraAuthorized {
                            // ── 실제 카메라 프리뷰 ──
                            CameraPreviewView(session: cameraService.session)
                                .frame(width: screenWidth, height: cameraHeight)
                        } else {
                            // 카메라 권한 없을 때 플레이스홀더
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: screenWidth, height: cameraHeight)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("Camera access required")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Button("Open Settings") {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.blue)
                                    }
                                )
                        }
                        
                        // 필터 오버레이 (날짜/시간/워터마크)
                        filterOverlayView(index: selectedFilterIndex)
                            .frame(width: screenWidth, height: cameraHeight)
                    }
                    .frame(width: screenWidth, height: cameraHeight)
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
        .onAppear {
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
        }
        .onReceive(timer) { currentTime = $0 }
        .alert("저장 완료", isPresented: $showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("사진이 저장되었습니다.")
        }
        .alert("Camera Permission", isPresented: $cameraService.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Slate needs camera access to capture your moments. Please enable it in Settings.")
        }
    }
    
    // MARK: - 상단 헤더
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            Spacer()
            
            // ── 전면/후면 카메라 전환 버튼 ──
            Button(action: { cameraService.toggleCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("Auto Save").font(.system(size: 14)).foregroundColor(.black)
                Toggle("", isOn: $autoSave).labelsHidden().tint(Color(red: 0.41, green: 0.81, blue: 0.44))
            }
        }
        .padding(.horizontal, 20).frame(height: 50)
    }
    
    // MARK: - 사진 촬영
    @MainActor
    private func takePhotoAndSave() {
        if cameraService.isCameraAuthorized {
            // ── 실제 카메라로 촬영 ──
            cameraService.takePhoto { image in
                guard let uiImage = image else { return }
                savePhoto(uiImage)
            }
        } else {
            // 카메라 권한 없을 때 → 필터 오버레이만 렌더링해서 저장 (기존 방식 폴백)
            let screenWidth = UIScreen.main.bounds.width
            let cameraHeight = screenWidth / currentAspectRatio
            let renderer = ImageRenderer(content:
                ZStack {
                    Rectangle().fill(Color.gray.opacity(0.1))
                    filterOverlayView(index: selectedFilterIndex)
                }
                .frame(width: screenWidth, height: cameraHeight)
            )
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                savePhoto(uiImage)
            }
        }
    }
    
    private func savePhoto(_ uiImage: UIImage) {
        // 앨범 저장 (Auto Save 켜져 있을 때)
        if autoSave {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
        
        // SwiftData 기록 — 현재 선택된 카테고리 사용
        if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
            let spaceTag = spaceManager.categories.first ?? "Daily"
            let newRecord = PhotoRecord(date: Date(), imageData: imageData, spaceTag: spaceTag)
            modelContext.insert(newRecord)
        }
        showingSaveAlert = true
    }

    // MARK: - 필터 선택기
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

    // MARK: - 하단 컨트롤
    private var shutterControlSection: some View {
        HStack {
            // 1:1 비율
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
            
            // 3:4 비율
            Button(action: { withAnimation { currentAspectRatio = 3 / 4 } }) {
                Image(systemName: "rectangle.portrait")
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(currentAspectRatio == 3/4 ? 1 : 0.2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(currentAspectRatio == 3/4 ? 1 : 0.2), lineWidth: 2).frame(width: 16, height: 22))
            }
        }
        .padding(.horizontal, 60).padding(.bottom, 30)
    }

    // MARK: - 필터 오버레이 (실시간 날짜/시간)
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
        let schema = Schema([PhotoRecord.self, Space.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    return CameraView()
        .modelContainer(container)
        .environmentObject(SpaceManager.shared)
}
