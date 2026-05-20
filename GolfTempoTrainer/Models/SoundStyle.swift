import Foundation

enum SoundStyle: String, CaseIterable, Identifiable {
    case metronome  = "metronome"
    case bell       = "bell"
    case beep       = "beep"
    case woodblock  = "woodblock"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .metronome:  return "Metronome"
        case .bell:       return "Bell"
        case .beep:       return "Beep"
        case .woodblock:  return "Wood Block"
        }
    }

    var icon: String {
        switch self {
        case .metronome:  return "🎵"
        case .bell:       return "🔔"
        case .beep:       return "📡"
        case .woodblock:  return "🪵"
        }
    }

    var backFilename: String { "\(rawValue)_back" }
    var hitFilename:  String { "\(rawValue)_hit" }

    // Persist selection across launches
    static var saved: SoundStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: "soundStyle") ?? SoundStyle.metronome.rawValue
            return SoundStyle(rawValue: raw) ?? .metronome
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "soundStyle")
        }
    }
}
