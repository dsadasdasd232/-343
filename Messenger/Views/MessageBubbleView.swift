import SwiftUI

public struct MessageBubbleView: View {
    public let message: Message
    public let onLongPress: () -> Void
    public let onReactionTap: (String) -> Void

    public init(
        message: Message,
        onLongPress: @escaping () -> Void,
        onReactionTap: @escaping (String) -> Void
    ) {
        self.message = message
        self.onLongPress = onLongPress
        self.onReactionTap = onReactionTap
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                // Main Bubble
                VStack(alignment: .leading, spacing: 6) {
                    if message.type == .audio {
                        AudioWaveformView(duration: message.audioDuration ?? 15.0)
                    } else {
                        Text(message.text)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(message.isFromCurrentUser ? .white : Color(UIColor.label))
                            .lineSpacing(2)
                    }

                    // Metadata footer: time + read receipts
                    HStack(spacing: 4) {
                        Spacer()

                        Text(timeFormatter.string(from: message.timestamp))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(message.isFromCurrentUser ? Color.white.opacity(0.7) : Color.secondary)

                        if message.isFromCurrentUser {
                            switch message.status {
                            case .sending:
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                            case .sent:
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            case .delivered:
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            case .read:
                                HStack(spacing: -3) {
                                    Image(systemName: "checkmark")
                                    Image(systemName: "checkmark")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#64D2FF"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if message.isFromCurrentUser {
                            LinearGradient(
                                colors: [Color(hex: "#0A84FF"), Color(hex: "#5E5CE6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(UIColor.secondarySystemBackground)
                        }
                    }
                )
                .clipShape(
                    RoundedCornerShape(
                        radius: 18,
                        corners: message.isFromCurrentUser
                            ? [.topLeft, .topRight, .bottomLeft]
                            : [.topLeft, .topRight, .bottomRight]
                    )
                )
                .shadow(
                    color: message.isFromCurrentUser ? Color(hex: "#0A84FF").opacity(0.25) : Color.black.opacity(0.04),
                    radius: 5,
                    x: 0,
                    y: 2
                )
                .onLongPressGesture {
                    Haptics.playImpact(style: .medium)
                    onLongPress()
                }

                // Reactions Bar
                if !message.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.reactions) { reaction in
                            Button(action: {
                                onReactionTap(reaction.emoji)
                            }) {
                                HStack(spacing: 2) {
                                    Text(reaction.emoji)
                                        .font(.system(size: 12))
                                    if reaction.count > 1 {
                                        Text("\(reaction.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(reaction.userReacted ? Color(hex: "#0A84FF").opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                                        .overlay(
                                            Capsule()
                                                .stroke(reaction.userReacted ? Color(hex: "#0A84FF") : Color.clear, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.top, 1)
                }
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}

// Custom shape for custom corner radii
public struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
