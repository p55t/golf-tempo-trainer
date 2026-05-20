import SwiftUI

struct BeatIndicatorView: View {
    let phase: TempoEngine.SwingPhase

    var body: some View {
        ZStack {
            Circle()
                .fill(phaseColor.opacity(0.12))
                .frame(width: 130, height: 130)
                .animation(.easeInOut(duration: 0.15), value: phase)

            Circle()
                .stroke(phaseColor, lineWidth: 4)
                .frame(width: 130, height: 130)
                .animation(.easeInOut(duration: 0.15), value: phase)

            VStack(spacing: 4) {
                Text(phase.label)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(phaseColor)
                    .animation(.easeInOut(duration: 0.1), value: phase)
            }
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .idle:      return .secondary
        case .backswing: return .blue
        case .downswing: return .orange
        }
    }
}
