class UserProfile {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? classYear; // e.g., "2026"
  final String? major; // e.g., "CS"
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.classYear,
    this.major,
    this.interests = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isComplete =>
      interests.isNotEmpty; // tweak your own “completion” rule

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'classYear': classYear,
    'major': major,
    'interests': interests,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] as String,
    displayName: m['displayName'] as String?,
    photoUrl: m['photoUrl'] as String?,
    bio: m['bio'] as String?,
    classYear: m['classYear'] as String?,
    major: m['major'] as String?,
    interests: (m['interests'] as List?)?.cast<String>() ?? const [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int? ?? 0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int? ?? 0),
  );
}
