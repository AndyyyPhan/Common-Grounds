import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import 'profile_service.dart';

class MessagingService {
  MessagingService._();
  static final instance = MessagingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProfileService _profileService = ProfileService.instance;

  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';
  static const String _userChatsCollection = 'user_chats';

  StreamController<Message>? _messageController;
  StreamController<Chat>? _chatController;

  Stream<Message> get messageStream {
    _messageController ??= StreamController<Message>.broadcast();
    return _messageController!.stream;
  }

  Stream<Chat> get chatStream {
    _chatController ??= StreamController<Chat>.broadcast();
    return _chatController!.stream;
  }

  /// Create a new chat between two users
  Future<Chat> createChat(String userId1, String userId2) async {
    try {
      // Check if chat already exists
      final existingChat = await _getExistingChat(userId1, userId2);
      if (existingChat != null) {
        return existingChat;
      }

      final chatId = _generateChatId();
      final now = DateTime.now();

      final chat = Chat(
        id: chatId,
        participants: [userId1, userId2],
        status: ChatStatus.active,
        createdAt: now,
        updatedAt: now,
        readStatus: {userId1: true, userId2: false},
        lastSeen: {userId1: now, userId2: now},
      );

      // Create chat document
      await _db.collection(_chatsCollection).doc(chatId).set(chat.toMap());

      // Add to user chats
      await _addToUserChats(userId1, chatId);
      await _addToUserChats(userId2, chatId);

      // Send system message
      await _sendSystemMessage(chatId, 'Chat started! Say hello 👋');

      _chatController?.add(chat);
      return chat;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  /// Get existing chat between two users
  Future<Chat?> _getExistingChat(String userId1, String userId2) async {
    try {
      final query = await _db
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in query.docs) {
        final chat = Chat.fromMap(doc.data());
        if (chat.participants.contains(userId2)) {
          return chat;
        }
      }
      return null;
    } catch (e) {
      print('Error getting existing chat: $e');
      return null;
    }
  }

  /// Add chat to user's chat list
  Future<void> _addToUserChats(String userId, String chatId) async {
    try {
      await _db.collection(_userChatsCollection).doc(userId).set({
        'chats': FieldValue.arrayUnion([chatId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding to user chats: $e');
    }
  }

  /// Send a text message
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _generateMessageId();
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: MessageType.text,
        timestamp: now,
        replyToMessageId: replyToMessageId,
      );

      // Save message
      await _db.collection(_messagesCollection).doc(messageId).set(message.toMap());

      // Update chat with last message info
      await _updateChatLastMessage(chatId, message);

      // Update read status
      await _updateReadStatus(chatId, senderId, true);

      _messageController?.add(message);
      return message;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Send a system message
  Future<Message> _sendSystemMessage(String chatId, String content) async {
    try {
      final messageId = _generateMessageId();
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: 'system',
        content: content,
        type: MessageType.system,
        timestamp: now,
      );

      await _db.collection(_messagesCollection).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      print('Error sending system message: $e');
      rethrow;
    }
  }

  /// Update chat with last message info
  Future<void> _updateChatLastMessage(String chatId, Message message) async {
    try {
      await _db.collection(_chatsCollection).doc(chatId).update({
        'lastMessageId': message.id,
        'lastMessageContent': message.content,
        'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating chat last message: $e');
    }
  }

  /// Get user's chats
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final userChatsDoc = await _db.collection(_userChatsCollection).doc(userId).get();
      if (!userChatsDoc.exists) return [];

      final chatIds = List<String>.from(userChatsDoc.data()?['chats'] ?? []);
      if (chatIds.isEmpty) return [];

      final chats = <Chat>[];
      for (final chatId in chatIds) {
        final chatDoc = await _db.collection(_chatsCollection).doc(chatId).get();
        if (chatDoc.exists) {
          chats.add(Chat.fromMap(chatDoc.data()!));
        }
      }

      // Sort by last message timestamp
      chats.sort((a, b) {
        final aTime = a.lastMessageTimestamp ?? a.createdAt;
        final bTime = b.lastMessageTimestamp ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return chats;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  /// Stream user's chats
  Stream<List<Chat>> watchUserChats(String userId) {
    return _db.collection(_userChatsCollection).doc(userId).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) return <Chat>[];

      final chatIds = List<String>.from(snapshot.data()?['chats'] ?? []);
      if (chatIds.isEmpty) return <Chat>[];

      final chats = <Chat>[];
      for (final chatId in chatIds) {
        final chatDoc = await _db.collection(_chatsCollection).doc(chatId).get();
        if (chatDoc.exists) {
          chats.add(Chat.fromMap(chatDoc.data()!));
        }
      }

      // Sort by last message timestamp
      chats.sort((a, b) {
        final aTime = a.lastMessageTimestamp ?? a.createdAt;
        final bTime = b.lastMessageTimestamp ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  /// Get chat messages
  Future<List<Message>> getChatMessages(String chatId, {int limit = 50}) async {
    try {
      final query = await _db
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final messages = query.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  /// Stream chat messages
  Stream<List<Message>> watchChatMessages(String chatId, {int limit = 50}) {
    return _db
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Update chat read status
      await _db.collection(_chatsCollection).doc(chatId).update({
        'readStatus.$userId': true,
        'lastSeen.$userId': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update individual message read status
      final messagesQuery = await _db
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _db.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Update read status for a specific user
  Future<void> _updateReadStatus(String chatId, String userId, bool hasRead) async {
    try {
      await _db.collection(_chatsCollection).doc(chatId).update({
        'readStatus.$userId': hasRead,
        'lastSeen.$userId': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating read status: $e');
    }
  }

  /// Archive chat
  Future<void> archiveChat(String chatId, String userId) async {
    try {
      await _db.collection(_chatsCollection).doc(chatId).update({
        'status': ChatStatus.archived.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error archiving chat: $e');
    }
  }

  /// Block user in chat
  Future<void> blockUser(String chatId, String userId) async {
    try {
      await _db.collection(_chatsCollection).doc(chatId).update({
        'status': ChatStatus.blocked.toString(),
        'blockedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  /// Get chat with user profile info
  Future<ChatWithProfile?> getChatWithProfile(String chatId, String currentUserId) async {
    try {
      final chatDoc = await _db.collection(_chatsCollection).doc(chatId).get();
      if (!chatDoc.exists) return null;

      final chat = Chat.fromMap(chatDoc.data()!);
      final otherUserId = chat.getOtherParticipant(currentUserId);
      if (otherUserId == null) return null;

      final otherUserProfile = await _profileService.getProfile(otherUserId);
      if (otherUserProfile == null) return null;

      return ChatWithProfile(chat: chat, otherUser: otherUserProfile);
    } catch (e) {
      print('Error getting chat with profile: $e');
      return null;
    }
  }

  /// Generate unique chat ID
  String _generateChatId() {
    return 'chat_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Dispose resources
  void dispose() {
    _messageController?.close();
    _chatController?.close();
  }
}

/// Helper class to combine chat with user profile
class ChatWithProfile {
  final Chat chat;
  final UserProfile otherUser;

  const ChatWithProfile({
    required this.chat,
    required this.otherUser,
  });
}
