import Foundation
import SwiftUI

public enum MessageDeliveryStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
}

public enum MessageType: String, Codable {
    case text
    case image
    case audio
}

public struct MessageReaction: Identifiable, Codable, Equatable {
    public var id = UUID()
    public var emoji: String
    public var count: Int
    public var userReacted: Bool
}

public struct Message: Identifiable, Codable, Equatable {
    public var id: UUID
    public var senderId: UUID
    public var text: String
    public var timestamp: Date
    public var isFromCurrentUser: Bool
    public var status: MessageDeliveryStatus
    public var type: MessageType
    public var mediaUrl: String?
    public var audioDuration: TimeInterval?
    public var reactions: [MessageReaction]
    public var replyToMessageId: UUID?

    public init(
        id: UUID = UUID(),
        senderId: UUID,
        text: String,
        timestamp: Date = Date(),
        isFromCurrentUser: Bool,
        status: MessageDeliveryStatus = .read,
        type: MessageType = .text,
        mediaUrl: String? = nil,
        audioDuration: TimeInterval? = nil,
        reactions: [MessageReaction] = [],
        replyToMessageId: UUID? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.isFromCurrentUser = isFromCurrentUser
        self.status = status
        self.type = type
        self.mediaUrl = mediaUrl
        self.audioDuration = audioDuration
        self.reactions = reactions
        self.replyToMessageId = replyToMessageId
    }
}

public struct UserProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var username: String
    public var avatarColorHex: String
    public var avatarEmoji: String
    public var statusBio: String
    public var isOnline: Bool
    public var lastSeen: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        username: String,
        avatarColorHex: String = "#0A84FF",
        avatarEmoji: String = "👤",
        statusBio: String = "Hey there! I am using Messenger.",
        isOnline: Bool = false,
        lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.avatarColorHex = avatarColorHex
        self.avatarEmoji = avatarEmoji
        self.statusBio = statusBio
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
}

public struct Chat: Identifiable, Codable, Equatable {
    public var id: UUID
    public var partner: UserProfile
    public var messages: [Message]
    public var isPinned: Bool
    public var isMuted: Bool
    public var unreadCount: Int
    public var isTyping: Bool

    public var lastMessage: Message? {
        messages.last
    }

    public init(
        id: UUID = UUID(),
        partner: UserProfile,
        messages: [Message] = [],
        isPinned: Bool = false,
        isMuted: Bool = false,
        unreadCount: Int = 0,
        isTyping: Bool = false
    ) {
        self.id = id
        self.partner = partner
        self.messages = messages
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.unreadCount = unreadCount
        self.isTyping = isTyping
    }
}
