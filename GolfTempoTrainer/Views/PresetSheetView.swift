import SwiftUI

struct PresetSheetView: View {
    let state: SheetState
    @ObservedObject var store: AppStore
    let onClose: () -> Void

    @State private var name: String = ""
    @State private var ratio: Double = 3.0
    @State private var swingMs: Double = 1000

    @Environment(\.tc) var colors
    @FocusState private var nameFocused: Bool

    private var isEdit: Bool {
        if case .edit = state { return true }
        return false
    }

    private var editId: String? {
        if case .edit(let id) = state { return id }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrim
            colors.ink.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // Sheet
            VStack(alignment: .leading, spacing: 16) {
                sheetHandle

                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEdit ? "EDIT PRESET" : "NEW PRESET")
                        .font(.system(size: 10.5, weight: .medium)).tracking(1.8)
                        .foregroundColor(colors.inkFaint)
                    Text(isEdit ? "Refine the rhythm." : "Name a rhythm.")
                        .font(.custom("Georgia", size: 26))
                        .foregroundColor(colors.ink)
                }

                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(.system(size: 10.5, weight: .medium)).tracking(1.8)
                        .foregroundColor(colors.inkFaint)
                    TextField("e.g. 7-iron, Wedge, Driver", text: $name)
                        .font(.system(size: 16))
                        .foregroundColor(colors.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(colors.bgDeep)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(nameFocused ? colors.ink : colors.line, lineWidth: 1))
                        .cornerRadius(12)
                        .focused($nameFocused)
                        .onChange(of: name) { name = String($0.prefix(24)) }
                }

                // Ratio slider
                sliderRow(
                    label: "RATIO",
                    displayValue: String(format: "%.1f:1", ratio),
                    value: $ratio, in: 2.0...4.0, step: 0.1
                )

                // Swing duration slider
                sliderRow(
                    label: "SWING DURATION",
                    displayValue: String(format: "%.2fs", swingMs / 1000),
                    value: $swingMs, in: 700...1600, step: 25
                )

                // Phase preview
                HStack(spacing: 10) {
                    phaseCell(label: "BACK", value: "\(Int((swingMs * ratio / (ratio + 1)).rounded()))", unit: "ms")
                    phaseCell(label: "DOWN", value: "\(Int((swingMs / (ratio + 1)).rounded()))", unit: "ms")
                }

                // Actions
                HStack(spacing: 10) {
                    if isEdit {
                        Button("Delete") {
                            if let id = editId { store.deletePreset(id) }
                            onClose()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.72, green: 0.18, blue: 0.12))
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(colors.line, lineWidth: 1))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }

                    Button("Cancel", action: onClose)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(colors.inkSoft)
                        .frame(maxWidth: isEdit ? nil : .infinity)
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(colors.line, lineWidth: 1))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)

                    Button("Save preset") { save() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? colors.inkMute : colors.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? colors.line : colors.ink)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 42)
            .background(colors.surface)
            .cornerRadius(28, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea()
        .onAppear { prepopulate() }
    }

    // MARK: Components

    private var sheetHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colors.inkMute.opacity(0.55))
            .frame(width: 38, height: 4)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .padding(.bottom, 8)
    }

    private func sliderRow(label: String, displayValue: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(label)
                    .font(.system(size: 10.5, weight: .medium)).tracking(1.8)
                    .foregroundColor(colors.inkFaint)
                Spacer()
                Text(displayValue)
                    .font(.system(size: 17, weight: .medium).monospacedDigit())
                    .foregroundColor(colors.ink)
            }
            Slider(value: value, in: range, step: step).tint(colors.ink)
        }
    }

    private func phaseCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9.5, weight: .medium)).tracking(1.4)
                .foregroundColor(colors.inkFaint)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .medium).monospacedDigit())
                    .foregroundColor(colors.ink)
                Text(unit)
                    .font(.system(size: 11)).foregroundColor(colors.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(colors.bgDeep)
        .cornerRadius(12)
    }

    // MARK: Logic

    private func prepopulate() {
        switch state {
        case .edit(let id):
            if let p = store.presets.first(where: { $0.id == id }) {
                name = p.name; ratio = p.ratio; swingMs = p.swingMs
            }
        case .add(let seed):
            if let s = seed { name = ""; ratio = s.ratio; swingMs = s.swingMs }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { nameFocused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch state {
        case .edit(let id):
            store.updatePreset(id, name: trimmed, ratio: ratio, swingMs: swingMs)
        case .add:
            store.addPreset(TempoPreset(id: TempoPreset.newId(), name: trimmed, ratio: ratio, swingMs: swingMs))
        }
        onClose()
    }
}

// Convenience rounded corners on specific edges
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

private struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
