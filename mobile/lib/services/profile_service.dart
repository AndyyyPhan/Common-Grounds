import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data()!);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map(
      (s) => s.data() == null ? null : UserProfile.fromMap(s.data()!),
    );
  }

  Future<void> upsertProfile(UserProfile p) async {
    final now = DateTime.now();
    final payload = p.toMap()
      ..['updatedAt'] = now.millisecondsSinceEpoch
      ..putIfAbsent('createdAt', () => now.millisecondsSinceEpoch);
    await _doc(p.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> ensureDoc(
    String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    final ref = _doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final now = DateTime.now();
      await ref.set({
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'bio': null,
        'classYear': null,
        'major': null,
        'interests': <String>[],
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    }
  }
}
