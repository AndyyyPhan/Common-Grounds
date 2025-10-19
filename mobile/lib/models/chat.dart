import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatStatus {
  active,
  archived,
  blocked,
}

class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageSenderId;
  final ChatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool>? readStatus; // User ID -> has read latest message
  final Map<String, DateTime>? lastSeen; // User ID -> last seen timestamp

  const Chat({
    required this.id,
    required this.participants,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageTimestamp,
    this.lastMessageSenderId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.readStatus,
    this.lastSeen,
  });

  bool get isActive => status == ChatStatus.active;
  bool get isArchived => status == ChatStatus.archived;
  bool get isBlocked => status == ChatStatus.blocked;

  /// Get the other participant's ID
  String? getOtherParticipant(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  /// Check if user has read the latest message
  bool hasUserRead(String userId) {
    return readStatus?[userId] ?? false;
  }

  /// Get user's last seen timestamp
  DateTime? getUserLastSeen(String userId) {
    return lastSeen?[userId];
  }

  /// Check if this is a new chat (no messages yet)
  bool get isNewChat => lastMessageId == null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'participants': participants,
    'lastMessageId': lastMessageId,
    'lastMessageContent': lastMessageContent,
    'lastMessageTimestamp': lastMessageTimestamp != null 
        ? Timestamp.fromDate(lastMessageTimestamp!)
        : null,
    'lastMessageSenderId': lastMessageSenderId,
    'status': status.toString(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'readStatus': readStatus,
    'lastSeen': lastSeen?.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
  };

  factory Chat.fromMap(Map<String, dynamic> map) => Chat(
    id: map['id'] as String,
    participants: (map['participants'] as List).cast<String>(),
    lastMessageId: map['lastMessageId'] as String?,
    lastMessageContent: map['lastMessageContent'] as String?,
    lastMessageTimestamp: map['lastMessageTimestamp'] != null
        ? (map['lastMessageTimestamp'] as Timestamp).toDate()
        : null,
    lastMessageSenderId: map['lastMessageSenderId'] as String?,
    status: _parseChatStatus(map['status'] as String),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    readStatus: map['readStatus'] != null 
        ? Map<String, bool>.from(map['readStatus'] as Map)
        : null,
    lastSeen: map['lastSeen'] != null
        ? (map['lastSeen'] as Map).map((key, value) => 
            MapEntry(key as String, (value as Timestamp).toDate()))
        : null,
  );

  static ChatStatus _parseChatStatus(String status) {
    switch (status) {
      case 'ChatStatus.active':
        return ChatStatus.active;
      case 'ChatStatus.archived':
        return ChatStatus.archived;
      case 'ChatStatus.blocked':
        return ChatStatus.blocked;
      default:
        return ChatStatus.active;
    }
  }

  Chat copyWith({
    String? id,
    List<String>? participants,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderId,
    ChatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? readStatus,
    Map<String, DateTime>? lastSeen,
  }) => Chat(
    id: id ?? this.id,
    participants: participants ?? this.participants,
    lastMessageId: lastMessageId ?? this.lastMessageId,
    lastMessageContent: lastMessageContent ?? this.lastMessageContent,
    lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
    lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    readStatus: readStatus ?? this.readStatus,
    lastSeen: lastSeen ?? this.lastSeen,
  );
}
