import 'package:google_sign_in/google_sign_in.dart';

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

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In is not supported on this platform.',
      );
    }

    final account = await _googleSignIn.authenticate();

    _currentUser = account;

    return account;
  }

  Future<String> getAccessToken() async {
    await initialize();

    final account = _currentUser ?? await signIn();

    final authorization =
        await account.authorizationClient.authorizationForScopes(
      [BackupConfig.driveScope],
    );

    final result = authorization ??
        await account.authorizationClient.authorizeScopes(
          [BackupConfig.driveScope],
        );

    return result.accessToken;
  }

  Future<void> signOut() async {
    await initialize();

    await _googleSignIn.signOut();

    _currentUser = null;
  }
}