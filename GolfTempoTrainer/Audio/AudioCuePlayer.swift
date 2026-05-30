import AVFoundation
import Foundation

final class AudioCuePlayer: NSObject, ObservableObject {
    @Published var isReady = false
    @Published var errorMessage: String?
    @Published var soundStyle: SoundStyle = SoundStyle.saved {
        didSet {
            SoundStyle.saved = soundStyle
            rebuildBuffers()
        }
    }

    var masterVolume: Double = 0.55 {
        didSet { engine.mainMixerNode.outputVolume = Float(masterVolume) }
    }

    private let engine = AVAudioEngine()
    private let takeawayNode = AVAudioPlayerNode()
    private let topNode      = AVAudioPlayerNode()
    private let impactNode   = AVAudioPlayerNode()
    private let previewNode  = AVAudioPlayerNode()

    private let sampleRate: Double = 44100
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

    private var takeawayBuffer: AVAudioPCMBuffer?
    private var topBuffer:      AVAudioPCMBuffer?
    private var impactBuffer:   AVAudioPCMBuffer?

    private var pendingWork: [DispatchWorkItem] = []

    override init() {
        super.init()
        configureSession()
        setupEngine()
        rebuildBuffers()
        startEngine()
    }

    // MARK: - Public API

    func scheduleBeats(takeawayIn t0: Double, topIn t1: Double, impactIn t2: Double) {
        cancelPending()
        schedule(after: t0) { [weak self] in self?.playBack() }
        schedule(after: t1) { [weak self] in self?.playTop()  }
        schedule(after: t2) { [weak self] in self?.playHit()  }
    }

    func stopBeats() {
        cancelPending()
        takeawayNode.stop(); topNode.stop(); impactNode.stop()
        takeawayNode.play(); topNode.play(); impactNode.play()
    }

    func playBack() {
        guard let buf = takeawayBuffer else { return }
        takeawayNode.scheduleBuffer(buf, completionHandler: nil)
    }
    func playTop() {
        guard let buf = topBuffer else { return }
        topNode.scheduleBuffer(buf, completionHandler: nil)
    }
    func playHit() {
        guard let buf = impactBuffer else { return }
        impactNode.scheduleBuffer(buf, completionHandler: nil)
    }

    func previewStyle(_ style: SoundStyle) {
        guard let buf = makeBuffer(freq: pitch(for: style, beat: .impact), style: style) else { return }
        previewNode.scheduleBuffer(buf, completionHandler: nil)
    }

    // MARK: - Setup

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func setupEngine() {
        for node in [takeawayNode, topNode, impactNode, previewNode] {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = Float(masterVolume)
    }

    private func startEngine() {
        do {
            try engine.start()
            takeawayNode.play(); topNode.play(); impactNode.play(); previewNode.play()
            isReady = true
            errorMessage = nil
        } catch {
            errorMessage = "Audio engine failed: \(error.localizedDescription)"
            isReady = false
        }
    }

    // MARK: - Synthesis

    private enum Beat { case takeaway, top, impact }

    private func pitch(for style: SoundStyle, beat: Beat) -> Double {
        let base: Double
        switch style {
        case .metronome: base = 880
        case .beep:      base = 1000
        case .bell:      base = 660
        case .woodblock: base = 520
        }
        switch beat {
        case .takeaway: return base
        case .top:      return base * 1.25   // major third
        case .impact:   return base * 1.5    // perfect fifth — resolves the phrase
        }
    }

    private func rebuildBuffers() {
        takeawayBuffer = makeBuffer(freq: pitch(for: soundStyle, beat: .takeaway), style: soundStyle)
        topBuffer      = makeBuffer(freq: pitch(for: soundStyle, beat: .top),      style: soundStyle)
        impactBuffer   = makeBuffer(freq: pitch(for: soundStyle, beat: .impact),   style: soundStyle)
    }

    private func makeBuffer(freq: Double, style: SoundStyle) -> AVAudioPCMBuffer? {
        let durationSec: Double
        let attack:      Double
        let decay:       Double
        let harmonics:   [(mult: Double, amp: Double)]
        let level:       Double

        switch style {
        case .metronome:
            durationSec = 0.10; attack = 0.001; decay = 0.04
            harmonics = [(1, 1.0), (2, 0.15)]
            level = 0.90
        case .beep:
            durationSec = 0.12; attack = 0.002; decay = 0.08
            harmonics = [(1, 1.0), (3, 0.25), (5, 0.10)]
            level = 0.85
        case .bell:
            durationSec = 0.60; attack = 0.001; decay = 0.30
            harmonics = [(1, 1.0), (2.76, 0.5), (5.40, 0.25), (8.93, 0.12)]
            level = 0.80
        case .woodblock:
            durationSec = 0.14; attack = 0.0005; decay = 0.05
            harmonics = [(1, 1.0), (1.7, 0.6), (2.4, 0.3)]
            level = 0.95
        }

        let frameCount = AVAudioFrameCount(sampleRate * durationSec)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        guard let ch = buf.floatChannelData?[0] else { return nil }

        let norm = harmonics.map { abs($0.amp) }.reduce(0, +)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env: Double = (t < attack) ? (t / attack) : exp(-(t - attack) / decay)
            var s: Double = 0
            for h in harmonics {
                s += sin(2 * .pi * freq * h.mult * t) * h.amp
            }
            ch[i] = Float((s / norm) * env * level)
        }
        return buf
    }

    // MARK: - Scheduling helpers

    private func schedule(after delay: Double, _ block: @escaping () -> Void) {
        let item = DispatchWorkItem(block: block)
        pendingWork.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay), execute: item)
    }

    private func cancelPending() {
        for w in pendingWork { w.cancel() }
        pendingWork.removeAll()
    }
}
