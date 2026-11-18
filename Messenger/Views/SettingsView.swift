import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var biometricLock = false
    @State private var showCacheAlert = false

    public var body: some View {
        NavigationStack {
            List {
                // Profile header card
                Section {
                    HStack(spacing: 16) {
                        AvatarView(
                            emoji: viewModel.currentUser.avatarEmoji,
                            hexColor: viewModel.currentUser.avatarColorHex,
                            size: 64,
                            isOnline: true
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.currentUser.name)
                                .font(.system(size: 19, weight: .bold))

                            Text(viewModel.currentUser.username)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text(viewModel.currentUser.statusBio)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Sideloadly & Device Info Section
                Section(header: Text("Статус установки и сертификат")) {
                    HStack {
                        Label("Метод установки", systemImage: "arrow.down.app.fill")
                        Spacer()
                        Text("Sideloadly (Free Apple ID)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#0A84FF"))
                    }

                    HStack {
                        Label("Срок сертификата", systemImage: "calendar.badge.clock")
                        Spacer()
                        Text("7 дней (Авто-продление по Wi-Fi)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Архитектура", systemImage: "cpu")
                        Spacer()
                        Text("arm64-apple-ios (SwiftUI Native)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                // Server / Backend Sync
                Section(header: Text("Синхронизация и сервер")) {
                    HStack {
                        Label("WebSocket Сервер", systemImage: "network")
                        Spacer()
                    }
                    TextField("wss://example.com/chat", text: $viewModel.serverAddress)
                        .font(.system(size: 14, design: .monospaced))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Toggle(isOn: $viewModel.isConnectedToServer) {
                        Label("Подключить сервер", systemImage: "bolt.fill")
                    }
                    .tint(Color(hex: "#34C759"))
                }

                // Appearance & Theme
                Section(header: Text("Оформление")) {
                    Picker("Тема оформления", selection: $viewModel.currentThemeMode) {
                        Text("Системная").tag(0)
                        Text("Тёмная").tag(1)
                        Text("Светлая").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Notifications & Security
                Section(header: Text("Безопасность и уведомления")) {
                    Toggle("Push-уведомления", isOn: $notificationsEnabled)
                    Toggle("Звуковые эффекты", isOn: $soundEnabled)
                    Toggle("Вход по Face ID / Touch ID", isOn: $biometricLock)
                }

                // Storage
                Section(header: Text("Данные и память")) {
                    Button(role: .destructive) {
                        Haptics.playImpact(style: .medium)
                        showCacheAlert = true
                    } label: {
                        Label("Очистить кэш медиа (0.0 MB)", systemImage: "trash")
                    }
                }

                // About
                Section(footer: Text("Sideloadly Messenger v1.0.0 (Build 1)\nРазработано специально для установки через Sideloadly на iOS без App Store.")) {
                    HStack {
                        Label("Версия приложения", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .alert("Кэш очищен", isPresented: $showCacheAlert) {
                Button("ОК", role: .cancel) {}
            } message: {
                Text("Все временные файлы успешно удалены.")
            }
        }
    }
}
