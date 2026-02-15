import SwiftUI
import SwiftData

// MARK: - [1] 메인 캘린더 화면 (CalendarView)
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var inputImages: [UIImage] = []
    @State private var showCustomCamera = false
    
    // ── isDeleted == false인 레코드만 표시 ──
    @Query(
        filter: #Predicate<PhotoRecord> { $0.isDeleted == false },
        sort: \PhotoRecord.date
    ) private var activeRecords: [PhotoRecord]
    
    // ── Space 목록 로딩 (SwiftData) ──
    @Query(sort: \Space.createdAt) private var spaces: [Space]
    
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
    
    // ── 동적 월 범위: joinDate 기반 ──
    private var monthInterval: [Date] {
        let calendar = Calendar.current
        // UserDefaults에 joinDate가 없으면 현재 달 - 3개월부터
        let joinDate = UserDefaults.standard.object(forKey: "slate_joinDate") as? Date ?? calendar.date(byAdding: .month, value: -3, to: Date())!
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: joinDate))!
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
                                                 allRecords: activeRecords,
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
        .onAppear {
            // ── Space 카테고리 동기화 ──
            spaceManager.syncCategories(from: spaces)
            // ── joinDate 기록 (최초 1회) ──
            if UserDefaults.standard.object(forKey: "slate_joinDate") == nil {
                UserDefaults.standard.set(Date(), forKey: "slate_joinDate")
            }
        }
        .onChange(of: spaces) { _, newSpaces in
            spaceManager.syncCategories(from: newSpaces)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // 사진 저장 로직
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
    
    @State private var hasNotification: Bool = true
    @State private var animateGlow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    NavigationLink(destination: SocialFeedView()) {
                        ZStack {
                            if hasNotification {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(white: 0.85).opacity(animateGlow ? 0.8 : 0.1),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 2,
                                            endRadius: 20
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .scaleEffect(animateGlow ? 1.1 : 1.0)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                            animateGlow = true
                                        }
                                    }
                            }
                            
                            Image(systemName: hasNotification ? "bell.badge" : "bell")
                                .font(.system(size: 17))
                                .foregroundColor(Color(white: 0.2))
                        }
                        .padding(.leading, 16)
                    }
                    
                    Spacer()
                
                    NavigationLink(destination: RecentlyDeletedView()) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                    }
                }
                
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
            HStack(alignment: .center, spacing: 10) {
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 26, weight: .bold))
                
                NavigationLink(destination: MonthShareDetailView(
                                    month: month,
                                    records: allRecords.filter {
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
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return MainTabView()
        .modelContainer(container)
        .environmentObject(SpaceManager.shared)
}
