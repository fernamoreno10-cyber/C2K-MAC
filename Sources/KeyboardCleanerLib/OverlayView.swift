import SwiftUI

struct OverlayView: View {
    @ObservedObject var state: AppState
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header: icon + title + timer
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "keyboard")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Limpiando teclado")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(state.formattedTime())
                        .font(.system(size: 13, weight: .regular).monospacedDigit())
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.75))
                        .frame(width: progressWidth(total: geo.size.width))
                        .animation(.linear(duration: 1), value: state.timeRemaining)
                }
            }
            .frame(height: 4)

            // Footer: status + button
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#ff3b30"))
                        .frame(width: 6, height: 6)
                    Text("TECLADO BLOQUEADO")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Button(action: onDone) {
                    Text("Terminado")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
                .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
        )
    }

    private func progressWidth(total: CGFloat) -> CGFloat {
        guard state.duration > 0 else { return 0 }
        let raw = total * CGFloat(state.timeRemaining) / CGFloat(state.duration)
        return min(total, max(0, raw))
    }
}

struct StatusDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
