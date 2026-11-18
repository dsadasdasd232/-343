import SwiftUI

public struct ChatDetailView: View {
    public let chatId: UUID
    @ObservedObject var viewModel: ChatViewModel

    @State private var inputText: String = ""
    @State private var activeReactionMessageId: UUID? = nil
    @State private var isRecordingVoice: Bool = false
    @State private var recordingTimer: TimeInterval = 0
    @State private var showAttachmentMenu = false

    private var currentChat: Chat? {
        viewModel.chats.first(where: { $0.id == chatId })
    }

    public var body: some View {
        ZStack {
            // Background subtle gradient/texture
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages Scroll Area
                if let chat = currentChat {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                // Encryption security notice
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 11))
                                    Text("Сообщения защищены сквозным шифрованием (E2EE)")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(UIColor.secondarySystemBackground)))
                                .padding(.vertical, 10)

                                ForEach(chat.messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        onLongPress: {
                                            withAnimation(.spring(response: 0.3)) {
                                                activeReactionMessageId = message.id
                                            }
                                        },
                                        onReactionTap: { emoji in
                                            viewModel.addReaction(to: message.id, in: chat.id, emoji: emoji)
                                        }
                                    )
                                    .id(message.id)
                                }

                                if chat.isTyping {
                                    HStack {
                                        HStack(spacing: 6) {
                                            BouncingDotsView()
                                            Text("печатает...")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color(UIColor.secondarySystemBackground)))

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .onAppear {
                            viewModel.markAsRead(chatId: chatId)
                            if let lastId = chat.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                        .onChange(of: chat.messages.count) { _ in
                            if let lastId = chat.messages.last?.id {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Bottom Input Bar
                bottomInputBar
            }

            // Reaction Picker overlay
            if let activeId = activeReactionMessageId {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { activeReactionMessageId = nil }
                    }

                VStack {
                    ReactionPickerView { selectedEmoji in
                        viewModel.addReaction(to: activeId, in: chatId, emoji: selectedEmoji)
                        withAnimation { activeReactionMessageId = nil }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let chat = currentChat {
                    VStack(spacing: 2) {
                        Text(chat.partner.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(chat.partner.isOnline ? "в сети" : "был(а) недавно")
                            .font(.system(size: 11))
                            .foregroundColor(chat.partner.isOnline ? .green : .secondary)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if let chat = currentChat {
                    HStack(spacing: 14) {
                        Button {
                            Haptics.playImpact(style: .light)
                        } label: {
                            Image(systemName: "phone")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#0A84FF"))
                        }

                        AvatarView(
                            emoji: chat.partner.avatarEmoji,
                            hexColor: chat.partner.avatarColorHex,
                            size: 32,
                            isOnline: chat.partner.isOnline
                        )
                    }
                }
            }
        }
        .confirmationDialog("Вложения", isPresented: $showAttachmentMenu, titleVisibility: .visible) {
            Button("📷 Камера") {
                viewModel.sendMessage(to: chatId, text: "📷 [Фото с камеры]")
            }
            Button("🖼 Фото или видео") {
                viewModel.sendMessage(to: chatId, text: "🖼 [Фотография из галереи]")
            }
            Button("📄 Документ") {
                viewModel.sendMessage(to: chatId, text: "📄 Document.pdf (2.4 MB)")
            }
            Button("📍 Геолокация") {
                viewModel.sendMessage(to: chatId, text: "📍 Москва, Россия")
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // Input Bar Component
    private var bottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 10) {
                // Attachment (+) button
                Button(action: {
                    Haptics.playImpact(style: .light)
                    showAttachmentMenu = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "#0A84FF"))
                }
                .padding(.bottom, 6)

                // Input Box or Voice Recording Status
                if isRecordingVoice {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)

                        Text("Запись: \(String(format: "0:%02d", Int(recordingTimer)))")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)

                        Spacer()

                        Text("Отпустите для отправки")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(19)
                } else {
                    TextField("Сообщение...", text: $inputText, axis: .vertical)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(19)
                        .lineLimit(1...5)
                }

                // Send or Voice Mic Button
                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: {
                        toggleVoiceRecording()
                    }) {
                        Image(systemName: isRecordingVoice ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(isRecordingVoice ? Color.red : Color(hex: "#0A84FF"))
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: {
                        sendCurrentText()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#0A84FF"), Color(hex: "#5E5CE6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground).opacity(0.95))
        }
    }

    private func sendCurrentText() {
        let textToSend = inputText
        inputText = ""
        viewModel.sendMessage(to: chatId, text: textToSend)
    }

    private func toggleVoiceRecording() {
        Haptics.playImpact(style: .medium)
        if isRecordingVoice {
            isRecordingVoice = false
            viewModel.sendMessage(to: chatId, text: "", type: .audio, audioDuration: recordingTimer > 0 ? recordingTimer : 5.0)
            recordingTimer = 0
        } else {
            isRecordingVoice = true
            recordingTimer = 3.0
        }
    }
}
