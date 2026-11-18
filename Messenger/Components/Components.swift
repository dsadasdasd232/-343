import SwiftUI

// MARK: - Haptics Helper
public struct Haptics {
    public static func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func playNotification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Color Hex Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 10, 132, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Modern Avatar View
public struct AvatarView: View {
    public let emoji: String
    public let hexColor: String
    public let size: CGFloat
    public let isOnline: Bool

    public init(emoji: String, hexColor: String = "#0A84FF", size: CGFloat = 52, isOnline: Bool = false) {
        self.emoji = emoji
        self.hexColor = hexColor
        self.size = size
        self.isOnline = isOnline
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: hexColor), Color(hex: hexColor).opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: Color(hex: hexColor).opacity(0.3), radius: 6, x: 0, y: 3)

                Text(emoji)
                    .font(.system(size: size * 0.48))
            }

            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Audio Waveform Simulation View
public struct AudioWaveformView: View {
    public let duration: TimeInterval
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0.0

    let barHeights: [CGFloat] = [10, 18, 14, 26, 22, 16, 28, 20, 12, 24, 18, 30, 14, 22, 10]

    public init(duration: TimeInterval = 12.0) {
        self.duration = duration
    }

    public var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                Haptics.playImpact(style: .light)
                withAnimation(.spring(response: 0.3)) {
                    isPlaying.toggle()
                }
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }

            HStack(spacing: 3) {
                ForEach(0..<barHeights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(isPlaying && CGFloat(index) / CGFloat(barHeights.count) <= progress ? 1.0 : 0.5))
                        .frame(width: 3, height: barHeights[index])
                }
            }

            Text(String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .cornerRadius(18)
    }
}

// MARK: - Quick Reaction Picker
public struct ReactionPickerView: View {
    public let onSelect: (String) -> Void
    let reactions = ["❤️", "👍", "🔥", "😂", "😮", "😢", "🎉"]

    public init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(reactions, id: \.self) { emoji in
                Button(action: {
                    Haptics.playImpact(style: .light)
                    onSelect(emoji)
                }) {
                    Text(emoji)
                        .font(.system(size: 24))
                        .scaleEffect(1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}
