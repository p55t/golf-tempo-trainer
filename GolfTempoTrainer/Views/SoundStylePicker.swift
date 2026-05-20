import SwiftUI

struct SoundStylePicker: View {
    @ObservedObject var audioPlayer: AudioCuePlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SOUND STYLE")
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(SoundStyle.allCases) { style in
                    SoundStyleButton(
                        style: style,
                        isSelected: audioPlayer.soundStyle == style
                    ) {
                        audioPlayer.soundStyle = style
                        audioPlayer.previewStyle(style)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SoundStyleButton: View {
    let style: SoundStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(style.icon).font(.title3)
                Text(style.label)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
