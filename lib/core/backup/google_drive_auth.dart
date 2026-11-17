
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

import 'backup_config.dart';

class GoogleDriveAuth {
  GoogleDriveAuth._();

  static final GoogleDriveAuth instance = GoogleDriveAuth._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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

  Future<GoogleSignInAccount> signIn() async {
    await initialize();

    final account = await _googleSignIn.authenticate();

    _currentUser = account;

    return account;
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

  Future<AuthClient> getAuthenticatedClient({
    bool allowInteraction = true,
  }) async {
    await initialize();

    final account = await tryRestoreSignIn();

    if (account == null) {
      if (!allowInteraction) {
        throw StateError(
          'Google sign-in is required for automatic backup.',
        );
      }

      await signIn();
    }

    final currentAccount = _currentUser!;

    final scopes = [BackupConfig.driveScope];

    var authorization =
        await currentAccount.authorizationClient
            .authorizationForScopes(scopes);

    if (authorization == null) {
      if (!allowInteraction) {
        throw StateError(
          'Google Drive permission is required.',
        );
      }

      authorization =
          await currentAccount.authorizationClient
              .authorizeScopes(scopes);
    }

    return authorization.authClient(scopes: scopes);
  }

  Future<void> signOut() async {
    await initialize();

    await _googleSignIn.signOut();

    _currentUser = null;
  }
}
