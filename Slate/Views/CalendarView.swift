import SwiftUI
import SwiftData

// MARK: - [1] 메인 캘린더 화면 (CalendarView)
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var inputImages: [UIImage] = []
    @State private var showCustomCamera = false
    
    // 데이터베이스 실시간 연동
    @Query(sort: \PhotoRecord.date) private var allRecords: [PhotoRecord]
    @ObservedObject var spaceManager = SpaceManager.shared
    
    @State private var selectedCategory = "Daily"
    @State private var navigateToCreateSpace = false
    @State private var showImagePicker = false
    @State private var photoDate: Date?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var currentTime = Date()
    @State private var showActionSheet = false
    @State private var targetDate: Date = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var monthInterval: [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 1))!
        let endDate = calendar.date(byAdding: .month, value: 3, to: Date())!
        var months: [Date] = []
        var current = startDate
        while current <= endDate {
            months.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }
        return months
    }

    private var currentMonthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        GeometryReader { outerGeometry in
            let totalWidth = outerGeometry.size.width
            
            VStack(spacing: 0) {
                // (A) 헤더 섹션
                CalendarHeaderView(currentTime: currentTime)
                
                // (B) 카테고리 선택 섹션
                CalendarCategorySelector(selectedCategory: $selectedCategory,
                                        navigateToCreateSpace: $navigateToCreateSpace,
                                        spaceManager: spaceManager)
                
                // (C) 메인 캘린더 리스트
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 45) {
                            ForEach(monthInterval, id: \.self) { month in
                                MonthSectionView(month: month,
                                                 showActionSheet: $showActionSheet,
                                                 targetDate: $targetDate,
                                                 allRecords: allRecords,
                                                 totalWidth: totalWidth,
                                                 selectedCategory: selectedCategory)
                                    .id(month)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 150)
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo(currentMonthStart, anchor: .top)
                        }
                    }
                }
            }
            // ⭐️ 네비게이션 및 시트 설정
            .navigationDestination(isPresented: $navigateToCreateSpace) {
                CreateSpaceView()
            }
            .confirmationDialog("Add your moment", isPresented: $showActionSheet, titleVisibility: .visible) {
                Button("Take a Photo") { showCustomCamera = true }
                Button("Choose from Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $inputImages, detectedDate: photoDate ?? targetDate)
                    .onDisappear {
                        saveSelectedImages()
                    }
            }
            .fullScreenCover(isPresented: $showCustomCamera) {
                NavigationStack {
                    CameraView()
                        .environmentObject(SpaceManager.shared)
                }
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .onReceive(timer) { currentTime = $0 }
        .navigationBarBackButtonHidden(true)
    }
    
    // 사진 저장 로직 분리
    private func saveSelectedImages() {
        for img in inputImages {
            let data = img.jpegData(compressionQuality: 0.7)
            let newRecord = PhotoRecord(
                date: targetDate,
                memo: "",
                imageData: data,
                spaceTag: selectedCategory
            )
            modelContext.insert(newRecord)
        }
        try? modelContext.save()
        inputImages = []
    }
}

// MARK: - [2] 커스텀 헤더 뷰 (CalendarHeaderView)
struct CalendarHeaderView: View {
    let currentTime: Date
    
    // ⭐️ 1. 알림 유무와 애니메이션 상태값 추가
    @State private var hasNotification: Bool = true // 나중에 실제 데이터와 연결하세요!
    @State private var animateGlow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    // 🔔 알람 버튼
                    NavigationLink(destination: SocialFeedView()) {
                        ZStack {
                            if hasNotification {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                // ⭐️ 채도를 낮춘 회색 톤 (보드라운 느낌)
                                                Color(white: 0.85).opacity(animateGlow ? 0.8 : 0.1),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 2,
                                            endRadius: 20
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    // ⭐️ 스케일 변화도 아주 미세하게 (1.0 -> 1.1)
                                    .scaleEffect(animateGlow ? 1.1 : 1.0)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                            animateGlow = true
                                        }
                                    }
                            }
                            
