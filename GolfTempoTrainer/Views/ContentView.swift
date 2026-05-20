import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayer = AudioCuePlayer()
    @StateObject private var engine: TempoEngine

    init() {
        let player = AudioCuePlayer()
        _audioPlayer = StateObject(wrappedValue: player)
        _engine      = StateObject(wrappedValue: TempoEngine(player: player))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    swingModePicker
                    gearPicker
                    soundStylePicker
                    timingDisplay
                    beatIndicator
                    actionArea
                    backgroundNote
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
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
                .font(.system(size: 24, weight: .bold))
            Text("3:1 Ratio · Tour Tempo method")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.top, 8)
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
            HStack(spacing: 8) {
                ForEach(TempoGear.allCases) { gear in
                    GearButton(gear: gear, isSelected: engine.gear == gear) {
                        engine.gear = gear
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var soundStylePicker: some View {
        SoundStylePicker(audioPlayer: audioPlayer)
    }

    private var timingDisplay: some View {
        HStack(spacing: 0) {
            timingStat(
                value: String(format: "%.2fs", engine.gear.backswingDuration(for: engine.swingMode)),
                label: "Back"
            )
            Divider().frame(height: 40)
            timingStat(value: "3 : 1", label: "Ratio")
            Divider().frame(height: 40)
            timingStat(
                value: String(format: "%.2fs", engine.gear.downswingDuration(for: engine.swingMode)),
                label: "Hit"
            )
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private var beatIndicator: some View {
        BeatIndicatorView(phase: engine.currentPhase)
            .frame(height: 140)
    }

    private var actionArea: some View {
        VStack(spacing: 8) {
            if let err = audioPlayer.errorMessage {
                Text(err).font(.caption).foregroundColor(.red)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }

            Button(engine.isPlaying ? "Stop" : "Start Training") {
                engine.isPlaying ? engine.stop() : engine.start()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(engine.isPlaying ? .red : .green)
            .font(.title3.bold())
            .disabled(!audioPlayer.isReady)
        }
    }

    private var backgroundNote: some View {
        Label("Audio continues with screen off", systemImage: "lock.iphone")
            .font(.caption2).foregroundColor(.secondary)
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            .padding(.horizontal)
    }

    private func timingStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
