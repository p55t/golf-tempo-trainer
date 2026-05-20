import Foundation
import Combine

@MainActor
final class TempoEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentPhase: SwingPhase = .idle
    @Published var gear: TempoGear = .gear2
    @Published var swingMode: SwingMode = .fullSwing

    private var backTimer: Timer?
    private var hitTimer: Timer?
    private let player: AudioCuePlayer

    enum SwingPhase: Equatable {
        case idle, backswing, downswing

        var label: String {
            switch self {
            case .idle:      return "Ready"
            case .backswing: return "Back"
            case .downswing: return "Hit"
            }
        }
    }

    init(player: AudioCuePlayer) {
        self.player = player
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        beginBackswing()
    }

    func stop() {
        isPlaying = false
        currentPhase = .idle
        cancelTimers()
    }

    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
    }

    // MARK: Private

    private func beginBackswing() {
        guard isPlaying else { return }
        currentPhase = .backswing
        player.playBack()

        let duration = gear.backswingDuration(for: swingMode)
        backTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.beginDownswing() }
        }
    }

    private func beginDownswing() {
        guard isPlaying else { return }
        currentPhase = .downswing
        player.playHit()

        let rest = gear.downswingDuration(for: swingMode) + gear.restDuration(for: swingMode)
        hitTimer = Timer.scheduledTimer(withTimeInterval: rest, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.beginBackswing() }
        }
    }

    private func cancelTimers() {
        backTimer?.invalidate()
        hitTimer?.invalidate()
        backTimer = nil
        hitTimer = nil
    }
}
