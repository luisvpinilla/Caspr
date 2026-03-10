import AVFoundation
import Combine
import SwiftUI

@MainActor
final class AudioCaptureService: ObservableObject {
    static let shared = AudioCaptureService()

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var audioLevel: CGFloat = 0.0
    @Published var duration: TimeInterval = 0
    @Published var currentRecordingURL: URL?

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStart: Date?
    private var cafURL: URL?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private init() {}

    // MARK: - Recording Directory

    private var recordingsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Caspr/Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording Controls

    func start() {
        Task {
            let granted = await requestPermission()
            guard granted else {
                print("[Caspr] Microphone permission denied")
                return
            }
            startRecording()
        }
    }

    func stop() {
        stopRecording()
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        pauseStart = Date()
        audioEngine?.pause()
        timer?.invalidate()
    }

    func resume() {
        guard isRecording, isPaused else { return }
        if let pauseStart {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        isPaused = false
        pauseStart = nil
        try? audioEngine?.start()
        startTimer()
    }

    // MARK: - Private

    private func startRecording() {
        currentRecordingURL = nil

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Create CAF file for lossless capture
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "caspr_\(dateFormatter.string(from: Date())).caf"
        let cafURL = recordingsDirectory.appendingPathComponent(filename)
        self.cafURL = cafURL

        do {
            let audioFile = try AVAudioFile(
                forWriting: cafURL,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
            self.audioFile = audioFile

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                // Write audio data
                try? audioFile.write(from: buffer)

                // Calculate RMS level
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                var rms: Float = 0
                for i in 0..<frameLength {
                    rms += channelData[i] * channelData[i]
                }
                rms = sqrtf(rms / Float(frameLength))
                let level = min(CGFloat(rms * 3), 1.0) // Scale for visibility

                Task { @MainActor [weak self] in
                    self?.audioLevel = level
                }
            }

            try engine.start()
            self.audioEngine = engine
            self.isRecording = true
            self.isPaused = false
            self.startTime = Date()
            self.pausedDuration = 0
            self.duration = 0
            startTimer()

        } catch {
            print("[Caspr] Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isRecording = false
        isPaused = false
        audioLevel = 0

        // Convert CAF to M4A
        if let cafURL {
            Task {
                let m4aURL = await convertToM4A(cafURL: cafURL)
                self.currentRecordingURL = m4aURL
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let startTime = self.startTime else { return }
                self.duration = Date().timeIntervalSince(startTime) - self.pausedDuration
            }
        }
    }

    private func convertToM4A(cafURL: URL) async -> URL? {
        let m4aFilename = cafURL.deletingPathExtension().lastPathComponent + ".m4a"
        let m4aURL = recordingsDirectory.appendingPathComponent(m4aFilename)

        let asset = AVURLAsset(url: cafURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            print("[Caspr] Could not create export session")
            return cafURL
        }

        exportSession.outputFileType = .m4a
        exportSession.outputURL = m4aURL

        await exportSession.export()

        if exportSession.status == .completed {
            try? FileManager.default.removeItem(at: cafURL)
            return m4aURL
        } else {
            print("[Caspr] M4A conversion failed: \(exportSession.error?.localizedDescription ?? "unknown")")
            return cafURL
        }
    }
}
