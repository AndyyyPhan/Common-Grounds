import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a wave request
enum WaveStatus {
  pending, // Wave sent, waiting for response
  accepted, // Wave accepted by receiver
  declined, // Wave declined by receiver
  expired, // Wave expired (after 48 hours)
}

/// Represents a wave request between two users
///
/// When both users wave at each other (mutual wave), they can start messaging.
class WaveRequest {
  final String id;
  final String senderId; // User who sent the wave
  final String receiverId; // User who received the wave
  final DateTime timestamp; // When the wave was sent
  final WaveStatus status; // Current status of the wave
  final DateTime? respondedAt; // When the wave was accepted/declined

  // Metadata for display purposes
  final Map<String, dynamic> senderProfile; // {displayName, photoUrl}
  final Map<String, dynamic> receiverProfile; // {displayName, photoUrl}

  const WaveRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.status,
    this.respondedAt,
    required this.senderProfile,
    required this.receiverProfile,
  });

  /// Check if this wave has expired (48 hours old and still pending)
  bool get isExpired {
    if (status != WaveStatus.pending) return false;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours >= 48;
  }

  /// Get the formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'timestamp': Timestamp.fromDate(timestamp),
    'status': status.name,
    'respondedAt': respondedAt != null
        ? Timestamp.fromDate(respondedAt!)
        : null,
    'senderProfile': senderProfile,
    'receiverProfile': receiverProfile,
  };

  /// Create from Firestore map
  factory WaveRequest.fromMap(String id, Map<String, dynamic> map) {
    return WaveRequest(
      id: id,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: WaveStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WaveStatus.pending,
      ),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
      senderProfile: Map<String, dynamic>.from(map['senderProfile'] as Map),
      receiverProfile: Map<String, dynamic>.from(map['receiverProfile'] as Map),
    );
  }

  /// Create a copy with updated fields
  WaveRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    DateTime? timestamp,
    WaveStatus? status,
    DateTime? respondedAt,
    Map<String, dynamic>? senderProfile,
    Map<String, dynamic>? receiverProfile,
  }) {
    return WaveRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      senderProfile: senderProfile ?? this.senderProfile,
      receiverProfile: receiverProfile ?? this.receiverProfile,
    );
  }
}

/// Represents a mutual match between two users (both waved at each other)
class MutualMatch {
  final String user1Id;
  final String user2Id;
  final DateTime matchedAt;
  final String wave1Id; // Wave from user1 to user2
  final String wave2Id; // Wave from user2 to user1

  // Profiles for display
  final Map<String, dynamic> user1Profile;
  final Map<String, dynamic> user2Profile;

  const MutualMatch({
    required this.user1Id,
    required this.user2Id,
    required this.matchedAt,
    required this.wave1Id,
    required this.wave2Id,
    required this.user1Profile,
    required this.user2Profile,
  });

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Get the other user's profile
  Map<String, dynamic> getOtherUserProfile(String currentUserId) {
    return currentUserId == user1Id ? user2Profile : user1Profile;
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'user1Id': user1Id,
    'user2Id': user2Id,
    'matchedAt': Timestamp.fromDate(matchedAt),
    'wave1Id': wave1Id,
    'wave2Id': wave2Id,
    'user1Profile': user1Profile,
    'user2Profile': user2Profile,
  };

  /// Create from Firestore map
  factory MutualMatch.fromMap(Map<String, dynamic> map) {
    return MutualMatch(
      user1Id: map['user1Id'] as String,
      user2Id: map['user2Id'] as String,
      matchedAt: (map['matchedAt'] as Timestamp).toDate(),
      wave1Id: map['wave1Id'] as String,
      wave2Id: map['wave2Id'] as String,
      user1Profile: Map<String, dynamic>.from(map['user1Profile'] as Map),
      user2Profile: Map<String, dynamic>.from(map['user2Profile'] as Map),
    );
  }
}
