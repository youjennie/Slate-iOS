import SwiftUI
import SwiftData

struct MonthShareDetailView: View {
    let month: Date
    let records: [PhotoRecord]
    let category: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더 (시스템 nav bar 대신 — 부모가 bar를 숨겨도 뒤로가기 확실히 동작)
            Text("Share your Slate")
                .font(.slateSans(18, weight: .bold))
                .foregroundColor(SlateColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay(alignment: .leading) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle().fill(SlateColor.sand).frame(width: 42, height: 42)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(SlateColor.ink)
                        }
                    }
                    .padding(.leading, 16)
                }
                .overlay(alignment: .trailing) {
                    if let renderedImage = renderCard() {
                        ShareLink(item: renderedImage,
                                  preview: SharePreview("\(month.formatted(.dateTime.month(.wide))) Slate", image: renderedImage)) {
                            ZStack {
                                Circle().fill(SlateColor.sand).frame(width: 42, height: 42)
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(SlateColor.ink)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                }
                .background(SlateColor.paperSoft)
                .overlay(alignment: .bottom) { Rectangle().fill(SlateColor.ink.opacity(0.08)).frame(height: 1) }

            ScrollView {
                MonthSummaryView(month: month, records: records, category: category)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(SlateColor.ink.opacity(0.08), lineWidth: 1))
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slatePaperBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    @MainActor
    private func renderCard() -> Image? {
        let targetView = MonthSummaryView(month: month, records: records, category: category)
            .frame(width: MonthSummaryView.cardWidth)
        
        let renderer = ImageRenderer(content: targetView)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    let today = Date()
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
