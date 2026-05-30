// Contains LiveSessionView
import SwiftUI

// MARK: - Beat dots

private struct BeatDotsView: View {
    let frame: TempoFrame
    @Environment(\.tc) var colors

    var body: some View {
        let flashing = [
            frame.phase == .back && frame.phaseT < 0.18,
            frame.phase == .down && frame.phaseT < 0.18,
            (frame.phase == .rest && frame.phaseT < 0.18) || (frame.phase == .down && frame.phaseT > 0.94),
        ]
        let dotColors: [Color] = [colors.tone1, colors.tone2, colors.gold]
        let labels = ["takeaway", "top", "impact"]

        HStack(spacing: 30) {
            ForEach(0..<3, id: \.self) { i in
                VStack(spacing: 5) {
                    Circle()
                        .fill(flashing[i] ? dotColors[i] : colors.line)
                        .frame(width: flashing[i] ? 11 : 7, height: flashing[i] ? 11 : 7)
                        .shadow(color: flashing[i] ? dotColors[i].opacity(0.6) : .clear, radius: 5)
                        .animation(.easeOut(duration: 0.18), value: flashing[i])
                    Text(labels[i])
                        .font(.system(size: 8.5, weight: .medium)).tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(flashing[i] ? colors.ink : colors.inkFaint)
                        .animation(.easeOut(duration: 0.2), value: flashing[i])
                }
            }
        }
    }
}

// MARK: - Viz picker

private struct VizPicker: View {
    @Binding var selection: AppStore.VizStyle
    @Environment(\.tc) var colors

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppStore.VizStyle.allCases, id: \.self) { style in
                let active = selection == style
                Button { selection = style } label: {
                    Text(style.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(active ? colors.ink : colors.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(active ? colors.surface : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(colors.bgDeep)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(colors.lineSoft, lineWidth: 1))
        .cornerRadius(10)
    }
}

// MARK: - LiveSessionView

struct LiveSessionView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var engine: TempoEngine
    let onBack: () -> Void
    let onSaveAsNew: () -> Void

    @Environment(\.tc) var colors

    var body: some View {
        GeometryReader { geo in
            let vizSize = min(geo.size.width - 44, 300)

            VStack(spacing: 0) {

                // ── Top bar ── background bleeds into Dynamic Island / status bar area
                topBar
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(colors.bg.ignoresSafeArea(edges: .top))

                Divider().background(colors.lineSoft)

                // ── Main content ── fills remaining space, no scroll
                VStack(spacing: 0) {

                    // Preset label
                    VStack(spacing: 2) {
                        Text("PLAYING")
                            .font(.system(size: 9.5, weight: .medium)).tracking(1.8)
                            .foregroundColor(colors.inkFaint)
                        Text(store.activePreset.name)
                            .font(.custom("Georgia", size: 20))
                            .foregroundColor(colors.ink)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    // Pendulum — scales to screen width
                    PendulumView(
                        style: store.vizStyle,
                        frame: engine.frame,
                        ratio: store.activePreset.ratio,
                        swingMs: store.activePreset.swingMs
                    )
                    .frame(width: vizSize, height: vizSize)

                    // Beat indicators
                    BeatDotsView(frame: engine.frame)
                        .padding(.top, 10)

                    // Ratio readout
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(String(format: "%.1f", store.activePreset.ratio))
                            .font(.system(size: 48, weight: .medium).monospacedDigit())
                            .foregroundColor(colors.ink)
                        Text(":1")
                            .font(.system(size: 18, weight: .medium).monospacedDigit())
                            .foregroundColor(colors.inkFaint)
                            .padding(.bottom, 4)
                    }
                    .padding(.top, 8)

                    Text("\(Int(store.activePreset.backMs.rounded()))ms · \(Int(store.activePreset.downMs.rounded()))ms · \(String(format: "%.2f", store.activePreset.swingMs / 1000))s")
                        .font(.system(size: 11, weight: .medium).monospacedDigit()).tracking(0.6)
                        .foregroundColor(colors.inkFaint)
                        .padding(.top, 2)

                    Spacer(minLength: 8)

                    // Sliders
                    VStack(spacing: 12) {
                        tempoSlider(
                            label: "RATIO",
                            value: Binding(
                                get: { store.activePreset.ratio },
                                set: { store.updatePreset(store.activePreset.id, ratio: $0) }
                            ),
                            in: 2.0...4.0, step: 0.1,
                            display: String(format: "%.1f:1", store.activePreset.ratio)
                        )
                        tempoSlider(
                            label: "SWING DURATION",
                            value: Binding(
                                get: { store.activePreset.swingMs },
                                set: { store.updatePreset(store.activePreset.id, swingMs: $0) }
                            ),
                            in: 700...1600, step: 25,
                            display: String(format: "%.2fs", store.activePreset.swingMs / 1000)
                        )
                    }
                    .padding(.horizontal, 22)

                    // Save + viz picker
                    HStack(spacing: 10) {
                        Button(action: onSaveAsNew) {
                            Text("+ Save as new")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colors.inkSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .overlay(RoundedRectangle(cornerRadius: 999).stroke(colors.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        VizPicker(selection: $store.vizStyle)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)
                }
                .frame(maxHeight: .infinity)

                // ── Transport bar ── background bleeds into home indicator area
                transportBar
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Presets")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(colors.inkSoft)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 7) {
                Circle()
                    .fill(engine.isRunning ? colors.gold : colors.inkMute)
                    .frame(width: 6, height: 6)
                    .shadow(color: engine.isRunning ? colors.gold.opacity(0.6) : .clear, radius: 4)
                    .animation(.easeInOut(duration: 0.2), value: engine.isRunning)
                Text(engine.isRunning
                     ? String(format: "SWING %02d", engine.frame.swingCount + 1)
                     : "READY")
                    .font(.system(size: 11, weight: .medium).monospacedDigit()).tracking(0.8)
                    .foregroundColor(colors.inkSoft)
            }

            Spacer()

            Button { store.soundOn.toggle() } label: {
                Image(systemName: store.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 15))
                    .foregroundColor(store.soundOn ? colors.ink : colors.inkMute)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Slider

    private func tempoSlider(label: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double, display: String) -> some View {
        VStack(spacing: 5) {
            HStack(alignment: .lastTextBaseline) {
                Text(label)
                    .font(.system(size: 10, weight: .medium)).tracking(1.8)
                    .foregroundColor(colors.inkFaint)
                Spacer()
                Text(display)
                    .font(.system(size: 16, weight: .medium).monospacedDigit())
                    .foregroundColor(colors.ink)
            }
            Slider(value: value, in: range, step: step)
                .tint(colors.ink)
                .onChange(of: value.wrappedValue) { _ in engine.applyPreset(store.activePreset) }
        }
    }

    // MARK: Transport

    private var transportBar: some View {
        VStack(spacing: 0) {
            Divider().background(colors.lineSoft)
            Button {
                if engine.isRunning { engine.stop() } else { engine.start() }
            } label: {
                ZStack {
                    Circle()
                        .fill(engine.isRunning ? colors.surface : colors.ink)
                        .overlay(Circle().stroke(engine.isRunning ? colors.line : Color.clear, lineWidth: 1))
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: engine.isRunning ? 17 : 19))
                        .foregroundColor(engine.isRunning ? colors.ink : colors.bg)
                        .offset(x: engine.isRunning ? 0 : 2)
                }
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: engine.isRunning)
            .padding(.vertical, 14)
        }
        // Bleed theme color into home indicator area — no bare black strip
        .background(colors.bg.ignoresSafeArea(edges: .bottom))
    }
}
