// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
  });
  factory AppUser.fromFirebaseUser(User u) => AppUser(
    uid: u.uid,
    email: u.email,
    displayName: u.displayName,
    photoUrl: u.photoURL,
    emailVerified: u.emailVerified,
  );
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  /// OPTIONAL: call once on app start (e.g., in main after Firebase.initializeApp).
  /// If you see a runtime error asking for serverClientId on Android,
  /// pass the Web client ID here: initialize(serverClientId: 'xxx.apps.googleusercontent.com');
  bool _initialized = false;
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  Stream<AppUser?> get user$ => _auth.authStateChanges().map(
    (u) => u == null ? null : AppUser.fromFirebaseUser(u),
  );

  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser.fromFirebaseUser(u);
  }

  /// Google sign-in using the v7 flow.
  Future<AppUser> signInWithGoogle() async {
    // Ensure plugin is ready (safe to call multiple times)
    await initialize();

    // Try lightweight auth; if it doesn't sign in, fall back to full authenticate().
    await GoogleSignIn.instance.attemptLightweightAuthentication();

    GoogleSignInAccount? gUser;
    // If the platform supports the built-in UI, use it.
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      gUser = await GoogleSignIn.instance.authenticate();
    } else {
      // (Primarily for web) you’d render the official button from google_sign_in_web.
      // For your Android/iOS app this branch won’t be hit.
      throw Exception(
        'Platform requires platform-specific Google button flow.',
      );
    }

    // Get tokens, exchange for Firebase credential (idToken is sufficient).
    final gAuth = gUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: gAuth.idToken);
    final cred = await _auth.signInWithCredential(credential);

    final user = cred.user;
    if (user == null) throw Exception('Firebase sign-in failed.');
    return AppUser.fromFirebaseUser(user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}
