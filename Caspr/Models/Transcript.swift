import Foundation
import SwiftData

struct TranscriptSegment: Codable, Hashable {
    var startTime: Double
    var endTime: Double
    var text: String
    var speaker: String?
    var confidence: Float
}

@Model
final class Transcript {
    var id: UUID
    var createdAt: Date
    var fullText: String
    var segments: [TranscriptSegment]
    var source: String

    var recording: Recording?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        fullText: String = "",
        segments: [TranscriptSegment] = [],
        source: String = "local"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.fullText = fullText
        self.segments = segments
        self.source = source
    }
}
