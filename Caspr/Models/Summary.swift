import Foundation
import SwiftData

struct ActionItem: Codable, Hashable {
    var text: String
    var owner: String?
    var dueDate: String?
}

@Model
final class Summary {
    var id: UUID
    var createdAt: Date
    var overview: String
    var decisions: [String]
    var actionItems: [ActionItem]
    var followUps: [String]
    var parkingLot: [String]

    var recording: Recording?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        overview: String = "",
        decisions: [String] = [],
        actionItems: [ActionItem] = [],
        followUps: [String] = [],
        parkingLot: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.overview = overview
        self.decisions = decisions
        self.actionItems = actionItems
        self.followUps = followUps
        self.parkingLot = parkingLot
    }
}
