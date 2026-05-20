import Foundation

enum SwingMode: String, CaseIterable, Identifiable {
    case fullSwing = "Full Swing"
    case wedge     = "Wedge"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .fullSwing: return "Full Swing"
        case .wedge:     return "Wedge / Short"
        }
    }
}

// Tour Tempo gears — based on Novosel 3:1 frame research (24fps)
// Gear 1: 15/6 frames → ~0.625s back / ~0.208s down  (88 BPM equivalent)
// Gear 2: 24/8 frames → ~1.000s back / ~0.333s down  (72 BPM equivalent)
// Gear 3: 27/9 frames → ~1.125s back / ~0.375s down  (60 BPM equivalent)
enum TempoGear: Int, CaseIterable, Identifiable {
    case gear1 = 1
    case gear2 = 2
    case gear3 = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .gear1: return "Gear 1"
        case .gear2: return "Gear 2"
        case .gear3: return "Gear 3"
        }
    }

    var subtitle: String {
        switch self {
        case .gear1: return "Fast · 88 BPM"
        case .gear2: return "Medium · 72 BPM"
        case .gear3: return "Slow · 60 BPM"
        }
    }

    var bpm: Int {
        switch self {
        case .gear1: return 88
        case .gear2: return 72
        case .gear3: return 60
        }
    }

    // Backswing duration — wedge is ~20% faster overall, same 3:1 ratio
    func backswingDuration(for mode: SwingMode) -> Double {
        let base: Double
        switch self {
        case .gear1: base = 0.625
        case .gear2: base = 1.000
        case .gear3: base = 1.125
        }
        return mode == .wedge ? base * 0.80 : base
    }

    // Downswing always = backswing / 3  (the 3:1 rule)
    func downswingDuration(for mode: SwingMode) -> Double {
        backswingDuration(for: mode) / 3.0
    }

    // Rest between cycles = one full downswing duration
    func restDuration(for mode: SwingMode) -> Double {
        downswingDuration(for: mode)
    }
}
