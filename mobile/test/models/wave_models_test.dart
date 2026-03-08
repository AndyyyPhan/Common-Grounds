import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/wave_models.dart';

void main() {
  group('WaveRequest', () {
    test('should create WaveRequest with all fields', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        status: WaveStatus.pending,
        senderProfile: {'displayName': 'Alice', 'photoUrl': 'url1'},
        receiverProfile: {'displayName': 'Bob', 'photoUrl': 'url2'},
      );

      expect(wave.id, 'wave123');
      expect(wave.senderId, 'user1');
      expect(wave.receiverId, 'user2');
      expect(wave.status, WaveStatus.pending);
      expect(wave.senderProfile['displayName'], 'Alice');
      expect(wave.receiverProfile['displayName'], 'Bob');
    });

    test('should not be expired for recent wave', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(hours: 24)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.isExpired, false);
    });

    test('should be expired after 48 hours', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(hours: 49)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.isExpired, true);
    });

    test('should not be expired if already accepted', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(hours: 49)),
        status: WaveStatus.accepted,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.isExpired, false);
    });

    test('timeAgo should return "Just now" for recent wave', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.timeAgo, 'Just now');
    });

    test('timeAgo should return minutes ago', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.timeAgo, '30m ago');
    });

    test('timeAgo should return hours ago', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.timeAgo, '5h ago');
    });

    test('timeAgo should return days ago', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        status: WaveStatus.pending,
        senderProfile: {},
        receiverProfile: {},
      );

      expect(wave.timeAgo, '2d ago');
    });

    test('should convert to map correctly', () {
      final wave = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        status: WaveStatus.pending,
        senderProfile: {'displayName': 'Alice'},
        receiverProfile: {'displayName': 'Bob'},
      );

      final map = wave.toMap();

      expect(map['senderId'], 'user1');
      expect(map['receiverId'], 'user2');
      expect(map['status'], 'pending');
      expect(map['senderProfile']['displayName'], 'Alice');
      expect(map['receiverProfile']['displayName'], 'Bob');
    });

    test('should create from map correctly', () {
      final map = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'status': 'accepted',
        'respondedAt': Timestamp.fromDate(DateTime(2025, 1, 1, 13, 0)),
        'senderProfile': {'displayName': 'Alice'},
        'receiverProfile': {'displayName': 'Bob'},
      };

      final wave = WaveRequest.fromMap('wave123', map);

      expect(wave.id, 'wave123');
      expect(wave.senderId, 'user1');
      expect(wave.receiverId, 'user2');
      expect(wave.status, WaveStatus.accepted);
      expect(wave.senderProfile['displayName'], 'Alice');
      expect(wave.respondedAt, isNotNull);
    });

    test('should handle non-Timestamp timestamp gracefully', () {
      final map = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'timestamp': 'not-a-timestamp',
        'status': 'pending',
        'senderProfile': {'displayName': 'Alice'},
        'receiverProfile': {'displayName': 'Bob'},
      };

      final wave = WaveRequest.fromMap('wave123', map);

      // Should not crash, should fallback to DateTime.now()
      expect(wave.timestamp, isNotNull);
    });

    test('should handle null respondedAt', () {
      final map = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'status': 'pending',
        'respondedAt': null,
        'senderProfile': {},
        'receiverProfile': {},
      };

      final wave = WaveRequest.fromMap('wave123', map);
      expect(wave.respondedAt, isNull);
    });

    test('should handle missing profile maps gracefully', () {
      final map = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'status': 'pending',
      };

      final wave = WaveRequest.fromMap('wave123', map);

      expect(wave.senderProfile, isEmpty);
      expect(wave.receiverProfile, isEmpty);
    });

    test('should handle unknown status string gracefully', () {
      final map = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'status': 'unknown_status',
        'senderProfile': {},
        'receiverProfile': {},
      };

      final wave = WaveRequest.fromMap('wave123', map);

      // Should default to pending
      expect(wave.status, WaveStatus.pending);
    });

    test('copyWith should preserve unmodified fields', () {
      final original = WaveRequest(
        id: 'wave123',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        status: WaveStatus.pending,
        senderProfile: {'displayName': 'Alice'},
        receiverProfile: {'displayName': 'Bob'},
      );

      final updated = original.copyWith(status: WaveStatus.accepted);

      expect(updated.id, 'wave123');
      expect(updated.senderId, 'user1');
      expect(updated.status, WaveStatus.accepted);
    });
  });

  group('MutualMatch', () {
    test('should create MutualMatch with all fields', () {
      final match = MutualMatch(
        user1Id: 'user1',
        user2Id: 'user2',
        matchedAt: DateTime(2025, 1, 1, 12, 0),
        wave1Id: 'wave1',
        wave2Id: 'wave2',
        user1Profile: {'displayName': 'Alice'},
        user2Profile: {'displayName': 'Bob'},
      );

      expect(match.user1Id, 'user1');
      expect(match.user2Id, 'user2');
      expect(match.wave1Id, 'wave1');
      expect(match.wave2Id, 'wave2');
    });

    test('getOtherUserId should return correct user ID', () {
      final match = MutualMatch(
        user1Id: 'user1',
        user2Id: 'user2',
        matchedAt: DateTime.now(),
        wave1Id: 'wave1',
        wave2Id: 'wave2',
        user1Profile: {},
        user2Profile: {},
      );

      expect(match.getOtherUserId('user1'), 'user2');
      expect(match.getOtherUserId('user2'), 'user1');
    });

    test('getOtherUserProfile should return correct profile', () {
      final match = MutualMatch(
        user1Id: 'user1',
        user2Id: 'user2',
        matchedAt: DateTime.now(),
        wave1Id: 'wave1',
        wave2Id: 'wave2',
        user1Profile: {'displayName': 'Alice'},
        user2Profile: {'displayName': 'Bob'},
      );

      expect(match.getOtherUserProfile('user1')['displayName'], 'Bob');
      expect(match.getOtherUserProfile('user2')['displayName'], 'Alice');
    });

    test('should convert to map correctly', () {
      final match = MutualMatch(
        user1Id: 'user1',
        user2Id: 'user2',
        matchedAt: DateTime(2025, 1, 1, 12, 0),
        wave1Id: 'wave1',
        wave2Id: 'wave2',
        user1Profile: {'displayName': 'Alice'},
        user2Profile: {'displayName': 'Bob'},
      );

      final map = match.toMap();

      expect(map['user1Id'], 'user1');
      expect(map['user2Id'], 'user2');
      expect(map['wave1Id'], 'wave1');
      expect(map['wave2Id'], 'wave2');
      expect(map['user1Profile']['displayName'], 'Alice');
    });

    test('should create from map correctly', () {
      final map = {
        'user1Id': 'user1',
        'user2Id': 'user2',
        'matchedAt': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'wave1Id': 'wave1',
        'wave2Id': 'wave2',
        'user1Profile': {'displayName': 'Alice'},
        'user2Profile': {'displayName': 'Bob'},
      };

      final match = MutualMatch.fromMap(map);

      expect(match.user1Id, 'user1');
      expect(match.user2Id, 'user2');
      expect(match.wave1Id, 'wave1');
      expect(match.user1Profile['displayName'], 'Alice');
    });

    test('should handle non-Timestamp matchedAt gracefully', () {
      final map = {
        'user1Id': 'user1',
        'user2Id': 'user2',
        'matchedAt': 'not-a-timestamp',
        'wave1Id': 'wave1',
        'wave2Id': 'wave2',
        'user1Profile': {'displayName': 'Alice'},
        'user2Profile': {'displayName': 'Bob'},
      };

      final match = MutualMatch.fromMap(map);

      // Should not crash, should fallback to DateTime.now()
      expect(match.matchedAt, isNotNull);
    });

    test('should handle missing profile maps gracefully', () {
      final map = {
        'user1Id': 'user1',
        'user2Id': 'user2',
        'matchedAt': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
        'wave1Id': 'wave1',
        'wave2Id': 'wave2',
      };

      final match = MutualMatch.fromMap(map);

      expect(match.user1Profile, isEmpty);
      expect(match.user2Profile, isEmpty);
    });

    test('toMap and fromMap should round-trip', () {
      final original = MutualMatch(
        user1Id: 'user1',
        user2Id: 'user2',
        matchedAt: DateTime(2025, 6, 1),
        wave1Id: 'wave1',
        wave2Id: 'wave2',
        user1Profile: {'displayName': 'Alice'},
        user2Profile: {'displayName': 'Bob'},
      );

      final map = original.toMap();
      final restored = MutualMatch.fromMap(map);

      expect(restored.user1Id, original.user1Id);
      expect(restored.user2Id, original.user2Id);
      expect(restored.wave1Id, original.wave1Id);
      expect(restored.wave2Id, original.wave2Id);
    });
  });
}
