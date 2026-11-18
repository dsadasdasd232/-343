import SwiftUI

public struct ChatsListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingNewChatSheet = false

    public var body: some View {
        NavigationStack {
            List {
                // Stories / Online Section
                Section {
                    StoriesReelView(viewModel: viewModel)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                // Chat items
                Section {
                    ForEach(viewModel.filteredChats) { chat in
                        NavigationLink(destination: ChatDetailView(chatId: chat.id, viewModel: viewModel)) {
                            ChatRowView(chat: chat)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color(UIColor.secondarySystemGroupedBackground).opacity(0.75))
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.togglePin(for: chat.id)
                            } label: {
                                Label(chat.isPinned ? "Открепить" : "Закрепить", systemImage: chat.isPinned ? "pin.slash.fill" : "pin.fill")
                            }
                            .tint(Color(hex: "#FF9500"))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                viewModel.toggleMute(for: chat.id)
                            } label: {
                                Label(chat.isMuted ? "Вкл. звук" : "Без звука", systemImage: chat.isMuted ? "bell.fill" : "bell.slash.fill")
                            }
                            .tint(Color(hex: "#5856D6"))

                            Button(role: .destructive) {
                                if let index = viewModel.chats.firstIndex(where: { $0.id == chat.id }) {
                                    viewModel.chats.remove(at: index)
                                }
                            } label: {
                                Label("Удалить", systemImage: "trash.fill")
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.togglePin(for: chat.id)
                            } label: {
                                Label(chat.isPinned ? "Открепить" : "Закрепить", systemImage: "pin")
                            }

                            Button {
                                viewModel.toggleMute(for: chat.id)
                            } label: {
                                Label(chat.isMuted ? "Включить уведомления" : "Отключить звук", systemImage: "bell")
                            }

                            Button {
                                viewModel.markAsRead(chatId: chat.id)
                            } label: {
                                Label("Пометить как прочитанное", systemImage: "checkmark.message")
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .searchable(text: $viewModel.searchText, prompt: "Поиск по чатам и сообщениям")
            .navigationTitle("Чаты")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Изм.") {
                        Haptics.playImpact(style: .light)
                    }
                    .foregroundColor(Color(hex: "#0A84FF"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Haptics.playImpact(style: .medium)
                        showingNewChatSheet = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#0A84FF"))
                    }
                }
            }
            .sheet(isPresented: $showingNewChatSheet) {
                NewChatModalView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Chat Row View
public struct ChatRowView: View {
    public let chat: Chat

    private var timeString: String {
        guard let date = chat.lastMessage?.timestamp else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: date)
        }
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(
                emoji: chat.partner.avatarEmoji,
                hexColor: chat.partner.avatarColorHex,
                size: 54,
                isOnline: chat.partner.isOnline
            )

            // Name + last message preview
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chat.partner.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(timeString)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(chat.unreadCount > 0 ? Color(hex: "#0A84FF") : .secondary)
                }

                HStack(alignment: .center, spacing: 4) {
                    if chat.isTyping {
                        HStack(spacing: 4) {
                            Text("печатает")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#0A84FF"))

                            BouncingDotsView()
                        }
                    } else if let lastMsg = chat.lastMessage {
                        if lastMsg.isFromCurrentUser {
                            HStack(spacing: 2) {
                                switch lastMsg.status {
                                case .sending:
                                    Image(systemName: "clock")
                                case .sent:
                                    Image(systemName: "checkmark")
                                case .delivered:
                                    Image(systemName: "checkmark.circle")
                                case .read:
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }

                        if lastMsg.type == .audio {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Text(lastMsg.text)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Нет сообщений")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(chat.isMuted ? Color.secondary : Color(hex: "#0A84FF"))
                            )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Animated 3 bouncing dots for typing status
public struct BouncingDotsView: View {
    @State private var dotPhase: Int = 0

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "#0A84FF"))
                    .frame(width: 4, height: 4)
                    .scaleEffect(dotPhase == i ? 1.4 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: dotPhase
                    )
            }
        }
        .onAppear {
            dotPhase = 1
        }
    }
}
