import Foundation
import QuartzCore

struct TempoFrame: Equatable {
    var phase: TempoPhase = .idle
    var phaseT: Double = 0
    var cycleT: Double = 0
    var swingCount: Int = 0
}

enum TempoPhase: String, Equatable {
    case idle, back, down, rest
}

@MainActor
final class TempoEngine: ObservableObject {
    @Published private(set) var frame = TempoFrame()
    @Published private(set) var isRunning = false

    var ratio: Double = 3.0
    var swingMs: Double = 1000
    var restMs: Double = 2200
    var soundOn: Bool = true
    var volume: Double = 0.55 { didSet { audioPlayer.masterVolume = volume } }

    private let audioPlayer: AudioCuePlayer
    private var displayTimer: Timer?
    private var cycleStart: CFTimeInterval = 0
    private var lastScheduledCycle = -1
    private var swingCount = 0

    init(audioPlayer: AudioCuePlayer) {
        self.audioPlayer = audioPlayer
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        cycleStart = CACurrentMediaTime()
        lastScheduledCycle = 0
        swingCount = 0
        scheduleAudio(offsetFromNow: 0.06)
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        displayTimer = t
    }

    func stop() {
        isRunning = false
        displayTimer?.invalidate()
        displayTimer = nil
        audioPlayer.stopBeats()
        frame = TempoFrame()
    }

    func applyPreset(_ preset: TempoPreset) {
        ratio = preset.ratio
        swingMs = preset.swingMs
    }

    // MARK: Private

    private var backSecs: Double { swingMs * ratio / (ratio + 1) / 1000 }
    private var downSecs: Double { swingMs / (ratio + 1) / 1000 }
    private var cycleSecs: Double { (swingMs + restMs) / 1000 }

    // Called from MainActor — uses play(atTime:) for hardware-clock accuracy.
    // No GCD/DispatchWorkItem; the audio framework schedules at exact device times.
    private func scheduleAudio(offsetFromNow t0: Double) {
        guard soundOn else { return }
        audioPlayer.scheduleBeats(
            takeawayIn: t0,
            topIn:      t0 + backSecs,
            impactIn:   t0 + backSecs + downSecs
        )
    }

    private func tick() {
        guard isRunning else { return }
        let now = CACurrentMediaTime()
        let cycle = cycleSecs
        let elapsed = now - cycleStart
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        let back = backSecs, down = downSecs

        let phase: TempoPhase
        let phaseT: Double
        if t < back {
            phase = .back;  phaseT = t / back
        } else if t < back + down {
            phase = .down;  phaseT = (t - back) / down
        } else {
            phase = .rest;  phaseT = min(1, (t - back - down) / (restMs / 1000))
        }

        let cycleIdx = Int(elapsed / cycle)
        if cycleIdx != lastScheduledCycle {
            if cycleIdx > 0 { swingCount += 1 }
            lastScheduledCycle = cycleIdx
            let boundary = cycleStart + Double(cycleIdx) * cycle
            let offset = max(0.02, boundary - now)
            scheduleAudio(offsetFromNow: offset)
        }

        frame = TempoFrame(
            phase: phase,
            phaseT: max(0, min(1, phaseT)),
            cycleT: t / cycle,
            swingCount: swingCount
        )
    }
}
