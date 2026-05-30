// Renamed: contains HomeView
import SwiftUI

struct HomeView: View {
    @ObservedObject var store: AppStore
    let onStart: () -> Void
    let onEditPreset: (String) -> Void
    let onAddPreset: () -> Void

    @Environment(\.tc) var colors

    private var today: String {
        let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        return days[Calendar.current.component(.weekday, from: Date()) - 1].uppercased()
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header pinned at top — bleeds into Dynamic Island / status bar
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colors.bg.ignoresSafeArea(edges: .top))

                Divider().background(colors.lineSoft)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        heroCard
                        startButton
                        presetsSection
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                    .frame(minWidth: geo.size.width, alignment: .top)
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(today)
                .font(.system(size: 10, weight: .medium)).tracking(1.8)
                .foregroundColor(colors.inkFaint)
            Text("Find your tempo.")
                .font(.custom("Georgia", size: 28))
                .foregroundColor(colors.ink)
        }
    }

    // MARK: Hero card

    private var heroCard: some View {
        let preset = store.activePreset
        return ZStack(alignment: .topTrailing) {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.86, green: 0.70, blue: 0.35).opacity(0.3), .clear],
                    center: .center, startRadius: 0, endRadius: 70))
                .frame(width: 140, height: 140)
                .offset(x: 16, y: -16)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SELECTED")
                        .font(.system(size: 10, weight: .medium)).tracking(1.8)
                        .foregroundColor(colors.inkFaint)
                    Spacer()
                    Text(preset.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(colors.inkSoft)
                }

                HStack(alignment: .bottom, spacing: 6) {
                    Text(String(format: "%.1f", preset.ratio))
                        .font(.system(size: 72, weight: .medium).monospacedDigit())
                        .foregroundColor(colors.ink)
                        .lineLimit(1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(":1")
                            .font(.system(size: 18, weight: .medium).monospacedDigit())
                            .foregroundColor(colors.inkSoft)
                        Text("RATIO")
                            .font(.system(size: 8.5, weight: .medium)).tracking(1.4)
                            .foregroundColor(colors.inkFaint)
                    }
                    .padding(.bottom, 10)
                }

                Divider().background(colors.lineSoft)

                HStack(spacing: 0) {
                    statCell(label: "TOTAL", value: String(format: "%.2f", preset.swingMs / 1000), unit: "s")
                    statCell(label: "BACK",  value: "\(Int(preset.backMs.rounded()))", unit: "ms")
                    statCell(label: "DOWN",  value: "\(Int(preset.downMs.rounded()))", unit: "ms")
                }
            }
            .padding(16)
        }
        .background(colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(colors.lineSoft, lineWidth: 1))
        .cornerRadius(18)
        .clipped()
    }

    private func statCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8.5, weight: .medium)).tracking(1.4)
                .foregroundColor(colors.inkFaint)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundColor(colors.ink)
                Text(unit)
                    .font(.system(size: 9.5))
                    .foregroundColor(colors.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Start button

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Text("Begin session")
                    .font(.system(size: 15, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(colors.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(colors.ink)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Presets list

    private var presetsSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("PRESETS")
                    .font(.system(size: 10, weight: .medium)).tracking(1.8)
                    .foregroundColor(colors.inkFaint)
                Spacer()
                Button(action: onAddPreset) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
                        Text("Add").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(colors.inkSoft)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(store.presets) { preset in
                    presetRow(preset)
                    if preset.id != store.presets.last?.id {
                        Divider().background(colors.lineSoft)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 2)
            .background(colors.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.lineSoft, lineWidth: 1))
            .cornerRadius(16)
        }
    }

    private func presetRow(_ preset: TempoPreset) -> some View {
        let active = preset.id == store.activePresetId
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(active ? colors.ink : colors.bgDeep)
                    .overlay(Circle().stroke(active ? Color.clear : colors.line, lineWidth: 1))
                Text(String(preset.name.prefix(1)).uppercased())
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(active ? colors.bg : colors.inkSoft)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(colors.ink)
                    if active {
                        Text("ACTIVE")
                            .font(.system(size: 7.5, weight: .medium)).tracking(0.8)
                            .foregroundColor(colors.inkSoft)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(colors.bgDeep)
                            .cornerRadius(3)
                    }
                }
                Text(String(format: "%.1f:1 · %.2fs", preset.ratio, preset.swingMs / 1000))
                    .font(.system(size: 10.5).monospacedDigit())
                    .foregroundColor(colors.inkFaint)
            }
            Spacer()
            Button { onEditPreset(preset.id) } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colors.inkFaint)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { store.activePresetId = preset.id }
    }
}
