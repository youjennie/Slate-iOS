import Foundation
import SwiftData

@Model
final class Space {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var currentMemo: String
    var futureMemo: String
    @Attribute(.externalStorage) var startingPhotoData: Data?
    var isDefault: Bool
    var createdAt: Date
    
    init(
        name: String,
        category: String = "Daily",
        currentMemo: String = "",
        futureMemo: String = "",
        startingPhotoData: Data? = nil,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.currentMemo = currentMemo
        self.futureMemo = futureMemo
        self.startingPhotoData = startingPhotoData
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

extension Space {
    static var defaultSpace: Space {
        Space(name: "Daily", category: "Daily", isDefault: true)
    }
}
