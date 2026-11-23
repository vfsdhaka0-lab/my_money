
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

import 'backup_config.dart';

class GoogleDriveAuth {
  GoogleDriveAuth._();

  static final GoogleDriveAuth instance = GoogleDriveAuth._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _initialized = false;

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initialize() async {
    if (_initialized) return;

    // Android reads the Web Client ID from google-services.json.
    await _googleSignIn.initialize();

    _initialized = true;
  }

  Future<GoogleSignInAccount?> tryRestoreSignIn() async {
    await initialize();

    if (_currentUser != null) {
      return _currentUser;
    }

    _currentUser =
        await _googleSignIn.attemptLightweightAuthentication();

    return _currentUser;
  }

  Future<GoogleSignInAccount> signIn() async {
    await initialize();

    final existingAccount = await tryRestoreSignIn();

    if (existingAccount != null) {
      return existingAccount;
    }

    final account = await _googleSignIn.authenticate();

    _currentUser = account;

    return account;
  }

  Future<UserCredential> signInToMyMoney() async {
    await initialize();

    final GoogleSignInAccount googleUser = await signIn();

    final googleAuthentication = googleUser.authentication;

    final idToken = googleAuthentication.idToken;

    if (idToken == null) {
      throw Exception(
        'Google authentication token is missing. Please try again.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOutFromMyMoney() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();

    _currentUser = null;
  }

  Future<AuthClient> getAuthenticatedClient({
    bool allowInteraction = true,
  }) async {
    await initialize();

    var account = await tryRestoreSignIn();

    if (account == null) {
      if (!allowInteraction) {
        throw StateError(
          'Google sign-in is required for automatic backup.',
        );
      }

      account = await signIn();
    }

    final scopes = [BackupConfig.driveScope];

    var authorization =
        await account.authorizationClient
            .authorizationForScopes(scopes);

    if (authorization == null) {
      if (!allowInteraction) {
        throw StateError(
          'Google Drive permission is required.',
        );
      }

      authorization =
          await account.authorizationClient
              .authorizeScopes(scopes);
    }

    return authorization.authClient(scopes: scopes);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();

    _currentUser = null;
  }
}
