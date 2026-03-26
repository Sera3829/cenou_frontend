// services/notification_api_service.dart
import 'api_service.dart';

/// Service de gestion des notifications et annonces.
class NotificationApiService {
  final ApiService _apiService = ApiService();

  /// Récupère la liste des notifications Firebase.
  ///
  /// [limit] : nombre maximum de notifications à récupérer.
  /// [read]   : filtre sur le statut de lecture (true pour lues, false pour non lues).
  Future<List<Map<String, dynamic>>> getNotifications({
    int? limit,
    bool? read,
  }) async {
    try {
      final params = <String, String>{};
      if (limit != null) params['limit'] = limit.toString();
      if (read != null) params['read'] = read.toString();

      print('Recuperation des notifications Firebase...');
      final response = await _apiService.get('/api/notifications', params: params);

      print('Reponse complete: $response');

      if (response['notifications'] != null) {
        final notificationsData = response['notifications'] as List;
        print('${notificationsData.length} notifications Firebase recues');

        return notificationsData.map<Map<String, dynamic>>((firebaseNotif) {
          final data = firebaseNotif['data'] as Map<String, dynamic>? ?? {};

          return {
            'id': firebaseNotif['id'] as String? ?? '',
            'title': firebaseNotif['title'] as String? ?? 'Notification',
            'message': firebaseNotif['message'] as String? ?? '',
            'type': firebaseNotif['type'] as String? ?? 'GENERAL',
            'read': firebaseNotif['read'] as bool? ?? false,
            'createdAt': DateTime.parse(firebaseNotif['createdAt'] as String? ?? DateTime.now().toIso8601String()),
            'data': data,
          };
        }).toList();
      } else {
        print('Aucune notification dans la reponse');
        return [];
      }

    } catch (e) {
      print('Erreur lors de la recuperation des notifications: $e');
      return [];
    }
  }

  /// Récupère la liste des annonces destinées à l'étudiant.
  Future<List<Map<String, dynamic>>> getAnnoncesEtudiant() async {
    try {
      print('Recuperation des annonces pour etudiant...');
      final response = await _apiService.get('/api/annonces/etudiant');

      print('Reponse annonces: ${response['data']?.length ?? 0} annonces');

      final annoncesData = response['data'] as List? ?? [];

      return annoncesData.map<Map<String, dynamic>>((annonce) {
        return {
          'id': 'annonce_${annonce['id']}',
          'title': '📢 ${annonce['titre']}',
          'message': (annonce['contenu'] as String? ?? '').length > 100
              ? '${(annonce['contenu'] as String).substring(0, 100)}...'
              : annonce['contenu'] as String? ?? '',
          'type': 'ANNONCE',
          'read': annonce['lu'] as bool? ?? false,
          'createdAt': DateTime.parse(annonce['created_at'] as String),
          'data': {
            'annonce_id': annonce['id'],
            'cible': annonce['cible'],
            'created_by': '${annonce['created_by_nom']} ${annonce['created_by_prenom'] ?? ''}',
          },
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la recuperation des annonces etudiant: $e');
      return [];
    }
  }

  /// Marque une notification comme lue.
  Future<void> markAsRead(String notificationId) async {
    try {
      print('Marquage notification $notificationId comme lue');
      await _apiService.put('/api/notifications/$notificationId/read');
    } catch (e) {
      print('Erreur lors du marquage de la notification comme lue: $e');
      rethrow;
    }
  }

  /// Marque toutes les notifications comme lues.
  Future<void> markAllAsRead() async {
    try {
      print('Marquage de toutes les notifications comme lues');
      await _apiService.put('/api/notifications/read-all');
    } catch (e) {
      print('Erreur lors du marquage de toutes les notifications comme lues: $e');
      rethrow;
    }
  }

  /// Retourne le nombre de notifications non lues.
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/api/notifications');
      return response['unread_count'] as int? ?? 0;
    } catch (e) {
      print('Erreur lors de la recuperation du nombre de notifications non lues: $e');
      return 0;
    }
  }

  /// Supprime une notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('Suppression de la notification $notificationId');
      await _apiService.delete('/api/notifications/$notificationId');
    } catch (e) {
      print('Erreur lors de la suppression de la notification: $e');
      rethrow;
    }
  }

  /// Récupère la liste des annonces (toutes).
  Future<List<Map<String, dynamic>>> getAnnonces() async {
    try {
      final response = await _apiService.get('/api/annonces');
      final annoncesData = response['data'] as List? ?? [];

      return annoncesData.map<Map<String, dynamic>>((annonce) {
        return {
          'id': 'annonce_${annonce['id']}',
          'title': '📢 ${annonce['titre']}',
          'message': annonce['contenu'] as String? ?? '',
          'type': 'ANNONCE',
          'read': annonce['lu'] as bool? ?? false,
          'createdAt': DateTime.parse(annonce['created_at'] as String),
          'data': {
            'annonce_id': annonce['id'],
            'cible': annonce['cible'],
            'created_by': annonce['created_by_nom'],
          },
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la recuperation des annonces: $e');
      return [];
    }
  }

  /// Récupère une annonce spécifique par son identifiant.
  Future<Map<String, dynamic>?> getAnnonceById(int annonceId) async {
    try {
      print('Recuperation de l\'annonce $annonceId...');

      final response = await _apiService.get('/api/annonces/$annonceId');

      print('Annonce $annonceId recuperee: ${response['annonce']['titre']}');

      return response['annonce'] as Map<String, dynamic>?;
    } catch (e) {
      print('Erreur lors de la recuperation de l\'annonce $annonceId: $e');
      return null;
    }
  }
}