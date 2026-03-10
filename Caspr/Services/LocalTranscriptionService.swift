import Foundation
import WhisperKit
import SwiftUI
import SwiftData

@MainActor
final class LocalTranscriptionService: ObservableObject {
    static let shared = LocalTranscriptionService()

    @Published var isTranscribing = false
    @Published var progress: Double = 0.0 // 0.0 – 1.0
    @Published var progressMessage: String = ""
    @Published var isModelDownloaded = false
    @Published var isDownloadingModel = false
    @Published var downloadProgress: Double = 0.0

    private var whisperKit: WhisperKit?
    private var currentTask: Task<Void, Never>?

    private let modelName = "openai_whisper-base"

    private init() {
        Task { await checkModelStatus() }
    }

    // MARK: - Model Management

    func checkModelStatus() async {
        let modelDir = localModelDirectory()
        isModelDownloaded = FileManager.default.fileExists(atPath: modelDir.path)
    }

    func downloadModel() async throws {
        guard !isDownloadingModel else { return }
        isDownloadingModel = true
        downloadProgress = 0.0
        progressMessage = "Downloading transcription model..."

        defer {
            isDownloadingModel = false
        }

        do {
            let pipe = try await WhisperKit(
                model: modelName,
                verbose: false,
                prewarm: true
            )
            whisperKit = pipe
            isModelDownloaded = true
            downloadProgress = 1.0
            progressMessage = "Model ready"
        } catch {
            progressMessage = "Download failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Transcription

    func transcribe(audioURL: URL) async -> Transcript? {
        guard !isTranscribing else { return nil }
        isTranscribing = true
        progress = 0.0
        progressMessage = "Preparing transcription..."

        defer {
            isTranscribing = false
            progress = 1.0
        }

        do {
            // Ensure WhisperKit is loaded
            if whisperKit == nil {
                progressMessage = "Loading model..."
                progress = 0.1
                let pipe = try await WhisperKit(
                    model: modelName,
                    verbose: false,
                    prewarm: true
                )
                whisperKit = pipe
                isModelDownloaded = true
            }

            guard let pipe = whisperKit else {
                progressMessage = "Model not available"
                return nil
            }

            progress = 0.2
            progressMessage = "Transcribing audio..."

            // Transcribe the audio file
            // Use nonisolated(unsafe) to allow sending @MainActor-isolated pipe
            // to nonisolated WhisperKit.transcribe — safe because we await the result
            nonisolated(unsafe) let localPipe = pipe
            let audioPath = audioURL.path
            let results = try await localPipe.transcribe(
                audioPath: audioPath
            )

            progress = 0.9
            progressMessage = "Processing results..."

            // Convert WhisperKit results to our Transcript model
            var segments: [TranscriptSegment] = []
            var fullText = ""

            for result in results {
                for segment in result.segments {
                    let transcriptSegment = TranscriptSegment(
                        startTime: Double(segment.start),
                        endTime: Double(segment.end),
                        text: segment.text.trimmingCharacters(in: .whitespaces),
                        speaker: nil,
                        confidence: segment.avgLogprob
                    )
                    segments.append(transcriptSegment)
                    fullText += segment.text
                }
            }

            let transcript = Transcript(
                fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                segments: segments,
                source: "local"
            )

            progress = 1.0
            progressMessage = "Transcription complete"
            return transcript

        } catch {
            progressMessage = "Transcription failed: \(error.localizedDescription)"
            print("[Caspr] Transcription error: \(error)")
            return nil
        }
    }

    /// Auto-transcribe a recording and save to SwiftData
    func autoTranscribe(recording: Recording, modelContext: ModelContext) {
        currentTask?.cancel()
        currentTask = Task {
            guard recording.transcript == nil else { return }

            let audioURL = recording.audioFileURL
            let transcript = await self.transcribe(audioURL: audioURL)
            if let transcript {
                transcript.recording = recording
                recording.transcript = transcript
                modelContext.insert(transcript)
                try? modelContext.save()
            }
        }
    }

    func cancelTranscription() {
        currentTask?.cancel()
        currentTask = nil
        isTranscribing = false
        progress = 0.0
        progressMessage = ""
    }

    // MARK: - Helpers

    private func localModelDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Caspr/Models/\(modelName)", isDirectory: true)
    }
}
