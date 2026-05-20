import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayer = AudioCuePlayer()
    @StateObject private var engine: TempoEngine

    // ElevenLabs API key — update via Settings if needed
    private let elevenLabsKey = "sk_63561bf1a65c71b60aadc56c28ec33fa5d814fb50092166d"

    init() {
        let player = AudioCuePlayer()
        _audioPlayer = StateObject(wrappedValue: player)
        _engine      = StateObject(wrappedValue: TempoEngine(player: player))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                headerView
                swingModePicker
                gearPicker
                timingDisplay
                beatIndicator
                Spacer()
                actionArea
                backgroundNote
            }
            .padding(.top, 8)
            .navigationTitle("Golf Tempo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: engine.swingMode) { _ in if engine.isPlaying { engine.restart() } }
        .onChange(of: engine.gear)      { _ in if engine.isPlaying { engine.restart() } }
    }

    // MARK: Sub-views

    private var headerView: some View {
        VStack(spacing: 2) {
            Text("⛳️ Golf Tempo Trainer")
                .font(.system(size: 26, weight: .bold))
            Text("3:1 Ratio · Based on Tour Tempo research")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
    }

    private var swingModePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("SWING TYPE")
            Picker("Swing Mode", selection: $engine.swingMode) {
                ForEach(SwingMode.allCases) { Text($0.description).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    private var gearPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("TEMPO GEAR")
            HStack(spacing: 10) {
                ForEach(TempoGear.allCases) { gear in
                    GearButton(gear: gear, isSelected: engine.gear == gear) {
                        engine.gear = gear
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var timingDisplay: some View {
        HStack(spacing: 20) {
            timingStat(
                value: String(format: "%.2fs", engine.gear.backswingDuration(for: engine.swingMode)),
                label: "Back"
            )
            Divider().frame(height: 36)
            timingStat(value: "3 : 1", label: "Ratio")
            Divider().frame(height: 36)
            timingStat(
                value: String(format: "%.2fs", engine.gear.downswingDuration(for: engine.swingMode)),
                label: "Hit"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private var beatIndicator: some View {
        BeatIndicatorView(phase: engine.currentPhase)
            .frame(height: 140)
    }

    private var actionArea: some View {
        Group {
            if audioPlayer.isLoading {
                ProgressView("Generating audio cues…")
                    .padding()
            } else if !audioPlayer.isReady {
                VStack(spacing: 8) {
                    Button("Prepare Audio Cues") {
                        Task { await audioPlayer.generateFromElevenLabs(apiKey: elevenLabsKey) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Text("Generates voice cues via ElevenLabs (one-time)")
                        .font(.caption).foregroundColor(.secondary)
                }
            } else {
                Button(engine.isPlaying ? "Stop" : "Start Training") {
                    engine.isPlaying ? engine.stop() : engine.start()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(engine.isPlaying ? .red : .green)
                .font(.title3.bold())
            }

            if let err = audioPlayer.errorMessage {
                Text(err).font(.caption).foregroundColor(.red)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
        }
    }

    private var backgroundNote: some View {
        Label("Audio continues with screen off", systemImage: "lock.iphone")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
    }

    private func timingStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
