import SwiftUI     // ⭐️ 필수: View, ImageRenderer 등을 사용하기 위함
import SwiftData    // ⭐️ 필수: PhotoRecord 모델 접근을 위함

struct MonthShareDetailView: View {
    let month: Date
    let records: [PhotoRecord]
    let category: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
            VStack {
                // 미리보기 영역 (디자인된 카드를 스크롤로 보여줌)
                ScrollView {
                    MonthSummaryView(month: month, records: records, category: category)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding()
                }
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Share your Slate")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // 왼쪽 닫기 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
                
                // 오른쪽 실제 공유 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let renderedImage = renderCard() {
                        ShareLink(item: renderedImage,
                                  preview: SharePreview("\(month.formatted(.dateTime.month(.wide))) Slate", image: renderedImage)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        
    }
    
    // ⭐️ 뷰를 고화질 이미지로 변환하는 핵심 함수
    @MainActor
    private func renderCard() -> Image? {
        // 실제 렌더링할 타겟 뷰 생성
        let targetView = MonthSummaryView(month: month, records: records, category: category)
            .frame(width: 390) // 인스타그램 스토리 등 모바일 공유에 최적화된 너비
        
        let renderer = ImageRenderer(content: targetView)
        renderer.scale = UIScreen.main.scale // 기기 해상도에 맞춘 고화질 설정
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: - [Preview] 에러 없는 프리뷰 설정
#Preview {
    let schema = Schema([PhotoRecord.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    let today = Date()
    // 프리뷰용 더미 데이터
    let sampleRecords = [
        PhotoRecord(date: today, memo: "Yoga Practice", spaceTag: "Daily")
    ]
    
    return MonthShareDetailView(
        month: today,
        records: sampleRecords,
        category: "Daily"
    )
    .modelContainer(container)
    .environmentObject(SpaceManager.shared)
}
