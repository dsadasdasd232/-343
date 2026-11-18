import SwiftUI

public struct StoriesReelView: View {
    @ObservedObject var viewModel: ChatViewModel

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // "Your Story" button
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(
                            emoji: viewModel.currentUser.avatarEmoji,
                            hexColor: viewModel.currentUser.avatarColorHex,
                            size: 58,
                            isOnline: false
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                        )

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#0A84FF"))
                            .background(Color(UIColor.systemBackground).clipShape(Circle()))
                            .font(.system(size: 20, weight: .bold))
                            .offset(x: 2, y: 2)
                    }

                    Text("Ваша история")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 72)

                // Active online contacts
                ForEach(viewModel.chats.filter { $0.partner.isOnline }) { chat in
                    NavigationLink(destination: ChatDetailView(chatId: chat.id, viewModel: viewModel)) {
                        VStack(spacing: 6) {
                            AvatarView(
                                emoji: chat.partner.avatarEmoji,
                                hexColor: chat.partner.avatarColorHex,
                                size: 58,
                                isOnline: true
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF2D55"), Color(hex: "#5856D6"), Color(hex: "#007AFF")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                                    .padding(-3)
                            )

                            Text(chat.partner.name.components(separatedBy: " ").first ?? chat.partner.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
