import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  system,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToMessageId;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.replyToMessageId,
  });

  bool get isText => type == MessageType.text;
  bool get isSystem => type == MessageType.system;

  Map<String, dynamic> toMap() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'content': content,
    'type': type.toString(),
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'replyToMessageId': replyToMessageId,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] as String,
    chatId: map['chatId'] as String,
    senderId: map['senderId'] as String,
    content: map['content'] as String,
    type: _parseMessageType(map['type'] as String),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    isRead: map['isRead'] as bool? ?? false,
    replyToMessageId: map['replyToMessageId'] as String?,
  );

  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'MessageType.text':
        return MessageType.text;
      case 'MessageType.system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? replyToMessageId,
  }) => Message(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    type: type ?? this.type,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
    replyToMessageId: replyToMessageId ?? this.replyToMessageId,
  );
}
