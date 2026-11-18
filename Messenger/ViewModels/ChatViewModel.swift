import Foundation
import SwiftUI
import Combine

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var currentUser: UserProfile
    @Published public var chats: [Chat] = []
    @Published public var searchText: String = ""
    @Published public var serverAddress: String = "wss://echo.websocket.org"
    @Published public var isConnectedToServer: Bool = false
    @Published public var currentThemeMode: Int = 0 // 0: Auto, 1: Dark, 2: Light

    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.currentUser = UserProfile(
            name: "Alexey",
            username: "@alexey_dev",
            avatarColorHex: "#5856D6",
            avatarEmoji: "🚀",
            statusBio: "Building the future on iOS ⚡",
            isOnline: true
        )

        loadMockData()
    }

    public var filteredChats: [Chat] {
        let baseChats = chats.sorted { (c1, c2) -> Bool in
            if c1.isPinned != c2.isPinned {
                return c1.isPinned && !c2.isPinned
            }
            let d1 = c1.lastMessage?.timestamp ?? Date.distantPast
            let d2 = c2.lastMessage?.timestamp ?? Date.distantPast
            return d1 > d2
        }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return baseChats
        }

        return baseChats.filter { chat in
            chat.partner.name.localizedCaseInsensitiveContains(searchText) ||
            chat.partner.username.localizedCaseInsensitiveContains(searchText) ||
            chat.messages.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public var totalUnreadCount: Int {
        chats.reduce(0) { $0 + $1.unreadCount }
    }

    public func sendMessage(to chatId: UUID, text: String, type: MessageType = .text, audioDuration: TimeInterval? = nil) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty || type != .text else { return }

        let newMessage = Message(
            senderId: currentUser.id,
            text: cleanText.isEmpty && type == .audio ? "Voice message" : cleanText,
            timestamp: Date(),
            isFromCurrentUser: true,
            status: .sent,
            type: type,
            audioDuration: audioDuration
        )

        chats[index].messages.append(newMessage)
        Haptics.playImpact(style: .medium)

        // Simulate delivery & reply
        let partnerName = chats[index].partner.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self, let idx = self.chats.firstIndex(where: { $0.id == chatId }) else { return }
            if let lastIdx = self.chats[idx].messages.indices.last {
                self.chats[idx].messages[lastIdx].status = .delivered
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, let idx = self.chats.firstIndex(where: { $0.id == chatId }) else { return }
            if let lastIdx = self.chats[idx].messages.indices.last {
                self.chats[idx].messages[lastIdx].status = .read
            }
            self.chats[idx].isTyping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            guard let self = self, let idx = self.chats.firstIndex(where: { $0.id == chatId }) else { return }
            self.chats[idx].isTyping = false

            let replyText = self.generateSmartReply(to: cleanText, from: partnerName)
            let replyMessage = Message(
                senderId: self.chats[idx].partner.id,
                text: replyText,
                timestamp: Date(),
                isFromCurrentUser: false,
                status: .read,
                type: .text
            )
            self.chats[idx].messages.append(replyMessage)
            Haptics.playNotification(type: .success)
        }
    }

    public func togglePin(for chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].isPinned.toggle()
        Haptics.playImpact(style: .light)
    }

    public func toggleMute(for chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].isMuted.toggle()
        Haptics.playImpact(style: .light)
    }

    public func markAsRead(chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].unreadCount = 0
    }

    public func addReaction(to messageId: UUID, in chatId: UUID, emoji: String) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatId }),
              let msgIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == messageId }) else { return }

        var message = chats[chatIndex].messages[msgIndex]
        if let reactionIdx = message.reactions.firstIndex(where: { $0.emoji == emoji }) {
            if message.reactions[reactionIdx].userReacted {
                message.reactions[reactionIdx].count -= 1
                message.reactions[reactionIdx].userReacted = false
                if message.reactions[reactionIdx].count <= 0 {
                    message.reactions.remove(at: reactionIdx)
                }
            } else {
                message.reactions[reactionIdx].count += 1
                message.reactions[reactionIdx].userReacted = true
            }
        } else {
            message.reactions.append(MessageReaction(emoji: emoji, count: 1, userReacted: true))
        }

        chats[chatIndex].messages[msgIndex] = message
    }

    public func createNewChat(name: String, username: String, emoji: String, colorHex: String) {
        let partner = UserProfile(
            name: name,
            username: username.hasPrefix("@") ? username : "@\(username)",
            avatarColorHex: colorHex,
            avatarEmoji: emoji,
            isOnline: true
        )
        let newChat = Chat(
            partner: partner,
            messages: [
                Message(
                    senderId: partner.id,
                    text: "Hey! Let's connect on Sideloadly Messenger! 🎉",
                    timestamp: Date(),
                    isFromCurrentUser: false
                )
            ]
        )
        chats.insert(newChat, at: 0)
    }

    private func generateSmartReply(to input: String, from partner: String) -> String {
        let lower = input.lowercased()
        if lower.contains("привет") || lower.contains("hello") || lower.contains("hi") {
            return "Привет! Как твои дела? Как проходит тест мессенджера?"
        } else if lower.contains("как дела") || lower.contains("how are you") {
            return "Отлично! Дизайн просто огонь, анимации на 120 FPS летают!"
        } else if lower.contains("sideloadly") || lower.contains("установка") || lower.contains("ipa") {
            return "Sideloadly — топ! Подписал IPA личным Apple ID и всё работает без джейлбрейка."
        } else if lower.contains("фото") || lower.contains("картинка") {
            return "Классный кадр! Цвета очень сочные."
        } else {
            let templates = [
                "Принято! Отличная идея, давай реализуем.",
                "Договорились, держи меня в курсе!",
                "Полностью согласен, выглядит супер круто 🔥",
                "Сейчас протестирую и отпишусь тебе сюда же!"
            ]
            return templates.randomElement() ?? "Сообщение доставлено!"
        }
    }

    private func loadMockData() {
        let aiPartner = UserProfile(
            name: "Sideloadly Bot",
            username: "@sideload_assistant",
            avatarColorHex: "#007AFF",
            avatarEmoji: "🤖",
            statusBio: "Official Sideloadly Testing Bot",
            isOnline: true
        )

        let dmitryPartner = UserProfile(
            name: "Dmitry",
            username: "@dmitry_ios",
            avatarColorHex: "#34C759",
            avatarEmoji: "⚡",
            statusBio: "iOS Power User | Cyber & Design",
            isOnline: true
        )

        let elenaPartner = UserProfile(
            name: "Elena Rostova",
            username: "@elena_ux",
            avatarColorHex: "#FF2D55",
            avatarEmoji: "✨",
            statusBio: "Product Designer & UI lover",
            isOnline: false,
            lastSeen: Date().addingTimeInterval(-1800)
        )

        let cryptoPartner = UserProfile(
            name: "Crypto Alpha Club",
            username: "@crypto_alpha",
            avatarColorHex: "#FF9500",
            avatarEmoji: "🪙",
            statusBio: "DeFi, TON, Solana & Bitcoin trends",
            isOnline: true
        )

        let chat1 = Chat(
            partner: aiPartner,
            messages: [
                Message(
                    senderId: aiPartner.id,
                    text: "Добро пожаловать в твой собственный iOS мессенджер!",
                    timestamp: Date().addingTimeInterval(-3600),
                    isFromCurrentUser: false
                ),
                Message(
                    senderId: currentUser.id,
                    text: "Привет! Приложение успешно установлено через Sideloadly?",
                    timestamp: Date().addingTimeInterval(-3500),
                    isFromCurrentUser: true,
                    status: .read
                ),
                Message(
                    senderId: aiPartner.id,
                    text: "Да, абсолютно! Приложение подписано твоим Apple ID, работает плавно на чистом SwiftUI и готово к ежедневной работе.",
                    timestamp: Date().addingTimeInterval(-3400),
                    isFromCurrentUser: false,
                    reactions: [MessageReaction(emoji: "🔥", count: 3, userReacted: true)]
                )
            ],
            isPinned: true,
            unreadCount: 0
        )

        let chat2 = Chat(
            partner: dmitryPartner,
            messages: [
                Message(
                    senderId: dmitryPartner.id,
                    text: "Зацени новое оформление: стекло, градиенты, темная тема в стиле iOS 18!",
                    timestamp: Date().addingTimeInterval(-900),
                    isFromCurrentUser: false
                ),
                Message(
                    senderId: dmitryPartner.id,
                    text: "Голосовые сообщения тоже с интерактивным плеером:",
                    timestamp: Date().addingTimeInterval(-800),
                    isFromCurrentUser: false,
                    type: .audio,
                    audioDuration: 24.0
                )
            ],
            isPinned: true,
            unreadCount: 1
        )

        let chat3 = Chat(
            partner: elenaPartner,
            messages: [
                Message(
                    senderId: elenaPartner.id,
                    text: "Макеты согласованы! Отправляю финальный пак иконок.",
                    timestamp: Date().addingTimeInterval(-86400),
                    isFromCurrentUser: false
                )
            ],
            unreadCount: 0
        )

        let chat4 = Chat(
            partner: cryptoPartner,
            messages: [
                Message(
                    senderId: cryptoPartner.id,
                    text: "BTC пробил очередной уровень. Вся ликвидность переходит в альты 🚀",
                    timestamp: Date().addingTimeInterval(-172800),
                    isFromCurrentUser: false
                )
            ],
            unreadCount: 5
        )

        self.chats = [chat1, chat2, chat3, chat4]
    }
}
