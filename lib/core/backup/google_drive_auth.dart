
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

    await _googleSignIn.initialize(
      serverClientId: BackupConfig.googleWebClientId,
    );

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

    final scopes = [BackupConfig.driveScope];

    if (!allowInteraction) {
      // Request an existing Drive authorization without
      // restoring GoogleSignInAccount or opening account UI.
      final authorization = await _googleSignIn
          .authorizationClient
          .authorizationForScopes(scopes);

      if (authorization == null) {
        throw StateError(
          'Google Drive authorization is not available. '
          'Please open Backup & Restore and press Backup Now.',
        );
      }

      return authorization.authClient(scopes: scopes);
    }

    GoogleSignInAccount? account =
        await tryRestoreSignIn();

    account ??= await signIn();

    var authorization =
        await account.authorizationClient
            .authorizationForScopes(scopes);

    if (authorization == null) {
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

  Future<AuthClient> getClientForAutomaticRestore() async {
    await initialize();

    final account = await tryRestoreSignIn();

    if (account == null) {
      throw StateError(
        'Google sign-in is required before automatic restore.',
      );
    }

    final firebaseEmail =
        _firebaseAuth.currentUser?.email?.trim().toLowerCase();

    final googleEmail = account.email.trim().toLowerCase();

    if (firebaseEmail == null ||
        firebaseEmail.isEmpty ||
        firebaseEmail != googleEmail) {
      throw StateError(
        'The Google Drive account does not match '
        'the MyMoney account.',
      );
    }

    final scopes = [BackupConfig.driveScope];

    var authorization =
        await account.authorizationClient
            .authorizationForScopes(scopes);

    authorization ??= await account.authorizationClient
        .authorizeScopes(scopes);

    return authorization.authClient(scopes: scopes);
  }
}
