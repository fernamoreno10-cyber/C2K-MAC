import SwiftUI

struct SettingsView: View {
    @State private var minutes: Double
    let onDone: () -> Void

    init(onDone: @escaping () -> Void) {
        _minutes = State(initialValue: Double(AppState.shared.duration) / 60.0)
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Duración de limpieza")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#1d1d1f"))

            VStack(spacing: 8) {
                Slider(value: $minutes, in: 1...10, step: 1)
                    .tint(Color(hex: "#1d1d1f"))
                    .onChange(of: minutes) {
                        AppState.shared.duration = Int(minutes) * 60
                    }
                Text("\(Int(minutes)) min")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#86868b"))
            }

            Button("Listo") { onDone() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(Color(hex: "#1d1d1f"))
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(width: 260)
        .background(Color(hex: "#f5f5f7"))
    }
}
