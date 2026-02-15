import SwiftUI
import SwiftData

struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // ── soft-deleted 레코드만 필터링 ──
    @Query(
        filter: #Predicate<PhotoRecord> { $0.isDeleted == true },
        sort: \PhotoRecord.date,
        order: .reverse
    ) private var deletedRecords: [PhotoRecord]
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // 날짜별 그룹화 로직
    private var groupedRecords: [(Date, [PhotoRecord])] {
        let grouping = Dictionary(grouping: deletedRecords) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        return grouping.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // (A) 상단 헤더
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Recently Deleted")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // 전체 영구 삭제 버튼
                Button(action: { permanentlyDeleteAll() }) {
                    Text("Empty")
                        .font(.system(size: 17))
                        .foregroundColor(.red)
                }
                .disabled(deletedRecords.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // (B) 삭제된 사진 그리드
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 30) {
                    if deletedRecords.isEmpty {
                        VStack(spacing: 16) {
                            Spacer(minLength: 200)
                            Image(systemName: "trash.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No recently deleted photos.")
                                .foregroundColor(.secondary)
                            Text("Deleted photos will appear here for 30 days.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // ── 30일 안내 ──
                        Text("Photos will be permanently deleted after 30 days.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        ForEach(groupedRecords, id: \.0) { date, records in
                            VStack(alignment: .leading, spacing: 12) {
                                // ── 날짜 + 남은 일수 표시 ──
                                HStack {
                                    Text(date.formatted(.dateTime.month(.wide).day()))
                                        .font(.system(size: 18, weight: .bold))
                                    Spacer()
                                    if let firstRecord = records.first, let deletedAt = firstRecord.deletedAt {
                                        let daysLeft = max(0, 30 - Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day!)
                                        Text("\(daysLeft) days left")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(records) { record in
                                        if let data = record.imageData, let uiImage = UIImage(data: data) {
                                            ZStack(alignment: .bottom) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: (UIScreen.main.bounds.width - 52) / 3, height: (UIScreen.main.bounds.width - 52) / 3)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .opacity(0.7) // 삭제된 사진 시각적 구분
                                                
                                                // 복구 & 삭제 제어 바
                                                HStack(spacing: 0) {
                                                    // 복구 버튼
                                                    Button(action: { restoreRecord(record) }) {
                                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.green)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    
                                                    // 영구 삭제 버튼
                                                    Button(action: {
                                                        withAnimation { modelContext.delete(record) }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                }
                                                .padding(.bottom, 8)
                                                .background(
                                                    LinearGradient(colors: [.clear, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                                        .cornerRadius(12)
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }
    
    // ── 복구: isDeleted → false ──
    private func restoreRecord(_ record: PhotoRecord) {
        withAnimation {
            record.isDeleted = false
            record.deletedAt = nil
        }
    }
    
    // ── 전체 영구 삭제 ──
    private func permanentlyDeleteAll() {
        for record in deletedRecords {
            modelContext.delete(record)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PhotoRecord.self, Space.self, configurations: config)
    return RecentlyDeletedView()
        .modelContainer(container)
}
