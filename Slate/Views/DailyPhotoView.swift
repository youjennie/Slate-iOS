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

    let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    /// 피드: 선택 카테고리에 기록이 있는 날짜만 (최신순) + 진입한 날짜는 항상 포함
    private var feedDays: [Date] {
        let calendar = Calendar.current
        var days = Set(
            allRecords
                .filter { $0.spaceTag == selectedCategory }
                .map { calendar.startOfDay(for: $0.date) }
        )
        days.insert(calendar.startOfDay(for: date)) // 캘린더에서 탭한 날은 비어도 표시
        return days.sorted(by: >)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        ForEach(feedDays, id: \.self) { day in
                            let recordsForDay = allRecords.filter {
                                Calendar.current.isDate($0.date, inSameDayAs: day) && $0.spaceTag == selectedCategory
                            }
                            daySection(day: day, records: recordsForDay)
                                .id(Calendar.current.startOfDay(for: day))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    scrollToTargetDate(proxy: proxy)
                }
            }
        }
        .slatePaperBackground()
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
            CameraView(selectedCategory: selectedCategory)
                .environmentObject(SpaceManager.shared)
        }
    }

    /// 캘린더에서 클릭한 날짜(date)로 스크롤 — 오늘이 아닌 전달받은 날짜 기준
    private func scrollToTargetDate(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date) // ← 전달받은 날짜로 포커스
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(SlateColor.ink)
            }
            Spacer()
            HStack(spacing: 7) {
                Text(SlateEmoji.forSpace(named: selectedCategory)).font(.system(size: 16))
                Text("\(selectedCategory) Feed").font(.slateSans(17, weight: .bold)).foregroundColor(SlateColor.ink)
            }
            Spacer()
            NavigationLink(destination: RecentlyDeletedView()) {
                Image(systemName: "trash").font(.system(size: 17)).foregroundColor(SlateColor.inkSoft)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14).background(SlateColor.paperSoft)
        .onReceive(timer) { currentTime = $0 }
    }

    private func daySection(day: Date, records: [PhotoRecord]) -> some View {
        let cellSize = (UIScreen.main.bounds.width - 40 - 16) / 3
        let isToday = Calendar.current.isDateInToday(day)

        return VStack(alignment: .leading, spacing: 14) {
            // 날짜 헤더
            HStack(spacing: 8) {
                Text(day.formatted(.dateTime.day()))
                    .font(.slateSans(24, weight: .bold))
                    .foregroundColor(isToday ? SlateColor.leafDeep : SlateColor.ink)
                VStack(alignment: .leading, spacing: 0) {
                    Text(day.formatted(.dateTime.weekday(.wide)))
                        .font(.slateSans(13, weight: .semibold))
                        .foregroundColor(SlateColor.inkSoft)
                    Text(day.formatted(.dateTime.month(.wide)))
                        .font(.slateSans(11))
                        .foregroundColor(SlateColor.inkFaint)
                }
                if isToday {
                    Text("TODAY")
                        .font(.slateSans(9, weight: .bold))
                        .foregroundColor(SlateColor.leafDeep)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(SlateColor.leafSoft))
                }
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(records) { record in
                    if let data = record.imageData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage).resizable().scaledToFill()
                                .frame(width: cellSize, height: cellSize)
                                .clipShape(RoundedRectangle(cornerRadius: SlateRadius.md))
                            Button(action: { softDeleteRecord(record) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                    .padding(6).background(SlateColor.ink.opacity(0.45)).clipShape(Circle())
                            }.padding(6)
                        }
                    }
                }
                Button(action: {
                    targetDate = day
                    showActionSheet = true
                }) {
                    RoundedRectangle(cornerRadius: SlateRadius.md)
                        .fill(SlateColor.paperSoft)
                        .frame(width: cellSize, height: cellSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: SlateRadius.md)
                                .strokeBorder(SlateColor.sandDeep, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        )
                        .overlay(Image(systemName: "plus").font(.system(size: 22)).foregroundColor(SlateColor.inkFaint))
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
        HStack(spacing: 8) {
            Image(systemName: "pencil.line").font(.system(size: 13)).foregroundColor(SlateColor.inkFaint)
            TextField("Write a short note…", text: $text, onCommit: {
                if let first = records.first {
                    first.memo = text
                } else {
                    modelContext.insert(PhotoRecord(date: day, memo: text, spaceTag: spaceTag))
                }
            })
            .font(.slateSans(14))
            .foregroundColor(SlateColor.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: SlateRadius.md).fill(SlateColor.paperSoft))
        .padding(.horizontal, 20)
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
