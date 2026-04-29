import SwiftUI

struct OverlayView: View {
    @ObservedObject var state: AppState
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#f5f5f7").ignoresSafeArea()

            VStack(spacing: 20) {
                // Lock icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(hex: "#1d1d1f"))
                }

                Text("CLEAN MODE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(Color(hex: "#86868b"))

                Text(state.formattedTime())
                    .font(.system(size: 24, weight: .light).monospacedDigit())
                    .foregroundColor(Color(hex: "#1d1d1f"))

                // Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#e0e0e0"))
                        .frame(width: 320, height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1d1d1f"))
                        .frame(width: progressWidth, height: 6)
                        .animation(.linear(duration: 1), value: state.timeRemaining)
                }

                HStack(spacing: 24) {
                    StatusDot(color: Color(hex: "#ff3b30"), label: "Teclado bloqueado")
                    StatusDot(color: Color(hex: "#34c759"), label: "Mouse activo")
                }

                Button(action: onDone) {
                    Text("Terminado")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#86868b"))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#d0d0d0"), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    private var progressWidth: CGFloat {
        guard state.duration > 0 else { return 0 }
        return 320 * CGFloat(state.timeRemaining) / CGFloat(state.duration)
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
                .foregroundColor(Color(hex: "#86868b"))
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
