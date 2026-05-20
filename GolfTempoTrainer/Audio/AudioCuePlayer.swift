import AVFoundation
import Foundation

final class AudioCuePlayer: ObservableObject {
    @Published var isReady  = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var backPlayer: AVAudioPlayer?
    private var hitPlayer:  AVAudioPlayer?

    init() {
        // Try bundled assets first, fall back to cache
        if let backURL = Bundle.main.url(forResource: "back", withExtension: "mp3"),
           let hitURL  = Bundle.main.url(forResource: "hit",  withExtension: "mp3") {
            loadPlayers(backURL: backURL, hitURL: hitURL)
        } else {
            loadFromCache()
        }
    }

    // MARK: Public

    func generateFromElevenLabs(apiKey: String) async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            async let backData = ElevenLabsService.generateSpeech(text: "back", apiKey: apiKey)
            async let hitData  = ElevenLabsService.generateSpeech(text: "hit",  apiKey: apiKey)

            let (back, hit) = try await (backData, hitData)

            let backURL = cacheURL(for: "back")
            let hitURL  = cacheURL(for: "hit")
            try back.write(to: backURL)
            try hit.write(to: hitURL)

            await MainActor.run {
                self.loadPlayers(backURL: backURL, hitURL: hitURL)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func playBack() {
        backPlayer?.currentTime = 0
        backPlayer?.play()
    }

    func playHit() {
        hitPlayer?.currentTime = 0
        hitPlayer?.play()
    }

    // MARK: Private

    private func loadFromCache() {
        let backURL = cacheURL(for: "back")
        let hitURL  = cacheURL(for: "hit")
        guard FileManager.default.fileExists(atPath: backURL.path),
              FileManager.default.fileExists(atPath: hitURL.path) else { return }
        loadPlayers(backURL: backURL, hitURL: hitURL)
    }

    private func loadPlayers(backURL: URL, hitURL: URL) {
        do {
            backPlayer = try AVAudioPlayer(contentsOf: backURL)
            hitPlayer  = try AVAudioPlayer(contentsOf: hitURL)
            backPlayer?.prepareToPlay()
            hitPlayer?.prepareToPlay()
            isReady = true
        } catch {
            errorMessage = "Audio load failed: \(error.localizedDescription)"
        }
    }

    private func cacheURL(for name: String) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("golf_cue_\(name).mp3")
    }
}
