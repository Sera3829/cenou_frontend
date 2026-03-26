// services/language_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion de la langue de l'application.
///
/// Permet de changer dynamiquement la langue et de persister le choix
/// via SharedPreferences.
class LanguageService with ChangeNotifier {
  Locale _locale = const Locale('fr', 'FR');

  /// Locale actuelle.
  Locale get locale => _locale;

  /// Charge la langue sauvegardée dans SharedPreferences.
  ///
  /// Par défaut, la langue est le français (fr_FR).
  Future<void> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'fr';
      final countryCode = languageCode == 'en' ? 'US' : 'FR';
      _locale = Locale(languageCode, countryCode);
      print('Locale chargee: $_locale');
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de la locale: $e');
      _locale = const Locale('fr', 'FR');
    }
  }

  /// Définit une nouvelle locale et la persiste.
  Future<void> setLocale(Locale locale) async {
    try {
      _locale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
      print('Locale modifiee: $_locale');
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la sauvegarde de la locale: $e');
    }
  }

  /// Retourne la traduction correspondant à la clé donnée.
  ///
  /// Les traductions sont définies dans un dictionnaire interne.
  /// Si la clé n'existe pas, la clé elle-même est retournée.
  String translate(String key) {
    final translations = {
      'fr': {
        // Navigation
        'home': 'Accueil',
        'payments': 'Paiements',
        'reports': 'Signalements',
        'profile': 'Profil',

        // Settings
        'settings': 'Paramètres',
        'preferences': 'Préférences',
        'account': 'Compte',
        'notifications': 'Notifications',
        'language': 'Langue',
        'theme': 'Thème',
        'security': 'Sécurité',
        'help': 'Aide & Support',
        'logout': 'Déconnexion',

        // Commun
        'hello': 'Bonjour',
        'welcome': 'Bienvenue',
        'loading': 'Chargement...',
        'error': 'Erreur',
        'success': 'Succès',
        'cancel': 'Annuler',
        'confirm': 'Confirmer',
        'save': 'Enregistrer',
      },
      'en': {
        // Navigation
        'home': 'Home',
        'payments': 'Payments',
        'reports': 'Reports',
        'profile': 'Profile',

        // Settings
        'settings': 'Settings',
        'preferences': 'Preferences',
        'account': 'Account',
        'notifications': 'Notifications',
        'language': 'Language',
        'theme': 'Theme',
        'security': 'Security',
        'help': 'Help & Support',
        'logout': 'Logout',

        // Commun
        'hello': 'Hello',
        'welcome': 'Welcome',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'cancel': 'Cancel',
        'confirm': 'Confirm',
        'save': 'Save',
      }
    };

    return translations[_locale.languageCode]?[key] ?? key;
  }
}