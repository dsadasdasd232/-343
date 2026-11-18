import SwiftUI

public struct NewChatModalView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var selectedEmoji: String = "👤"
    @State private var selectedColorHex: String = "#0A84FF"

    let emojiOptions = ["👤", "🚀", "⚡", "🔥", "👑", "🦊", "💎", "🤖", "🎨", "🎮"]
    let colorOptions = ["#0A84FF", "#5856D6", "#AF52DE", "#FF2D55", "#FF9500", "#34C759", "#00C7BE"]

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Аватар")) {
                    HStack {
                        Spacer()
                        AvatarView(emoji: selectedEmoji, hexColor: selectedColorHex, size: 70, isOnline: true)
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                    Haptics.playImpact(style: .light)
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 26))
                                        .padding(6)
                                        .background(selectedEmoji == emoji ? Color.secondary.opacity(0.2) : Color.clear)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                    Haptics.playImpact(style: .light)
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Информация о собеседнике")) {
                    TextField("Имя (например, Михаил)", text: $name)
                    TextField("Username (например, @mikhail)", text: $username)
                }
            }
            .navigationTitle("Новый диалог")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.createNewChat(
                                name: name,
                                username: username.isEmpty ? "@user" : username,
                                emoji: selectedEmoji,
                                colorHex: selectedColorHex
                            )
                            Haptics.playNotification(type: .success)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
