import SwiftUI

enum AppRoute { case home, live }

enum SheetState: Identifiable {
    case add(seed: TempoPreset?)
    case edit(id: String)
    var id: String {
        switch self {
        case .add:          return "add"
        case .edit(let i):  return "edit-\(i)"
        }
    }
}

struct ContentView: View {
    @StateObject private var store = AppStore()
    @StateObject private var audioPlayer: AudioCuePlayer
    @StateObject private var engine: TempoEngine

    @State private var route: AppRoute = .home
    @State private var sheet: SheetState? = nil

    init() {
        let player = AudioCuePlayer()
        _audioPlayer = StateObject(wrappedValue: player)
        _engine      = StateObject(wrappedValue: TempoEngine(audioPlayer: player))
    }

    var body: some View {
        let colors = store.isDark ? TC.night : TC.paper
        ZStack {
            if route == .home {
                HomeView(
                    store: store,
                    onStart:      startSession,
                    onEditPreset: { id in sheet = .edit(id: id) },
                    onAddPreset:  { sheet = .add(seed: nil) }
                )
            } else {
                LiveSessionView(
                    store: store,
                    engine: engine,
                    onBack: endSession,
                    onSaveAsNew: {
                        sheet = .add(seed: store.activePreset)
                    }
                )
            }

            if let s = sheet {
                PresetSheetView(
                    state: s,
                    store: store,
                    onClose: { sheet = nil }
                )
                .zIndex(10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Background as modifier so the ZStack layout respects safe areas
        .background(colors.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.28), value: sheet?.id)
        .environment(\.tc, colors)
        .onAppear {
            engine.applyPreset(store.activePreset)
            engine.soundOn = store.soundOn
            engine.volume  = store.volume
        }
        .onChange(of: store.activePreset) { engine.applyPreset($0) }
        .onChange(of: store.soundOn)      { engine.soundOn = $0 }
        .onChange(of: store.volume)       { engine.volume  = $0 }
    }

    private func startSession() {
        withAnimation(.easeInOut(duration: 0.35)) { route = .live }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { engine.start() }
    }

    private func endSession() {
        engine.stop()
        withAnimation(.easeInOut(duration: 0.35)) { route = .home }
    }
}
