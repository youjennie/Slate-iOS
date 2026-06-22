import SwiftUI
import SwiftData
import Photos
import UIKit

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var spaceManager: SpaceManager

    /// 촬영한 사진을 저장할 카테고리(Space). 호출하는 화면에서 주입
    var selectedCategory: String = "Daily"

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
                                .fill(SlateColor.inkFaint.opacity(0.1))
                                .frame(width: screenWidth, height: cameraHeight)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(SlateColor.inkSoft)
                                        Text("Camera access required")
                                            .font(.system(size: 14))
                                            .foregroundColor(SlateColor.inkSoft)
                                        Button("Open Settings") {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(SlateColor.skyDeep)
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
        .alert("Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your photo has been saved.")
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
                    .foregroundColor(SlateColor.ink)
            }
            Spacer()
            
            // ── 전면/후면 카메라 전환 버튼 ──
            Button(action: { cameraService.toggleCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18))
                    .foregroundColor(SlateColor.ink)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("Auto Save").font(.system(size: 14)).foregroundColor(SlateColor.ink)
                Toggle("", isOn: $autoSave).labelsHidden().tint(SlateColor.leaf)
            }
        }
        .padding(.horizontal, 20).frame(height: 50)
    }
    
    // MARK: - 사진 촬영
    @MainActor
    private func takePhotoAndSave() {
        if cameraService.isCameraAuthorized {
            // ── 실제 카메라로 촬영 + 선택한 스타일(날짜/시간 워터마크) 합성 ──
            cameraService.takePhoto { image in
                guard let uiImage = image else { return }
                Task { @MainActor in
                    savePhoto(composited(uiImage))
                }
            }
        } else {
            // 카메라 권한 없을 때 → 필터 오버레이만 렌더링해서 저장 (기존 방식 폴백)
            let screenWidth = UIScreen.main.bounds.width
            let cameraHeight = screenWidth / currentAspectRatio
            let renderer = ImageRenderer(content:
                ZStack {
                    Rectangle().fill(SlateColor.inkFaint.opacity(0.1))
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

        // SwiftData 기록 — 호출한 화면에서 주입된 카테고리 사용
        if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
            let newRecord = PhotoRecord(date: Date(), imageData: imageData, spaceTag: selectedCategory)
            modelContext.insert(newRecord)
        }
        showingSaveAlert = true
    }

    /// 촬영 원본 위에 선택한 스타일의 날짜/시간 워터마크를 합성
    /// - 오버레이는 390pt 기준 레이아웃으로 그린 뒤 사진 해상도에 맞춰 확대 → 비율/선명도 유지
    @MainActor
    private func composited(_ base: UIImage) -> UIImage {
        let targetSize = base.size
        guard targetSize.width > 0, targetSize.height > 0 else { return base }
        let ratio = targetSize.width / 390.0

        let renderer = ImageRenderer(content:
            filterOverlayView(index: selectedFilterIndex)
                .frame(width: 390, height: targetSize.height / max(ratio, 0.001))
                .scaleEffect(ratio)
                .frame(width: targetSize.width, height: targetSize.height)
        )
        renderer.scale = base.scale
        guard let overlayImage = renderer.uiImage else { return base }

        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            base.draw(in: CGRect(origin: .zero, size: targetSize))
            overlayImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // MARK: - 필터 선택기
    private var filterSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(0..<4) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(selectedFilterIndex == index ? SlateColor.leafDeep : SlateColor.inkFaint.opacity(0.1)).frame(width: 55, height: 55)
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
                    .fill(SlateColor.leafDeep)
                    .frame(width: 75, height: 75)
                    .overlay(Image(systemName: "plus").font(.system(size: 28, weight: .bold)).foregroundColor(.white))
            }
            
            Spacer()
            
            // 3:4 비율
            Button(action: { withAnimation { currentAspectRatio = 3 / 4 } }) {
                Image(systemName: "rectangle.portrait")
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(currentAspectRatio == 3/4 ? 1 : 0.2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(SlateColor.ink.opacity(currentAspectRatio == 3/4 ? 1 : 0.2), lineWidth: 2).frame(width: 16, height: 22))
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
