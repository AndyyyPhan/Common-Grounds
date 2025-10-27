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
  });
}
