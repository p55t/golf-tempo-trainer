# Golf Tempo Trainer

iOS app for training golf swing tempo using the **3:1 backswing-to-downswing ratio** — the ratio consistent across all tour professionals (Novosel Tour Tempo research).

Three synthesized audio beats guide each swing: **takeaway → top → impact**. Audio continues with the screen locked.

---

## Tempo Science

Tour professionals share a consistent 3:1 backswing-to-downswing ratio regardless of club or swing speed.

| Swing Duration | Backswing | Downswing | Ratio |
|---|---|---|---|
| 0.84s (fast) | 0.63s | 0.21s | 3:1 |
| 1.00s (tour avg) | 0.75s | 0.25s | 3:1 |
| 1.15s (beginner) | 0.86s | 0.29s | 3:1 |

Most amateurs swing at a 2:1 ratio — rushing the downswing. Start with a longer swing duration (1.0–1.2s) and the default 3:1 ratio.

---

## Features

- **3-beat metronome** — distinct tones for takeaway, top of backswing, and impact
- **4 sound styles** — metronome, beep, bell, wood block (all synthesized, no audio files)
- **Fully customisable presets** — set ratio (2:1–4:1) and swing duration per club
- **3 visualisations** — arc (golfer silhouette), dial, and bars
- **Background audio** — keeps playing when screen locks
- **Light / dark theme**

---

## Setup

### Requirements
- Xcode 15+
- iOS 16+ device or simulator
- No API keys or external dependencies

### Build

```bash
# Option A — xcodegen (recommended)
brew install xcodegen
cd golf-tempo-trainer
xcodegen generate
open GolfTempoTrainer.xcodeproj

# Option B — open directly
open GolfTempoTrainer.xcodeproj
```

Then select your device in Xcode and hit **⌘R**.

**First install on a physical device:** go to Settings → General → VPN & Device Management → your Apple ID → Trust.

---

## How It Works

1. Pick or create a **preset** (club name, ratio, swing duration)
2. Tap **Begin session**
3. Hear three beats per cycle:
   - **Takeaway** — start your backswing
   - **Top** — you've reached the top (softer tone)
   - **Impact** — drive through the ball
4. Adjust ratio and duration live with the sliders
5. Lock your screen — audio keeps going

---

## Audio

All sounds are synthesised at runtime using `AVAudioEngine` — no bundled audio files. Each style uses a sine + harmonic stack with an exponential decay envelope. The three beats play at ascending pitches (root → major third → fifth) so they're tonally distinct even at low volume.

| Style | Character |
|---|---|
| Metronome | Clean sine, short punch |
| Beep | Odd harmonics, square-ish |
| Bell | Inharmonic partials, long decay |
| Wood Block | Short, sharp, slight inharmonicity |

---

## File Structure

```
GolfTempoTrainer/
├── GolfTempoTrainerApp.swift        # Entry point
├── Models/
│   ├── TempoConfig.swift            # AppStore, TempoPreset, design tokens
│   └── SoundStyle.swift             # Sound style enum
├── Audio/
│   ├── TempoEngine.swift            # Swing cycle timing (60fps CADisplayLink-style)
│   └── AudioCuePlayer.swift         # AVAudioEngine + PCM synthesis
├── Services/
│   └── ElevenLabsService.swift      # Unused — kept for reference
├── Views/
│   ├── ContentView.swift            # Root navigation + sheet orchestration
│   ├── BeatIndicatorView.swift      # HomeView (preset list)
│   ├── SoundStylePicker.swift       # LiveSessionView (training screen)
│   ├── GearButton.swift             # PendulumArcView / DialView / BarsView
│   └── PresetSheetView.swift        # Add / edit preset sheet
└── Resources/
    └── Audio/                       # Legacy mp3s (unused, safe to delete)
```
