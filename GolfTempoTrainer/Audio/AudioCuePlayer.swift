import AVFoundation
import Foundation

final class AudioCuePlayer: ObservableObject {
    @Published var isReady      = false
    @Published var isLoading    = false
    @Published var errorMessage: String?
    @Published var soundStyle: SoundStyle = SoundStyle.saved {
        didSet {
            SoundStyle.saved = soundStyle
            loadStyle(soundStyle)
        }
    }

    private var backPlayer: AVAudioPlayer?
    private var hitPlayer:  AVAudioPlayer?

    init() {
        loadStyle(soundStyle)
    }

    // MARK: Public

    func playBack() {
        backPlayer?.currentTime = 0
        backPlayer?.play()
    }

    func playHit() {
        hitPlayer?.currentTime = 0
        hitPlayer?.play()
    }

    func previewStyle(_ style: SoundStyle) {
        guard let backURL = bundleURL(for: style.backFilename),
              let player = try? AVAudioPlayer(contentsOf: backURL) else { return }
        player.prepareToPlay()
        player.play()
        // Hold reference temporarily
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { _ = player }
    }

    // MARK: Private

    private func loadStyle(_ style: SoundStyle) {
        isReady = false
        errorMessage = nil

        guard let backURL = bundleURL(for: style.backFilename),
              let hitURL  = bundleURL(for: style.hitFilename) else {
            errorMessage = "Audio files for \(style.label) not found in bundle."
            return
        }

        do {
            backPlayer = try AVAudioPlayer(contentsOf: backURL)
            hitPlayer  = try AVAudioPlayer(contentsOf: hitURL)
            backPlayer?.prepareToPlay()
            hitPlayer?.prepareToPlay()
            isReady = true
        } catch {
            errorMessage = "Failed to load \(style.label): \(error.localizedDescription)"
        }
    }

    private func bundleURL(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp3")
    }
}
