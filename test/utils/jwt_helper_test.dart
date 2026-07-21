import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cenou_mobile/utils/jwt_helper.dart';

/// Fabrique un jeton au format JWT. La signature n'est pas calculée : le
/// lecteur ne la vérifie pas, c'est justement le point.
String _jeton(Map<String, dynamic> charge) {
  String encoder(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

  return '${encoder({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${encoder(charge)}'
      '.signature-non-verifiee';
}

int _secondesDepuisEpoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  group('JwtHelper.decoderCharge', () {
    test('décode la charge utile d\'un jeton bien formé', () {
      final token = _jeton({'id': 42, 'role': 'ETUDIANT'});

      final charge = JwtHelper.decoderCharge(token);

      expect(charge, isNotNull);
      expect(charge!['id'], 42);
      expect(charge['role'], 'ETUDIANT');
    });

    test('retourne null si le jeton n\'a pas trois segments', () {
      expect(JwtHelper.decoderCharge('pas-un-jwt'), isNull);
      expect(JwtHelper.decoderCharge('deux.segments'), isNull);
    });

    test('retourne null si la charge utile est illisible', () {
      expect(JwtHelper.decoderCharge('entete.@@@illisible@@@.signature'), isNull);
    });
  });

  group('JwtHelper.estPerime', () {
    test('un jeton expirant dans le futur n\'est pas périmé', () {
      final token = _jeton({
        'exp': _secondesDepuisEpoch(DateTime.now().add(const Duration(hours: 5))),
      });

      expect(JwtHelper.estPerime(token), isFalse);
    });

    test('un jeton dont l\'échéance est passée est périmé', () {
      final token = _jeton({
        'exp': _secondesDepuisEpoch(DateTime.now().subtract(const Duration(minutes: 1))),
      });

      expect(JwtHelper.estPerime(token), isTrue);
    });

    test('la marge permet d\'anticiper l\'échéance', () {
      final token = _jeton({
        'exp': _secondesDepuisEpoch(DateTime.now().add(const Duration(minutes: 2))),
      });

      expect(JwtHelper.estPerime(token), isFalse);
      expect(JwtHelper.estPerime(token, marge: const Duration(minutes: 10)), isTrue);
    });

    // Garde-fou : refuser l'accès hors ligne sur la foi d'un champ absent
    // déconnecterait l'utilisateur sans raison. C'est au serveur de trancher.
    test('un jeton sans revendication exp n\'est pas considéré comme périmé', () {
      expect(JwtHelper.estPerime(_jeton({'id': 1})), isFalse);
    });

    test('un jeton illisible n\'est pas considéré comme périmé', () {
      expect(JwtHelper.estPerime('pas-un-jwt'), isFalse);
    });

    test('une revendication exp non numérique est ignorée', () {
      expect(JwtHelper.estPerime(_jeton({'exp': 'bientôt'})), isFalse);
    });
  });

  group('JwtHelper.expiration', () {
    test('retourne la date portée par la revendication exp', () {
      final echeance = DateTime.utc(2030, 1, 1, 12);
      final token = _jeton({'exp': _secondesDepuisEpoch(echeance)});

      expect(JwtHelper.expiration(token), echeance);
    });

    test('retourne null en l\'absence de revendication exp', () {
      expect(JwtHelper.expiration(_jeton({'id': 1})), isNull);
    });
  });
}
