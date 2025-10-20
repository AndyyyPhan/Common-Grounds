import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message in a conversation
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
  };

  factory Message.fromMap(String id, Map<String, dynamic> m) => Message(
    id: id,
    conversationId: m['conversationId'] as String,
    senderId: m['senderId'] as String,
    text: m['text'] as String,
    timestamp: (m['timestamp'] as Timestamp).toDate(),
    isRead: m['isRead'] as bool? ?? false,
  );
}

/// Represents a conversation between two users
class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, dynamic>
  participantProfiles; // uid -> {displayName, photoUrl}
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // uid -> count
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantProfiles,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
  });

  /// Get the other participant's ID (not the current user)
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  /// Get the other participant's display name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantProfiles[otherId]?['displayName'] as String? ??
        'Unknown User';
  }

  /// Get the other participant's photo URL
  String? getOtherParticipantPhoto(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantProfiles[otherId]?['photoUrl'] as String?;
  }

  /// Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  Map<String, dynamic> toMap() => {
    'participantIds': participantIds,
    'participantProfiles': participantProfiles,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime != null
        ? Timestamp.fromDate(lastMessageTime!)
        : null,
    'lastMessageSenderId': lastMessageSenderId,
    'unreadCount': unreadCount,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Conversation.fromMap(String id, Map<String, dynamic> m) {
    final rawUnreadCount = m['unreadCount'] as Map? ?? {};
    final unreadCount = <String, int>{};
    rawUnreadCount.forEach((key, value) {
      unreadCount[key.toString()] = (value as num).toInt();
    });

    return Conversation(
      id: id,
      participantIds: (m['participantIds'] as List).cast<String>(),
      participantProfiles: Map<String, dynamic>.from(
        m['participantProfiles'] as Map? ?? {},
      ),
      lastMessage: m['lastMessage'] as String?,
      lastMessageTime: m['lastMessageTime'] != null
          ? (m['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: m['lastMessageSenderId'] as String?,
      unreadCount: unreadCount,
      createdAt: (m['createdAt'] as Timestamp).toDate(),
    );
  }
}
