import Foundation
import SwiftData

@Model
final class Recording {
    var id: UUID
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var audioFileURL: URL
    var isCloudSynced: Bool

    @Relationship(deleteRule: .cascade, inverse: \Transcript.recording)
    var transcript: Transcript?

    @Relationship(deleteRule: .cascade, inverse: \Summary.recording)
    var summary: Summary?

    init(
        id: UUID = UUID(),
        title: String? = nil,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        audioFileURL: URL,
        isCloudSynced: Bool = false
    ) {
        self.id = id
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        self.title = title ?? "Recording — \(formatter.string(from: createdAt))"
        self.createdAt = createdAt
        self.duration = duration
        self.audioFileURL = audioFileURL
        self.isCloudSynced = isCloudSynced
    }
}
