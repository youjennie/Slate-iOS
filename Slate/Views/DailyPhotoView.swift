import SwiftUI
import SwiftData

struct DailyPhotoView: View {
    let date: Date
    var selectedCategory: String
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // ── isDeleted == false인 레코드만 ──
    @Query(
        filter: #Predicate<PhotoRecord> { $0.isDeleted == false },
        sort: \PhotoRecord.date,
        order: .forward
    ) private var allRecords: [PhotoRecord]
    
    @State private var showImagePicker = false
    @State private var showCustomCamera = false
    @State private var showActionSheet = false
    @State private var selectedImages: [UIImage] = []
    @State private var targetDate: Date = Date()
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    private var allDatesInCalendar: [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let endDate = calendar.date(byAdding: .month, value: 6, to: Date())!
        var dates: [Date] = []
        var current = startDate
        while current <= endDate {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 30) {
                        ForEach(allDatesInCalendar, id: \.self) { day in
                            let recordsForDay = allRecords.filter {
                                Calendar.current.isDate($0.date, inSameDayAs: day) && $0.spaceTag == selectedCategory
                            }
                            
                            daySection(day: day, records: recordsForDay)
                                .id(Calendar.current.startOfDay(for: day))
                        }
                    }
                    .padding(.bottom, 100)
                }
                .onAppear {
                    scrollToToday(proxy: proxy)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Add your moment", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Take a Photo") { showCustomCamera = true }
            Button("Choose from Library") { showImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedImages, detectedDate: targetDate)
                .onDisappear {
                    saveImages()
                }
        }
        .fullScreenCover(isPresented: $showCustomCamera) {
            CameraView()
                .environmentObject(SpaceManager.shared)
        }
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                proxy.scrollTo(today, anchor: .top)
            }
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.black)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("\(selectedCategory) Slate Feed").font(.system(size: 16, weight: .bold))
                Text(currentTime.formatted(date: .complete, time: .omitted)).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
            NavigationLink(destination: RecentlyDeletedView()) {
                Image(systemName: "trash").font(.system(size: 18)).padding(.trailing, 16)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12).background(Color.white)
        .onReceive(timer) { currentTime = $0 }
    }

    private func daySection(day: Date, records: [PhotoRecord]) -> some View {
        let cellSize = (UIScreen.main.bounds.width - 44) / 3
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(day.formatted(.dateTime.month(.wide).day().weekday()))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Calendar.current.isDateInToday(day) ? .green : .primary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(records) { record in
                    if let data = record.imageData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: cellSize, height: cellSize).clipped()
                            // ── Soft Delete: isDeleted = true로 변경 ──
                            Button(action: { softDeleteRecord(record) }) {
                                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(6).background(Color.white.opacity(0.3)).clipShape(Circle())
                            }.padding(6)
                        }
                    }
                }
                Button(action: {
                    targetDate = day
                    showActionSheet = true
                }) {
                    Rectangle().fill(Color.gray.opacity(0.1)).frame(width: cellSize, height: cellSize)
                        .overlay(Image(systemName: "plus").foregroundColor(.gray))
                }
            }
            .padding(.horizontal, 20)
            
            MemoInputField(day: day, records: records, modelContext: modelContext, spaceTag: selectedCategory)
        }
    }
    
    // ── Soft Delete ──
    private func softDeleteRecord(_ record: PhotoRecord) {
        withAnimation {
            record.isDeleted = true
            record.deletedAt = Date()
        }
    }

    private func saveImages() {
        for img in selectedImages {
            if let data = img.jpegData(compressionQuality: 0.7) {
                let newRecord = PhotoRecord(date: targetDate, imageData: data, spaceTag: selectedCategory)
                modelContext.insert(newRecord)
            }
        }
        selectedImages = []
    }
}

// MARK: - [Memo Component]
struct MemoInputField: View {
    let day: Date
    let records: [PhotoRecord]
    let modelContext: ModelContext
    let spaceTag: String
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TextField("Write a short note...", text: $text, onCommit: {
                if let first = records.first {
                    first.memo = text
                } else {
                    modelContext.insert(PhotoRecord(date: day, memo: text, spaceTag: spaceTag))
                }
            })
            .font(.system(size: 14)).padding(12).background(Color.gray.opacity(0.05)).cornerRadius(10).padding(.horizontal, 20)
            
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
                .foregroundColor(Color.gray.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 30)
                .padding(.top, 25)
        }
        .onAppear {
            if let existingMemo = records.first(where: { !$0.memo.isEmpty })?.memo {
                text = existingMemo
            }
        }
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
