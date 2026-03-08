import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message in a conversation
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final int
  sequence; // Sequence number for ordering messages with identical timestamps
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.sequence = 0,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'sequence': sequence,
    'isRead': isRead,
  };

  factory Message.fromMap(String id, Map<String, dynamic> m) {
    // Handle server timestamp (may be null if not yet resolved)
    // IMPORTANT: Server timestamps are assigned by Firebase server, not device
    DateTime timestamp;
    final timestampValue = m['timestamp'];
    if (timestampValue == null) {
      // Server timestamp not yet resolved - use a very recent past time
      // This ensures messages appear at the end until timestamp resolves
      // The client-side sort will handle ordering correctly
      timestamp = DateTime.now().subtract(const Duration(seconds: 1));
    } else if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else {
      // Unexpected type - use current time as last resort
      // Client-side sort will correct any ordering issues
      timestamp = DateTime.now();
    }

    return Message(
      id: id,
      conversationId: m['conversationId'] as String,
      senderId: m['senderId'] as String,
      text: m['text'] as String,
      timestamp: timestamp,
      sequence: m['sequence'] as int? ?? 0,
      isRead: m['isRead'] as bool? ?? false,
    );
  }
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

    DateTime createdAt;
    final createdAtValue = m['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else {
      createdAt = DateTime.now();
    }

    DateTime? lastMessageTime;
    final lastMessageTimeValue = m['lastMessageTime'];
    if (lastMessageTimeValue is Timestamp) {
      lastMessageTime = lastMessageTimeValue.toDate();
    }

    return Conversation(
      id: id,
      participantIds: (m['participantIds'] as List?)?.cast<String>() ?? [],
      participantProfiles: Map<String, dynamic>.from(
        m['participantProfiles'] as Map? ?? {},
      ),
      lastMessage: m['lastMessage'] as String?,
      lastMessageTime: lastMessageTime,
      lastMessageSenderId: m['lastMessageSenderId'] as String?,
      unreadCount: unreadCount,
      createdAt: createdAt,
    );
  }
}