                            Image(systemName: hasNotification ? "bell.badge" : "bell")
                                .font(.system(size: 17)) // 크기 살짝 줄여서 더 정갈하게
                                .foregroundColor(Color(white: 0.2)) // 완전 검정보다 짙은 회색이 더 고급짐
                        }
                        .padding(.leading, 16)
                    }
                    
                    Spacer()
                
                    // 오른쪽 쓰레기통 버튼 (기존 유지)
                    NavigationLink(destination: RecentlyDeletedView()) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                }
                
                // 중앙 날짜 (기존 유지)
                VStack(spacing: 2) {
                    Text(currentTime.formatted(date: .complete, time: .omitted))
                        .font(.system(size: 14, weight: .medium))
                    Text(currentTime.formatted(date: .omitted, time: .shortened) + " PST")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 50)
        }
        .padding(.vertical, 5)
        .background(Color.white)
    }
}

// MARK: - [3] 카테고리 탭 선택기
struct CalendarCategorySelector: View {
    @Binding var selectedCategory: String
    @Binding var navigateToCreateSpace: Bool
    @ObservedObject var spaceManager: SpaceManager
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(spaceManager.categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category)
                            .font(.system(size: 16, weight: selectedCategory == category ? .bold : .medium))
                            .foregroundColor(selectedCategory == category ? .black : .gray)
                            .padding(.bottom, 5)
                            .overlay(Rectangle().fill(selectedCategory == category ? Color.black : Color.clear).frame(height: 2).offset(y: 5), alignment: .bottom)
                    }
                }
                Button(action: { navigateToCreateSpace = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.gray).font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - [4] 월별 섹션 뷰 (MonthSectionView)
struct MonthSectionView: View {
    let month: Date
    @Binding var showActionSheet: Bool
    @Binding var targetDate: Date
    let allRecords: [PhotoRecord]
    let totalWidth: CGFloat
    let selectedCategory: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // ⭐️ 월 이름과 공유 버튼을 가로로 배치
            HStack(alignment: .center, spacing: 10) {
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 26, weight: .bold))
                
                NavigationLink(destination: MonthShareDetailView(
                                    month: month,
                                    records: allRecords.filter {
                                        // 해당 월에 속하고 + 현재 선택된 카테고리인 데이터만 필터링
                                        Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) &&
                                        $0.spaceTag == selectedCategory
                                    },
                                    category: selectedCategory
                                )) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)
                                }
            }
            .padding(.horizontal, 24)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...31, id: \.self) { day in
                    if let date = Calendar.current.date(byAdding: .day, value: day-1, to: month),
                       Calendar.current.isDate(date, equalTo: month, toGranularity: .month) {
                        
                        let recordsForDate = allRecords.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.spaceTag == selectedCategory
                        }
                        let cellSize = (totalWidth - 80) / 5
                        
                        if recordsForDate.isEmpty {
                            Button(action: {
                                targetDate = date
                                showActionSheet = true
                            }) {
                                CalendarCell(day: day, size: cellSize, photoCount: 0, firstImage: nil)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: DailyPhotoView(date: date, selectedCategory: selectedCategory)) {
                                CalendarCell(day: day, size: cellSize, photoCount: recordsForDate.count,
                                            firstImage: UIImage(data: recordsForDate.first?.imageData ?? Data()))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - [5] 캘린더 개별 날짜 셀 (CalendarCell)
struct CalendarCell: View {
    let day: Int
    let size: CGFloat
    let photoCount: Int
    let firstImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let uiImage = firstImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
            } else {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color.white)
                    .overlay(Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.1))
                        .font(.system(size: size * 0.3)))
            }
            
            Text("\(day)")
                .font(.system(size: size * 0.18, weight: .bold))
                .padding(size * 0.1)
                .foregroundColor(firstImage == nil ? .gray.opacity(0.5) : .white)
            
            if photoCount > 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(photoCount)")
                            .font(.system(size: 9, weight: .bold))
                            .padding(5)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return MainTabView()
        .modelContainer(container)
        .environmentObject(SpaceManager.shared)
}
