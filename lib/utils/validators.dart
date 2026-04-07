import 'package:flutter/material.dart';

class Validators {
  // Regex alignées avec le backend
  static final RegExp email = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  static final RegExp phone = RegExp(
    r'^\+?[0-9]{8,15}$',
  );
  // Majuscule, minuscule, chiffre, min 6 caractères
  static final RegExp password = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{6,}$',
  );
  // Matricule : uniquement majuscules et chiffres, min 5
  static final RegExp matricule = RegExp(
    r'^[A-Z0-9]{5,}$',
  );

  static String? validateMatricule(String? value) {
    if (value == null || value.isEmpty) return 'Matricule requis';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Majuscules et chiffres uniquement';
    }
    if (value.length < 5) return 'Min. 5 caractères';
    return null;
  }

  static String? validateNom(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    if (!email.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!phone.hasMatch(value.replaceAll(' ', ''))) return 'Numéro invalide';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return 'Min. 6 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return '1 majuscule requise';
    if (!RegExp(r'[a-z]').hasMatch(value)) return '1 minuscule requise';
    if (!RegExp(r'[0-9]').hasMatch(value)) return '1 chiffre requis';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmation requise';
    if (value != password) return 'Mots de passe différents';
    return null;
  }
}