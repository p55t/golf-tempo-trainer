import Foundation
import SwiftUI

// MARK: - Preset model

struct TempoPreset: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var ratio: Double    // backswing / downswing
    var swingMs: Double  // total back+down in ms

    var backMs: Double { swingMs * ratio / (ratio + 1) }
    var downMs: Double { swingMs / (ratio + 1) }

    static let defaults: [TempoPreset] = [
        TempoPreset(id: "p1", name: "7-Iron",  ratio: 3.0, swingMs: 1000),
        TempoPreset(id: "p2", name: "Wedge",   ratio: 2.7, swingMs: 1150),
        TempoPreset(id: "p3", name: "Driver",  ratio: 3.2, swingMs: 1100),
    ]

    static func newId() -> String {
        "p" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6).lowercased()
    }
}

// MARK: - App-level state

final class AppStore: ObservableObject {
    @Published var presets: [TempoPreset] {
        didSet { save() }
    }
    @Published var activePresetId: String {
        didSet { UserDefaults.standard.set(activePresetId, forKey: "activePresetId") }
    }
    @Published var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }
    @Published var soundOn: Bool {
        didSet { UserDefaults.standard.set(soundOn, forKey: "soundOn") }
    }
    @Published var volume: Double {
        didSet { UserDefaults.standard.set(volume, forKey: "volume") }
    }
    @Published var vizStyle: VizStyle {
        didSet { UserDefaults.standard.set(vizStyle.rawValue, forKey: "vizStyle") }
    }

    enum VizStyle: String, CaseIterable {
        case arc, dial, bars
        var label: String {
            switch self {
            case .arc:  return "Arc"
            case .dial: return "Dial"
            case .bars: return "Bars"
            }
        }
    }

    var activePreset: TempoPreset {
        presets.first { $0.id == activePresetId } ?? presets[0]
    }

    init() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: "presets"),
           let saved = try? JSONDecoder().decode([TempoPreset].self, from: data) {
            presets = saved
        } else {
            presets = TempoPreset.defaults
        }
        activePresetId = ud.string(forKey: "activePresetId") ?? "p1"
        isDark = ud.bool(forKey: "isDark")
        soundOn = ud.object(forKey: "soundOn") as? Bool ?? true
        volume = ud.object(forKey: "volume") as? Double ?? 0.55
        vizStyle = VizStyle(rawValue: ud.string(forKey: "vizStyle") ?? "") ?? .arc
    }

    private func save() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "presets")
        }
    }

    func updatePreset(_ id: String, name: String? = nil, ratio: Double? = nil, swingMs: Double? = nil) {
        guard let i = presets.firstIndex(where: { $0.id == id }) else { return }
        if let v = name   { presets[i].name = v }
        if let v = ratio  { presets[i].ratio = min(max(v, 1.5), 5.0) }
        if let v = swingMs { presets[i].swingMs = min(max(v, 500), 2500) }
    }

    func addPreset(_ preset: TempoPreset) {
        presets.append(preset)
        activePresetId = preset.id
    }

    func deletePreset(_ id: String) {
        guard presets.count > 1 else { return }
        presets.removeAll { $0.id == id }
        if activePresetId == id { activePresetId = presets[0].id }
    }
}

// MARK: - Design tokens

struct TC {
    let bg:         Color
    let bgDeep:     Color
    let surface:    Color
    let surface2:   Color
    let ink:        Color
    let inkSoft:    Color
    let inkFaint:   Color
    let inkMute:    Color
    let line:       Color
    let lineSoft:   Color
    let accent:     Color
    let gold:       Color
    let goldDeep:   Color
    let tone1:      Color
    let tone2:      Color

    static let paper = TC(
        bg:       Color(red: 0.957, green: 0.949, blue: 0.912),
        bgDeep:   Color(red: 0.938, green: 0.928, blue: 0.888),
        surface:  Color(red: 0.980, green: 0.976, blue: 0.964),
        surface2: Color(red: 0.910, green: 0.898, blue: 0.860),
        ink:      Color(red: 0.088, green: 0.182, blue: 0.120),
        inkSoft:  Color(red: 0.158, green: 0.322, blue: 0.212),
        inkFaint: Color(red: 0.275, green: 0.468, blue: 0.340),
        inkMute:  Color(red: 0.458, green: 0.622, blue: 0.520),
        line:     Color(red: 0.590, green: 0.748, blue: 0.652),
        lineSoft: Color(red: 0.695, green: 0.822, blue: 0.746),
        accent:   Color(red: 0.062, green: 0.265, blue: 0.158),
        gold:     Color(red: 0.868, green: 0.700, blue: 0.288),
        goldDeep: Color(red: 0.752, green: 0.570, blue: 0.195),
        tone1:    Color(red: 0.168, green: 0.398, blue: 0.258),
        tone2:    Color(red: 0.132, green: 0.352, blue: 0.225)
    )

    static let night = TC(
        bg:       Color(red: 0.040, green: 0.132, blue: 0.088),
        bgDeep:   Color(red: 0.022, green: 0.088, blue: 0.058),
        surface:  Color(red: 0.055, green: 0.172, blue: 0.115),
        surface2: Color(red: 0.075, green: 0.215, blue: 0.148),
        ink:      Color(red: 0.955, green: 0.950, blue: 0.940),
        inkSoft:  Color(red: 0.775, green: 0.782, blue: 0.755),
        inkFaint: Color(red: 0.525, green: 0.548, blue: 0.508),
        inkMute:  Color(red: 0.332, green: 0.358, blue: 0.340),
        line:     Color(red: 0.198, green: 0.268, blue: 0.225),
        lineSoft: Color(red: 0.148, green: 0.215, blue: 0.178),
        accent:   Color(red: 0.620, green: 0.852, blue: 0.718),
        gold:     Color(red: 0.952, green: 0.792, blue: 0.355),
        goldDeep: Color(red: 0.840, green: 0.672, blue: 0.260),
        tone1:    Color(red: 0.525, green: 0.752, blue: 0.618),
        tone2:    Color(red: 0.452, green: 0.695, blue: 0.558)
    )
}

// Environment key for theme colors
struct TempoColorsKey: EnvironmentKey {
    static let defaultValue = TC.paper
}

extension EnvironmentValues {
    var tc: TC {
        get { self[TempoColorsKey.self] }
        set { self[TempoColorsKey.self] = newValue }
    }
}
