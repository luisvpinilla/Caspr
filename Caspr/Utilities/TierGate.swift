import SwiftUI

enum ProFeature: String {
    case cloudTranscription = "Cloud Transcription"
    case aiSummaries = "AI Summaries"
    case cloudSync = "Cloud Sync"
    case systemAudioCapture = "System Audio Capture"
    case exportNotion = "Export to Notion"
    case exportPDF = "Export to PDF"

    var description: String {
        switch self {
        case .cloudTranscription:
            "Higher accuracy transcription with speaker labels via Deepgram Nova-2."
        case .aiSummaries:
            "AI-powered meeting summaries with decisions, action items, and follow-ups."
        case .cloudSync:
            "Access your recordings and transcripts from anywhere."
        case .systemAudioCapture:
            "Capture system audio from Zoom, Teams, and Meet."
        case .exportNotion:
            "Export summaries directly to Notion."
        case .exportPDF:
            "Export transcripts and summaries as PDF."
        }
    }
}

@MainActor
enum TierGate {
    static func isAvailable(_ feature: ProFeature) -> Bool {
        let tier = UserProfile.shared.tier
        return tier == .pro || tier == .team
    }

    static func requirePro(_ feature: ProFeature, showPaywall: Binding<Bool>) -> Bool {
        if isAvailable(feature) {
            return true
        }
        showPaywall.wrappedValue = true
        return false
    }
}
