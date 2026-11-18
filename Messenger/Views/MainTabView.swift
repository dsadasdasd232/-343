import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            ChatsListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("Чаты")
                }
                .badge(viewModel.totalUnreadCount > 0 ? viewModel.totalUnreadCount : 0)
                .tag(0)

            NavigationStack {
                CallsPlaceholderView()
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "phone.fill" : "phone")
                Text("Звонки")
            }
            .tag(1)

            NavigationStack {
                ContactsListView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "person.2.fill" : "person.2")
                Text("Контакты")
            }
            .tag(2)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Настройки")
                }
                .tag(3)
        }
        .tint(Color(hex: "#0A84FF"))
        .preferredColorScheme(viewModel.currentThemeMode == 1 ? .dark : (viewModel.currentThemeMode == 2 ? .light : nil))
    }
}

// Contacts View
struct ContactsListView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        List {
            ForEach(viewModel.chats) { chat in
                NavigationLink(destination: ChatDetailView(chatId: chat.id, viewModel: viewModel)) {
                    HStack(spacing: 14) {
                        AvatarView(
                            emoji: chat.partner.avatarEmoji,
                            hexColor: chat.partner.avatarColorHex,
                            size: 44,
                            isOnline: chat.partner.isOnline
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(chat.partner.name)
                                .font(.system(size: 16, weight: .semibold))

                            Text(chat.partner.username)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Контакты")
    }
}

// Calls Placeholder
struct CallsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#0A84FF").opacity(0.8))

            Text("Нет недавних звонков")
                .font(.system(size: 20, weight: .semibold))

            Text("Здесь будут отображаться ваши голосовые и видеозвонки.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Звонки")
    }
}
