import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus {
  pending,
  mutual,
  declined,
  expired,
}

class Match {
  final String id;
  final List<String> participants;
  final List<String> sharedInterests;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool>? responses; // User ID -> response (true for wave, false for decline)

  const Match({
    required this.id,
    required this.participants,
    required this.sharedInterests,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.responses,
  });

  bool get isMutual => status == MatchStatus.mutual;
  bool get isPending => status == MatchStatus.pending;
  bool get isDeclined => status == MatchStatus.declined;
  bool get isExpired => status == MatchStatus.expired;

  /// Get the other participant's ID
  String? getOtherParticipant(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  /// Check if user has responded to this match
  bool hasUserResponded(String userId) {
    return responses?[userId] != null;
  }

  /// Get user's response
  bool? getUserResponse(String userId) {
    return responses?[userId];
  }

  /// Check if both users have waved (mutual interest)
  bool get isMutualWave {
    if (responses == null || responses!.length != 2) return false;
    return responses!.values.every((response) => response == true);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'participants': participants,
    'sharedInterests': sharedInterests,
    'status': status.toString(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'responses': responses,
  };

  factory Match.fromMap(Map<String, dynamic> map) => Match(
    id: map['id'] as String,
    participants: (map['participants'] as List).cast<String>(),
    sharedInterests: (map['sharedInterests'] as List).cast<String>(),
    status: _parseMatchStatus(map['status'] as String),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    responses: map['responses'] != null 
        ? Map<String, bool>.from(map['responses'] as Map)
        : null,
  );

  static MatchStatus _parseMatchStatus(String status) {
    switch (status) {
      case 'MatchStatus.pending':
        return MatchStatus.pending;
      case 'MatchStatus.mutual':
        return MatchStatus.mutual;
      case 'MatchStatus.declined':
        return MatchStatus.declined;
      case 'MatchStatus.expired':
        return MatchStatus.expired;
      default:
        return MatchStatus.pending;
    }
  }

  Match copyWith({
    String? id,
    List<String>? participants,
    List<String>? sharedInterests,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? responses,
  }) => Match(
    id: id ?? this.id,
    participants: participants ?? this.participants,
    sharedInterests: sharedInterests ?? this.sharedInterests,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    responses: responses ?? this.responses,
  );
}
