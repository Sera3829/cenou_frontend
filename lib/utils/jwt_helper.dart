import 'dart:convert';

/// Lecture locale d'un jeton JWT, **sans vérification de signature**.
///
/// La validité réelle d'un jeton reste l'affaire du serveur : lui seul détient
/// la clé et sait si la session a été révoquée. Ce lecteur sert uniquement à
/// répondre à une question plus modeste, utile hors ligne : « ce jeton est-il
/// de toute façon périmé ? ». Cela permet de garder une session ouverte sans
/// réseau tant que le jeton n'a pas atteint sa propre date d'expiration, au
/// lieu de renvoyer l'utilisateur vers l'écran de connexion dès qu'il perd la
/// connexion.
class JwtHelper {
  /// Décode la charge utile du jeton, ou null si le format est inexploitable.
  static Map<String, dynamic>? decoderCharge(String token) {
    try {
      final segments = token.split('.');
      if (segments.length != 3) return null;

      final json = utf8.decode(base64Url.decode(base64Url.normalize(segments[1])));
      final charge = jsonDecode(json);
      return charge is Map<String, dynamic> ? charge : null;
    } catch (e) {
      // Jeton illisible : traité comme dépourvu d'information exploitable.
      return null;
    }
  }

  /// Date d'expiration déclarée par le jeton (revendication `exp`), ou null.
  static DateTime? expiration(String token) {
    final charge = decoderCharge(token);
    final exp = charge?['exp'];
    if (exp is! int) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  /// Indique si le jeton est périmé selon sa propre date d'expiration.
  ///
  /// Un jeton dont l'expiration est illisible est considéré comme **non**
  /// périmé : c'est au serveur de trancher, et refuser l'accès hors ligne sur
  /// la foi d'un champ manquant pénaliserait l'utilisateur sans raison.
  ///
  /// [marge] permet d'anticiper l'échéance (ex. exiger 1 min restante).
  static bool estPerime(String token, {Duration marge = Duration.zero}) {
    final echeance = expiration(token);
    if (echeance == null) return false;

    return DateTime.now().toUtc().add(marge).isAfter(echeance);
  }
}
