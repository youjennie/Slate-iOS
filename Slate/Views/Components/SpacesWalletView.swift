import SwiftUI
import SwiftData

/// 지갑처럼 카드가 겹겹이 쌓여, 탭하면 그 Space가 앞으로 당겨지고 선택되는 메뉴.
struct SpacesWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Space.createdAt) private var spaces: [Space]
    @Query(filter: #Predicate<PhotoRecord> { $0.isDeleted == false })
    private var records: [PhotoRecord]

    @Binding var selectedCategory: String
    var onCreateNew: () -> Void = {}

    @State private var liftedIndex: Int? = nil

    private let cardHeight: CGFloat = 108
    private let peek: CGFloat = 76

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                ZStack(alignment: .top) {
                    ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
                        walletCard(space: space, index: index)
                            .offset(y: peek * CGFloat(index))
                            .scaleEffect(liftedIndex == index ? 1.03 : 1.0, anchor: .top)
                            .zIndex(liftedIndex == index ? 100 : Double(index))
                            .onTapGesture { selectSpace(space) }
                    }
                }
                .frame(height: stackHeight, alignment: .top)
                .padding(.horizontal, 22)
                .padding(.top, 6)

                newSpaceButton
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
            }
        }
        .background(SlateColor.paper.ignoresSafeArea())
    }

    // MARK: - Pieces
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Your Spaces")
                    .font(.slateSans(26, weight: .bold))
                    .foregroundColor(SlateColor.ink)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SlateColor.inkSoft)
                        .padding(10)
                        .background(Circle().fill(SlateColor.paperSoft))
                }
            }
            Text("Tap a card to pull it out")
                .font(.slateSans(13))
                .foregroundColor(SlateColor.inkSoft)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var stackHeight: CGFloat {
        guard !spaces.isEmpty else { return cardHeight }
        return peek * CGFloat(spaces.count - 1) + cardHeight + 10
    }

    private func walletCard(space: Space, index: Int) -> some View {
        let color = SlateColor.forSpace(index)
        let onColor = SlateColor.onAccentText(for: color)
        let count = records.filter { $0.spaceTag == space.name }.count
        let isActive = selectedCategory == space.name

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(SlateEmoji.forSpace(named: space.name))
                    .font(.system(size: 26))
                Text(space.name)
                    .font(.slateSans(18, weight: .bold))
                    .foregroundColor(onColor)
                Text("\(count) \(count == 1 ? "moment" : "moments")")
                    .font(.slateSans(12))
                    .foregroundColor(onColor.opacity(0.8))
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(onColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight, alignment: .top)
        .background(RoundedRectangle(cornerRadius: SlateRadius.lg).fill(color))
        .shadow(color: SlateColor.ink.opacity(0.12), radius: 8, x: 0, y: 6)
    }

    private var newSpaceButton: some View {
        Button(action: { dismiss(); onCreateNew() }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("New Space").font(.slateSans(15, weight: .bold))
            }
            .foregroundColor(SlateColor.inkSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: SlateRadius.lg)
                    .strokeBorder(SlateColor.sandDeep, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
    }

    private func selectSpace(_ space: Space) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            liftedIndex = spaces.firstIndex(where: { $0.id == space.id })
        }
        selectedCategory = space.name
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            dismiss()
        }
    }
}

#Preview {
    let schema = Schema([PhotoRecord.self, Space.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    container.mainContext.insert(Space(name: "Daily", category: "Daily", isDefault: true))
    container.mainContext.insert(Space(name: "Workout", category: "Workout"))
    container.mainContext.insert(Space(name: "Reading", category: "Reading"))
    return SpacesWalletView(selectedCategory: .constant("Daily"))
        .modelContainer(container)
}
