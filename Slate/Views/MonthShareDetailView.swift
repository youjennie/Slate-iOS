import SwiftUI
import SwiftData

struct MonthShareDetailView: View {
    let month: Date
    let records: [PhotoRecord]
    let category: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
            VStack {
                ScrollView {
                    MonthSummaryView(month: month, records: records, category: category)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding()
                }
            }
            .background(SlateColor.paper)
            .navigationTitle("Share your Slate")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(SlateColor.ink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let renderedImage = renderCard() {
                        ShareLink(item: renderedImage,
                                  preview: SharePreview("\(month.formatted(.dateTime.month(.wide))) Slate", image: renderedImage)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(SlateColor.ink)
                        }
                    }
                }
            }
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
