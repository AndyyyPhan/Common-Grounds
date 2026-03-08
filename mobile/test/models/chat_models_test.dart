import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/chat_models.dart';

void main() {
  group('Message', () {
    test('should create Message from map with all fields', () {
      final map = {
        'conversationId': 'conv1',
        'senderId': 'user1',
        'text': 'Hello!',
        'timestamp': Timestamp.fromDate(DateTime(2025, 6, 1, 12, 0)),
        'sequence': 5,
        'isRead': true,
      };

      final message = Message.fromMap('msg1', map);

      expect(message.id, 'msg1');
      expect(message.conversationId, 'conv1');
      expect(message.senderId, 'user1');
      expect(message.text, 'Hello!');
      expect(message.sequence, 5);
      expect(message.isRead, true);
    });

    test('should handle null timestamp gracefully', () {
      final map = {
        'conversationId': 'conv1',
        'senderId': 'user1',
        'text': 'Hello!',
        'timestamp': null,
        'sequence': 1,
        'isRead': false,
      };

      final message = Message.fromMap('msg1', map);

      expect(message.timestamp, isNotNull);
    });

    test('should default sequence to 0 when missing', () {
      final map = {
        'conversationId': 'conv1',
        'senderId': 'user1',
        'text': 'Hello!',
        'timestamp': Timestamp.fromDate(DateTime(2025, 6, 1)),
      };

      final message = Message.fromMap('msg1', map);

      expect(message.sequence, 0);
      expect(message.isRead, false);
    });

    test('should convert to map correctly', () {
      final message = Message(
        id: 'msg1',
        conversationId: 'conv1',
        senderId: 'user1',
        text: 'Hello!',
        timestamp: DateTime(2025, 6, 1, 12, 0),
        sequence: 3,
        isRead: false,
      );

      final map = message.toMap();

      expect(map['conversationId'], 'conv1');
      expect(map['senderId'], 'user1');
      expect(map['text'], 'Hello!');
      expect(map['sequence'], 3);
      expect(map['isRead'], false);
    });
  });

  group('Conversation', () {
    test('should create Conversation from map with all fields', () {
      final map = {
        'participantIds': ['user1', 'user2'],
        'participantProfiles': {
          'user1': {'displayName': 'Alice', 'photoUrl': 'url1'},
          'user2': {'displayName': 'Bob', 'photoUrl': 'url2'},
        },
        'lastMessage': 'Hey!',
        'lastMessageTime': Timestamp.fromDate(DateTime(2025, 6, 1, 12, 0)),
        'lastMessageSenderId': 'user1',
        'unreadCount': {'user1': 0, 'user2': 3},
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final conv = Conversation.fromMap('conv1', map);

      expect(conv.id, 'conv1');
      expect(conv.participantIds, ['user1', 'user2']);
      expect(conv.lastMessage, 'Hey!');
      expect(conv.lastMessageSenderId, 'user1');
      expect(conv.getUnreadCountForUser('user2'), 3);
      expect(conv.getUnreadCountForUser('user1'), 0);
    });

    test('should handle missing participantIds gracefully', () {
      final map = {
        'participantProfiles': {},
        'unreadCount': {},
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final conv = Conversation.fromMap('conv1', map);

      expect(conv.participantIds, isEmpty);
    });

    test('should handle missing lastMessageTime', () {
      final map = {
        'participantIds': ['user1', 'user2'],
        'participantProfiles': {},
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': {},
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final conv = Conversation.fromMap('conv1', map);

      expect(conv.lastMessageTime, isNull);
      expect(conv.lastMessage, isNull);
    });

    test('should handle non-Timestamp createdAt gracefully', () {
      final map = {
        'participantIds': ['user1', 'user2'],
        'participantProfiles': {},
        'unreadCount': {},
        'createdAt': 'not-a-timestamp',
      };

      final conv = Conversation.fromMap('conv1', map);

      // Should fallback to DateTime.now() instead of crashing
      expect(conv.createdAt, isNotNull);
    });

    test('getOtherParticipantId should return the other user', () {
      final conv = Conversation(
        id: 'conv1',
        participantIds: ['user1', 'user2'],
        participantProfiles: {
          'user1': {'displayName': 'Alice'},
          'user2': {'displayName': 'Bob'},
        },
        unreadCount: {},
        createdAt: DateTime.now(),
      );

      expect(conv.getOtherParticipantId('user1'), 'user2');
      expect(conv.getOtherParticipantId('user2'), 'user1');
    });

    test('getOtherParticipantName should return correct name', () {
      final conv = Conversation(
        id: 'conv1',
        participantIds: ['user1', 'user2'],
        participantProfiles: {
          'user1': {'displayName': 'Alice'},
          'user2': {'displayName': 'Bob'},
        },
        unreadCount: {},
        createdAt: DateTime.now(),
      );

      expect(conv.getOtherParticipantName('user1'), 'Bob');
      expect(conv.getOtherParticipantName('user2'), 'Alice');
    });

    test(
      'getOtherParticipantName should return Unknown for missing profile',
      () {
        final conv = Conversation(
          id: 'conv1',
          participantIds: ['user1', 'user2'],
          participantProfiles: {},
          unreadCount: {},
          createdAt: DateTime.now(),
        );

        expect(conv.getOtherParticipantName('user1'), 'Unknown User');
      },
    );

    test('getUnreadCountForUser should return 0 for unknown user', () {
      final conv = Conversation(
        id: 'conv1',
        participantIds: ['user1', 'user2'],
        participantProfiles: {},
        unreadCount: {'user1': 5},
        createdAt: DateTime.now(),
      );

      expect(conv.getUnreadCountForUser('user1'), 5);
      expect(conv.getUnreadCountForUser('user3'), 0);
    });

    test('toMap should produce valid map', () {
      final now = DateTime(2025, 6, 1);
      final conv = Conversation(
        id: 'conv1',
        participantIds: ['user1', 'user2'],
        participantProfiles: {
          'user1': {'displayName': 'Alice'},
        },
        lastMessage: 'Hi',
        lastMessageTime: now,
        lastMessageSenderId: 'user1',
        unreadCount: {'user1': 0, 'user2': 1},
        createdAt: now,
      );

      final map = conv.toMap();

      expect(map['participantIds'], ['user1', 'user2']);
      expect(map['lastMessage'], 'Hi');
      expect(map['lastMessageSenderId'], 'user1');
      expect(map['unreadCount']['user2'], 1);
    });
  });
}
