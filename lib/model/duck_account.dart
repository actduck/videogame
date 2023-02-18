import 'package:google_sign_in/google_sign_in.dart';

class DuckAccount {
  int? id;

  String? displayName;

  String? email;

  String? googleId;

  String? photoUrl;

  int? coins = null;

  int? highScore = null;

  DuckAccount(this.displayName, this.email, this.googleId, this.photoUrl);

  factory DuckAccount.google(GoogleSignInAccount g) => DuckAccount(g.displayName, g.email, g.id, g.photoUrl);
}
