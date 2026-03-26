import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des préférences utilisateur persistantes.
///
/// Permet de sauvegarder et récupérer les paramètres tels que les notifications,
/// la langue, le thème, l'activation biométrique, l'identifiant de session,
/// ainsi que des paramètres utilisateur personnalisés.
class PreferenceService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'preferred_language';
  static const String _themeKey = 'preferred_theme';
  static const String _biometricKey = 'biometric_enabled';
  static const String _sessionKey = 'session_id';
  static const String _userSettingsKey = 'user_settings';

  static PreferenceService? _instance;
  static SharedPreferences? _prefs;

  /// Retourne l'instance unique du service.
  factory PreferenceService() {
    return _instance ??= PreferenceService._internal();
  }

  PreferenceService._internal();

  /// Initialise le service en chargeant les préférences partagées.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Notifications
  /// Indique si les notifications sont activées.
  Future<bool> getNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(_notificationsKey) ?? true;
  }

  /// Active ou désactive les notifications.
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(_notificationsKey, enabled);
  }

  // Langue
  /// Retourne le code de la langue préférée (ex: 'fr', 'en').
  Future<String> getPreferredLanguage() async {
    await _ensureInitialized();
    return _prefs!.getString(_languageKey) ?? 'fr';
  }

  /// Définit la langue préférée.
  Future<void> setPreferredLanguage(String language) async {
    await _ensureInitialized();
    await _prefs!.setString(_languageKey, language);
  }

  // Thème
  /// Retourne le thème préféré ('system', 'light', 'dark').
  Future<String> getPreferredTheme() async {
    await _ensureInitialized();
    return _prefs!.getString(_themeKey) ?? 'system';
  }

  /// Définit le thème préféré.
  Future<void> setPreferredTheme(String theme) async {
    await _ensureInitialized();
    await _prefs!.setString(_themeKey, theme);
  }

  // Biométrie
  /// Indique si l'authentification biométrique est activée.
  Future<bool> getBiometricEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(_biometricKey) ?? false;
  }

  /// Active ou désactive l'authentification biométrique.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(_biometricKey, enabled);
  }

  // Session
  /// Retourne l'identifiant de session en cours.
  Future<String?> getSessionId() async {
    await _ensureInitialized();
    return _prefs!.getString(_sessionKey);
  }

  /// Définit l'identifiant de session.
  Future<void> setSessionId(String sessionId) async {
    await _ensureInitialized();
    await _prefs!.setString(_sessionKey, sessionId);
  }

  // Paramètres utilisateur personnalisés
  /// Sauvegarde un ensemble de paramètres utilisateur au format JSON.
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    final jsonString = jsonEncode(settings);
    await _prefs!.setString(_userSettingsKey, jsonString);
  }

  /// Récupère les paramètres utilisateur personnalisés.
  Future<Map<String, dynamic>> getUserSettings() async {
    await _ensureInitialized();
    final jsonString = _prefs!.getString(_userSettingsKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  /// Efface toutes les préférences stockées.
  Future<void> clearAllPreferences() async {
    await _ensureInitialized();
    await _prefs!.clear();
  }

  /// Vérifie que l'initialisation a bien été effectuée.
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}