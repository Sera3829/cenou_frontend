import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AppLocalizations — traductions FR / EN sans code generation
//
// Usage dans un widget :
//   final l10n = AppLocalizations.of(context);
//   Text(l10n.home)
//
// Ajouter dans main.dart → MaterialApp.localizationsDelegates :
//   AppLocalizations.delegate,
// ══════════════════════════════════════════════════════════════════════════════

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr', 'FR'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  bool get isFrench => locale.languageCode == 'fr';

  String _t(String fr, String en) => isFrench ? fr : en;

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome          => _t('Accueil', 'Home');
  String get navPayments      => _t('Paiements', 'Payments');
  String get navReports       => _t('Signalements', 'Reports');
  String get navProfile       => _t('Profil', 'Profile');

  // ── Actions communes ───────────────────────────────────────────────────────
  String get cancel           => _t('Annuler', 'Cancel');
  String get save             => _t('Enregistrer', 'Save');
  String get confirm          => _t('Confirmer', 'Confirm');
  String get close            => _t('Fermer', 'Close');
  String get retry            => _t('Réessayer', 'Retry');
  String get refresh          => _t('Rafraîchir', 'Refresh');
  String get loading          => _t('Chargement…', 'Loading…');
  String get offline          => _t('Hors ligne', 'Offline');
  String get offlineBadge     => _t('Hors ligne', 'Offline');
  String get error            => _t('Erreur', 'Error');
  String get success          => _t('Succès', 'Success');
  String get send             => _t('Envoyer', 'Send');
  String get edit             => _t('Modifier', 'Edit');
  String get delete           => _t('Supprimer', 'Delete');
  String get comingSoon       => _t('Bientôt disponible', 'Coming soon');

  // ── Auth ───────────────────────────────────────────────────────────────────
  String get login            => _t('Connexion', 'Login');
  String get logout           => _t('Déconnexion', 'Logout');
  String get logoutTitle      => _t('Déconnexion', 'Logout');
  String get logoutConfirm    => _t('Voulez-vous vraiment vous déconnecter ?', 'Are you sure you want to log out?');
  String get logoutButton     => _t('Se déconnecter', 'Log out');
  String get loggingOut       => _t('Déconnexion en cours…', 'Logging out…');
  // Login
  String get welcome => _t('Bienvenue', 'Welcome');
  String get pleaseLogin => _t('Veuillez vous connecter', 'Please log in');
  String get usernameOrEmail => _t('Matricule ou Email', 'Student ID or Email');
  String get usernameShort => _t('Matricule / Email', 'ID / Email');
  String get enterUsername => _t('Entrez votre matricule', 'Enter your student ID');
  String get yourUsername => _t('Votre matricule', 'Your ID');
  String get password => _t('Mot de passe', 'Password');
  String get enterPassword => _t('Entrez votre mot de passe', 'Enter your password');
  String get yourPassword => _t('Votre mot de passe', 'Your password');
  String get loginShort => _t('CONNEXION', 'LOGIN');
  String get noAccount => _t('Pas encore de compte ?', 'No account yet?');
  String get createAccount => _t('Créer un compte', 'Create an account');
  String get pleaseEnterUsername => _t('Veuillez entrer votre identifiant', 'Please enter your username');
  String get pleaseEnterPassword => _t('Veuillez entrer votre mot de passe', 'Please enter your password');
  String get loginError => _t('Erreur de connexion', 'Login error');
  String get unexpectedError => _t('Erreur inattendue', 'Unexpected error');
  String get accountDisabled => _t('Compte désactivé', 'Account disabled');
  String get accountDisabledMessage => _t('Votre compte a été désactivé ou suspendu.', 'Your account has been disabled or suspended.');
  String get contactAdminToReactivate => _t('Contactez l\'administration pour réactiver votre compte.', 'Contact the administration to reactivate your account.');
  String get iUnderstand => _t('J\'ai compris', 'I understand');
  String get createAccountTitle => _t('Créer un compte', 'Create an account');
  String get fillInfoToRegister => _t('Remplissez vos informations pour vous inscrire', 'Fill in your information to register');
  String get enterMatricule => _t('Entrez votre matricule', 'Enter your student ID');
  String get lastName => _t('Nom', 'Last name');
  String get lastNameHint => _t('Nom', 'Last name');
  String get firstName => _t('Prénom', 'First name');
  String get firstNameHint => _t('Prénom', 'First name');
  String get emailHint => _t('exemple@cenou.bf', 'example@cenou.bf');
  String get passwordHint => _t('Minimum 6 caractères', 'Minimum 6 characters');
  String get confirmPasswordHint => _t('Retapez votre mot de passe', 'Retype your password');
  String get pwdLowercase => _t('1 minuscule', '1 lowercase');
  String get registerButton => _t('S\'INSCRIRE', 'REGISTER');
  String get alreadyHaveAccount => _t('Déjà un compte ? ', 'Already have an account? ');
  String get loginHere => _t('Se connecter', 'Log in');
  String get accountCreatedSuccess => _t('Compte créé avec succès', 'Account created successfully');
  String get correctFormErrors => _t('Veuillez corriger les erreurs dans le formulaire', 'Please correct the errors in the form');

  // ── Profil ─────────────────────────────────────────────────────────────────
  String get myProfile        => _t('Mon Profil', 'My Profile');
  String get editProfile      => _t('Modifier le profil', 'Edit Profile');
  String get personalInfo     => _t('Informations personnelles', 'Personal Information');
  String get matricule        => _t('Matricule', 'Student ID');
  String get email            => _t('Adresse email', 'Email address');
  String get phone            => _t('Téléphone', 'Phone');
  String get role             => _t('Rôle', 'Role');
  String get roleStudent      => _t('Étudiant', 'Student');
  String get roleManager      => _t('Gestionnaire', 'Manager');
  String get roleAdmin        => _t('Administrateur', 'Administrator');
  String get statusActive     => _t('Compte actif', 'Active account');
  String get statusInactive   => _t('Compte inactif', 'Inactive account');
  String get statusSuspended  => _t('Compte suspendu', 'Suspended account');
  String get profileUpdated   => _t('Profil mis à jour avec succès', 'Profile updated successfully');
  String get profileUpdateErr => _t('Erreur lors de la mise à jour du profil', 'Profile update failed');
  String get activity         => _t('Activité', 'Activity');
  String get paymentsMade     => _t('Paiements effectués', 'Payments made');
  String get reportsCreated   => _t('Signalements créés', 'Reports created');
  String get nameNotEditable  => _t('Le nom et le matricule ne peuvent pas être modifiés',
      'Name and student ID cannot be modified');
  String get phoneOptional    => _t('Téléphone (optionnel)', 'Phone (optional)');
  String get emailRequired    => _t('L\'email est requis', 'Email is required');
  String get emailInvalid     => _t('Email invalide', 'Invalid email');
  String get phoneMin         => _t('Au moins 8 chiffres', 'At least 8 digits');
  String get loadingProfile   => _t('Chargement du profil…', 'Loading profile…');
  String get settingsSub => _t('Personnaliser votre application', 'Customize your application');
  String get updatingProfile => _t('Mise à jour en cours…', 'Updating…');

  // ── Paramètres ─────────────────────────────────────────────────────────────
  String get settings         => _t('Paramètres', 'Settings');
  String get preferences      => _t('Préférences', 'Preferences');
  String get security         => _t('Sécurité', 'Security');
  String get helpSupport      => _t('Aide & Support', 'Help & Support');
  String get appInfo          => _t('Informations de l\'application', 'Application info');

  // Préférences
  String get pushNotif        => _t('Notifications push', 'Push notifications');
  String get pushNotifSub     => _t('Recevoir les notifications importantes', 'Receive important notifications');
  String get biometric        => _t('Authentification biométrique', 'Biometric authentication');
  String get biometricSub     => _t('Utiliser l\'empreinte digitale', 'Use fingerprint');
  String get language         => _t('Langue', 'Language');
  String get chooseLanguage   => _t('Choisir la langue', 'Choose language');
  String get theme            => _t('Thème', 'Theme');
  String get chooseTheme      => _t('Choisir le thème', 'Choose theme');
  String get themeLight       => _t('Clair', 'Light');
  String get themeDark        => _t('Sombre', 'Dark');
  String get themeSystem      => _t('Système', 'System');
  String themeChanged(String name) => _t('Thème changé en $name', 'Theme changed to $name');

  // Sécurité
  String get changePassword   => _t('Changer le mot de passe', 'Change password');
  String get changePasswordSub=> _t('Mettre à jour votre mot de passe', 'Update your password');
  String get activeSessions   => _t('Sessions actives', 'Active sessions');
  String get activeSessionsSub=> _t('Gérer les appareils connectés', 'Manage connected devices');
  String get loginHistory     => _t('Historique de connexion', 'Login history');
  String get loginHistorySub  => _t('Voir les connexions récentes', 'View recent logins');
  String get passwordChanged  => _t('Mot de passe changé avec succès', 'Password changed successfully');
  String get oldPassword      => _t('Ancien mot de passe', 'Old password');
  String get newPassword      => _t('Nouveau mot de passe', 'New password');
  String get confirmPassword  => _t('Confirmation', 'Confirmation');
  String get passwordReqs     => _t('Exigences :', 'Requirements:');
  String get pwdMin6          => _t('Au moins 6 caractères', 'At least 6 characters');
  String get pwdUppercase     => _t('Une lettre majuscule', 'One uppercase letter');
  String get pwdDigit         => _t('Un chiffre', 'One digit');
  String get required_        => _t('Requis', 'Required');
  String get pwdMin6err       => _t('Min 6 caractères', 'Min 6 characters');
  String get pwdUppercaseErr  => _t('Une majuscule requise', 'One uppercase required');
  String get pwdDigitErr      => _t('Un chiffre requis', 'One digit required');
  String get pwdMismatch      => _t('Ne correspond pas', 'Does not match');
  String get change           => _t('Changer', 'Change');

  // Aide
  String get helpCenter       => _t('Centre d\'aide', 'Help center');
  String get helpCenterSub    => _t('FAQ et guides', 'FAQ and guides');
  String get contactUs        => _t('Nous contacter', 'Contact us');
  String get contactUsSub     => _t('Support technique CENOU', 'CENOU technical support');
  String get reportBug        => _t('Signaler un problème', 'Report an issue');
  String get reportBugSub     => _t('Faire remonter un bug', 'Report a bug');
  String get privacy          => _t('Confidentialité', 'Privacy');
  String get privacySub       => _t('Politique de confidentialité', 'Privacy policy');
  String get supportTitle     => _t('Support CENOU', 'CENOU Support');
  String get supportContact   => _t('Pour toute assistance technique :', 'For technical assistance:');
  String get supportHours     => _t('Lun-Dim : 8h-18h', 'Mon-Sun: 8am-6pm');
  String get sendEmail        => _t('Envoyer un email', 'Send email');
  String get reportTitle      => _t('Signaler un problème', 'Report an issue');
  String get reportContent    => _t(
      'Décrivez le problème que vous rencontrez. Notre équipe technique examinera votre rapport.',
      'Describe the issue you are experiencing. Our technical team will review your report.');
  String get report           => _t('Signaler', 'Report');

  // App info
  String get version          => _t('Version', 'Version');
  String get lastUpdate       => _t('Dernière mise à jour', 'Last update');
  String get build            => _t('Build', 'Build');
  String get session          => _t('Session', 'Session');
  String get mode             => _t('Mode', 'Mode');
  String get modeAdmin        => _t('Admin', 'Admin');
  String get modeMobile       => _t('Mobile', 'Mobile');
  String get copyright        => _t('© 2026', '© 2026');
  String get copyrightVal     => _t('CENOU - Tous droits réservés', 'CENOU - All rights reserved');

  // Biométrie
  String get biometricEnabled => _t('Authentification biométrique activée', 'Biometric authentication enabled');
  String get biometricCancelled=> _t('Authentification annulée', 'Authentication cancelled');

  // ── Accueil ────────────────────────────────────────────────────────────────
  String get hello            => _t('Bonjour,', 'Hello,');
  String get quickOverview    => _t('Aperçu rapide', 'Quick overview');
  String get quickActions     => _t('Actions rapides', 'Quick actions');
  String get myHousing        => _t('Mon Logement', 'My Housing');
  String get chambre          => _t('Chambre', 'Room');
  String get chambreShort     => _t('Ch.', 'Rm.');
  String get status           => _t('Statut', 'Status');
  String get active           => _t('Actif', 'Active');
  String get inactive         => _t('Inactif', 'Inactive');
  String get makePayment      => _t('Effectuer un paiement', 'Make a payment');
  String get makePaymentDesc  => _t('Régler votre loyer ou autres frais', 'Pay your rent or other fees');
  String get makePaymentShort => _t('Régler votre loyer', 'Pay your rent');
  String get reportIssue      => _t('Signaler un problème', 'Report an issue');
  String get reportIssueDesc  => _t('Signaler une panne ou un dysfonctionnement', 'Report a breakdown or malfunction');
  String get reportIssueShort => _t('Panne ou dysfonctionnement', 'Breakdown or malfunction');

  // Création de signalement
  String get problemType => _t('Type de problème', 'Problem type');
  String get description => _t('Description', 'Description');
  String photosCount(int count) => _t('Photos ($count/5)', 'Photos ($count/5)');
  String get createReportButton => _t('CRÉER LE SIGNALEMENT', 'CREATE REPORT');
  String get maxPhotosReached => _t('Maximum 5 photos autorisées', 'Maximum 5 photos allowed');
  String get cameraError => _t('Erreur lors de l\'accès à la caméra', 'Camera access error');
  String get cameraPermissionDenied => _t('Accès à la caméra refusé. Autorisez-le dans les paramètres.', 'Camera access denied. Please enable it in settings.');
  String photosAddedLimit(int count) => _t('Seulement $count photo(s) ajoutée(s) (max 5)', 'Only $count photo(s) added (max 5)');
  String get addAtLeastOnePhoto => _t('Veuillez ajouter au moins une photo', 'Please add at least one photo');
  String get reportCreated => _t('Signalement créé', 'Report created');
  String get reportCreatedSuccess => _t('Votre signalement a été enregistré avec succès.', 'Your report has been successfully submitted.');
  String trackingNumber(String number) => _t('Numéro de suivi: $number', 'Tracking number: $number');
  String get willBeNotified => _t('Vous serez notifié de son traitement.', 'You will be notified of its progress.');
  String get reportInfoBanner => _t('Décrivez le problème et ajoutez des photos pour un traitement rapide', 'Describe the problem and add photos for faster processing');
  String get detailedDescription => _t('Description détaillée', 'Detailed description');
  String get detailedDescriptionHint => _t('Décrivez le problème en détail…', 'Describe the problem in detail…');
  String get descriptionRequired => _t('La description est requise', 'Description is required');
  String get descriptionMinLength => _t('Au moins 10 caractères', 'At least 10 characters');
  String get camera => _t('Caméra', 'Camera');
  String get gallery => _t('Galerie', 'Gallery');
  String get addAtLeastOnePhotoHint => _t('Ajoutez au moins une photo du problème', 'Add at least one photo of the issue');

  // Stats
  String get confirmed        => _t('Confirmés', 'Confirmed');
  String get pending          => _t('En attente', 'Pending');
  String get total            => _t('Total', 'Total');
  String get payments         => _t('Paiements', 'Payments');
  String get reports          => _t('Signalements', 'Reports');

  // Détail signalement
  String get reportDetails => _t('Détails du signalement', 'Report details');
  String get share => _t('Partager', 'Share');
  String get reportNotFound => _t('Signalement introuvable', 'Report not found');
  String get problemResolved => _t('Problème résolu', 'Problem resolved');
  String get inProgressStatus => _t('En cours de traitement', 'In progress');
  String get reportCancelled => _t('Signalement annulé', 'Report cancelled');
  String get pendingProcessing => _t('En attente de traitement', 'Pending processing');
  String get type => _t('Type', 'Type');
  String get reportedOn => _t('Date de signalement', 'Reported on');
  String get reportedOnShort => _t('Signalé le', 'Reported');
  String get problemDetails => _t('Détails du problème', 'Problem details');
  String get cannotDisplayPhotos => _t('Impossible d\'afficher les photos', 'Cannot display photos');
  String get resolution => _t('Résolution', 'Resolution');
  String resolvedOn(String date) => _t('Résolu le $date', 'Resolved on $date');
  String get commentLabel => _t('Commentaire :', 'Comment:');

  // ── Paiements ──────────────────────────────────────────────────────────────
  String get paymentDetails   => _t('Détails du paiement', 'Payment details');
  String get amount           => _t('Montant', 'Amount');
  String get information      => _t('Informations', 'Information');
  String get receipt          => _t('Reçu', 'Receipt');
  String get downloadPdf      => _t('Télécharger le reçu PDF', 'Download PDF receipt');
  String get downloadPdfShort => _t('Télécharger PDF', 'Download PDF');
  String get shareReceipt     => _t('Partager le reçu', 'Share receipt');
  String get generatingPdf    => _t('Génération du PDF…', 'Generating PDF…');
  String get preparingShare   => _t('Préparation du partage…', 'Preparing share…');
  String get inProgress       => _t('En cours…', 'In progress…');
  String get preparing        => _t('Préparation…', 'Preparing…');
  String get paymentConfirmed => _t('Paiement confirmé', 'Payment confirmed');
  String get paymentFailed    => _t('Paiement échoué', 'Payment failed');
  String get paymentPending   => _t('En attente de confirmation', 'Awaiting confirmation');
  String get pendingShort     => _t('En attente…', 'Pending…');
  String get offlineData      => _t('Données hors ligne', 'Offline data');
  String get noDownloadOffline => _t('Téléchargement non disponible hors ligne', 'Download unavailable offline');
  String get noShareOffline   => _t('Partage non disponible hors ligne', 'Share unavailable offline');
  String get loadingError     => _t('Erreur de chargement', 'Loading error');
  String get notAvailableOffline => _t('Paiement non disponible hors ligne', 'Payment not available offline');
  String get offlinePaymentRequired => _t('Connexion internet requise pour effectuer un paiement', 'Internet connection required to make a payment');
  String get fullHistory => _t('Historique complet', 'Full history');
  String get newPayment => _t('Nouveau paiement', 'New payment');
  String get newPaymentShort => _t('Paiement', 'Payment');
  String get financialSummary => _t('Résumé financier', 'Financial summary');
  String get totalPayments => _t('Total', 'Total');
  String get confirmedPayments => _t('Confirmés', 'Confirmed');
  String get pendingPayments => _t('En cours', 'Pending');
  String totalPaidAmount(String amount) => _t('Total payé: $amount FCFA', 'Total paid: $amount FCFA');
  String amountDue(String amount) => _t('À régler: $amount FCFA', 'Due: $amount FCFA');
  String get loadingPayments => _t('Chargement des paiements…', 'Loading payments…');
  String get noPayments => _t('Aucun paiement', 'No payments');
  String get noPaymentsSub => _t('Vos paiements effectués apparaîtront ici', 'Your completed payments will appear here');
  String get pendingPayment => _t('En attente', 'Pending');
  String roomAbbr(String room) => _t('Ch. $room', 'Rm. $room');
  String get paymentNotFound => _t('Paiement introuvable', 'Payment not found');
  String get paymentNotAvailableOffline => _t('Paiement non disponible hors ligne', 'Payment not available offline');
  String get paymentMethod => _t('Mode de paiement', 'Payment method');
  String get reference => _t('Référence', 'Reference');
  String get dueDate => _t('Date d\'échéance', 'Due date');
  String get dueDateShort => _t('Échéance', 'Due');
  String get room => _t('Chambre', 'Room');
  String pdfSavedTo(String path) => _t('PDF sauvegardé dans : $path', 'PDF saved to: $path');
  String get receiptSubject => _t('Reçu de paiement CENOU', 'CENOU payment receipt');
  String receiptShareText(String ref) => _t('Reçu CENOU — Réf : $ref', 'CENOU receipt — Ref: $ref');
  String get shareError => _t('Erreur lors du partage', 'Share error');
  String get center => _t('Centre', 'Center');
  String get paymentDuration => _t('Durée du paiement', 'Payment duration');
  String get months => _t('mois', 'months');
  String get monthlyRent => _t('Loyer mensuel', 'Monthly rent');
  String get numberOfMonths => _t('Nombre de mois', 'Number of months');
  String get totalAmount => _t('Montant total', 'Total amount');
  String get phoneNumber => _t('Numéro de téléphone', 'Phone number');
  String get period => _t('Période', 'Period');
  String get confirmPayment => _t('Confirmer le paiement', 'Confirm payment');
  String get paymentInitiated => _t('Paiement initié', 'Payment initiated');
  String get paymentRequestRecorded => _t('Votre demande a été enregistrée.', 'Your request has been recorded.');
  String get willReceiveNotification => _t('Vous recevrez une notification de confirmation.', 'You will receive a confirmation notification.');
  String get ok => _t('OK', 'OK');
  String get selectPaymentMethod => _t('Veuillez sélectionner un mode de paiement', 'Please select a payment method');
  String get phoneHint => _t('+226 70 XX XX XX', '+226 70 XX XX XX');
  String get phoneRequired => _t('Le numéro de téléphone est requis', 'Phone number is required');
  String get phoneInvalid => _t('Numéro invalide', 'Invalid number');
  String cannotLoadRent(String error) => _t('Impossible de récupérer le loyer: $error', 'Unable to fetch rent: $error');
  String rentPerMonth(String amount) => _t('Loyer: $amount FCFA / mois', 'Rent: $amount FCFA / month');
  String monthsTimesRent(int months, String amount) => _t('$months × $amount FCFA', '$months × $amount FCFA');
  String referenceLabel(String ref) => _t('Réf: $ref', 'Ref: $ref');
  String periodRange(String start, String end) => _t('Période: $start → $end', 'Period: $start → $end');
  String pay(String amount) => _t('PAYER $amount FCFA', 'PAY $amount FCFA');
  String payShort(String amount) => _t('PAYER $amount F', 'PAY $amount F');

  // ── Signalements ───────────────────────────────────────────────────────────
  // Signalements - liste
  String get myReports => _t('Mes Signalements', 'My Reports');
  String get offlineCreateReport => _t('Connexion internet requise pour créer un signalement', 'Internet connection required to create a report');
  String get createReport => _t('Créer un signalement', 'Create a report');
  String get reportShort => _t('Signalement', 'Report');
  String get problemTypes => _t('Types de problèmes', 'Problem types');
  String get problemTypesTitle => _t('Types de problèmes', 'Problem types');
  String get availableCategories => _t('Catégories de signalements disponibles :', 'Available report categories:');
  String get plumbing => _t('PLOMBERIE', 'PLUMBING');
  String get plumbingDesc => _t('Fuite d\'eau, robinets, sanitaires', 'Water leak, taps, sanitary');
  String get electricity => _t('ÉLECTRICITÉ', 'ELECTRICITY');
  String get electricityDesc => _t('Pannes, prises, interrupteurs', 'Outages, sockets, switches');
  String get roofing => _t('TOITURE', 'ROOFING');
  String get roofingDesc => _t('Infiltrations, tuiles, gouttières', 'Leaks, tiles, gutters');
  String get locks => _t('SERRURE', 'LOCKS');
  String get locksDesc => _t('Portes, fenêtres, fermetures', 'Doors, windows, closures');
  String get furniture => _t('MOBILIER', 'FURNITURE');
  String get furnitureDesc => _t('Lits, tables, chaises, armoires', 'Beds, tables, chairs, cabinets');
  String get other => _t('AUTRE', 'OTHER');
  String get otherDesc => _t('Autres problèmes non listés', 'Other unlisted issues');
  String get understood => _t('Compris', 'Understood');
  String get reportOverview => _t('Aperçu des signalements', 'Report overview');
  String get resolved => _t('Résolus', 'Resolved');
  String historyCount(int count) => _t('Historique ($count)', 'History ($count)');
  String reportCount(int count) => _t('$count signalement${count > 1 ? "s" : ""}', '$count report${count > 1 ? "s" : ""}');
  String get loadingReports => _t('Chargement des signalements…', 'Loading reports…');
  String get noReports => _t('Aucun signalement', 'No reports');
  String get noReportsSub => _t('Vous n\'avez effectué aucun signalement pour le moment', 'You have not submitted any reports yet');

  // ── Notifications ──────────────────────────────────────────────────────────
  String get notifications    => _t('Notifications', 'Notifications');
  String get cacheBadge => _t('Cache', 'Cache');
  String get markAllRead => _t('Tout marquer lu', 'Mark all read');
  String get allMarkedAsRead => _t('Toutes les notifications marquées comme lues', 'All notifications marked as read');
  String get unreadCount => _t('non lue(s)', 'unread'); // Peut être paramétré
  String unreadCountText(int count) => _t('$count non lue(s)', '$count unread');
  String get notificationDeleted => _t('Notification supprimée', 'Notification deleted');
  String get offlineDeleteNotif => _t('Connexion internet requise pour supprimer une notification', 'Internet connection required to delete a notification');
  String get deleteNotificationConfirm => _t('Voulez-vous vraiment supprimer cette notification ?', 'Do you really want to delete this notification?');
  String get noNotifications => _t('Aucune notification', 'No notifications');
  String get noNotificationsSub => _t('Vous serez notifié des événements importants', 'You will be notified of important events');
  String get cannotLoadNotifications => _t('Impossible de charger les notifications', 'Unable to load notifications');
  String get detailsNotAvailable => _t('Détails non disponibles', 'Details not available');

  // Annonces
  String get announceDetails => _t('Détails de l\'annonce', 'Announcement details');
  String get announceNotAvailableOffline => _t('Cette annonce n\'est pas disponible hors ligne', 'This announcement is not available offline');
  String get cannotLoadAnnounce => _t('Impossible de charger l\'annonce', 'Unable to load announcement');
  String get announceTypeGeneral => _t('Générale', 'General');
  String get announceTypeByCenter => _t('Par centre', 'By center');
  String get announceTypeSpecificStudents => _t('Étudiants spécifiques', 'Specific students');
  String get unknownDate => _t('Date inconnue', 'Unknown date');
  String publishedOn(String date) => _t('Publiée le $date', 'Published on $date');
  String byAuthor(String author) => _t('Par $author', 'By $author');
  String sentToNPeople(int count) => _t('Envoyée à $count personne(s)', 'Sent to $count person(s)');

// Temps relatif
  String timeMinutesAgo(int minutes) => _t('Il y a $minutes min', '$minutes min ago');
  String timeHoursAgo(int hours) => _t('Il y a ${hours}h', '${hours}h ago');
  String timeDaysAgo(int days) => _t('Il y a ${days}j', '${days}d ago');

  // Dashboard (Web)

  // Admin Login
  String get adminLoginTitle => _t('Connexion Administrateur', 'Administrator Login');
  String get accessDashboard => _t('Accédez au tableau de bord', 'Access the dashboard');
  String get usernameRequired => _t('Identifiant requis', 'Username required');
  String get passwordRequired => _t('Mot de passe requis', 'Password required');
  String get passwordMinLength => _t('Minimum 6 caractères', 'Minimum 6 characters');
  String get rememberMe => _t('Se souvenir de moi', 'Remember me');
  String get forgotPassword => _t('Mot de passe oublié ?', 'Forgot password?');
  String get loginButton => _t('SE CONNECTER', 'LOGIN');
  String get forgotPasswordTitle => _t('Mot de passe oublié', 'Forgot password');
  String get contactTechSupport => _t('Contactez le support technique :', 'Contact technical support:');
  String copyrightText(int year) => _t('© $year CENOU - Tous droits réservés', '© $year CENOU - All rights reserved');
  String get contactEmail => _t('70382983b@gmail.com', '70382983b@gmail.com');
  String get contactPhone => _t('+226 70 38 29 83', '+226 70 38 29 83');

  // Annonces Admin
  String get announcementsNotifications => _t('Annonces & Notifications', 'Announcements & Notifications');
  String get sendImportantNotifications => _t('Envoyez des notifications importantes aux étudiants', 'Send important notifications to students');
  String get newAnnouncement => _t('Nouvelle annonce', 'New announcement');
  String get noAnnouncementsSent => _t('Aucune annonce envoyée', 'No announcements sent');
  String get sendFirstAnnouncement => _t('Envoyez votre première annonce aux étudiants', 'Send your first announcement to students');
  String get createAnnouncement => _t('Créer une annonce', 'Create announcement');
  String get deleteAnnouncementTitle => _t('Supprimer l\'annonce', 'Delete announcement');
  String get deleteAnnouncementConfirm => _t('Voulez-vous vraiment supprimer cette annonce ?', 'Do you really want to delete this announcement?');
  String get announcementDeleted => _t('Annonce supprimée avec succès', 'Announcement deleted successfully');
  String get announcementDeleteError => _t('Erreur: ', 'Error: '); // ou String announcementDeleteError(String e) => ...

// Statistiques
  String get general => _t('Générale', 'General');
  String get byCenter => _t('Par centre', 'By center');
  String get students => _t('Étudiants', 'Students');

// Dialogue d'envoi
  String get newAnnouncementTitle => _t('Nouvelle annonce', 'New announcement');
  String get sendNotificationToStudents => _t('Envoyez une notification aux étudiants', 'Send a notification to students');
  String get stepMessage => _t('Message', 'Message');
  String get stepRecipients => _t('Destinataires', 'Recipients');
  String get stepSummary => _t('Résumé', 'Summary');
  String get writeYourMessage => _t('Rédigez votre message', 'Write your message');
  String get beClearAndConcise => _t('Soyez clair et concis pour une meilleure lecture', 'Be clear and concise for better readability');
  String get announcementTitleLabel => _t('Titre de l\'annonce *', 'Announcement title *');
  String get titleHint => _t('Ex: Coupure d\'eau programmée ce soir', 'Ex: Scheduled water outage tonight');
  String get titleRequired => _t('Le titre est requis', 'Title is required');
  String get titleMinLength => _t('Le titre doit contenir au moins 5 caractères', 'Title must contain at least 5 characters');
  String get contentLabel => _t('Contenu du message *', 'Message content *');
  String get contentHint => _t('Rédigez le contenu détaillé de votre annonce...', 'Write the detailed content of your announcement...');
  String get contentRequired => _t('Le contenu est requis', 'Content is required');
  String get contentMinLength => _t('Le contenu doit contenir au moins 10 caractères', 'Content must contain at least 10 characters');
  String get tipTitle => _t('Conseil : Rédigez un titre accrocheur et un message clair pour maximiser l\'engagement', 'Tip: Write a catchy title and a clear message to maximize engagement');
  String get chooseRecipients => _t('Choisissez les destinataires', 'Choose recipients');
  String get selectWhoReceives => _t('Sélectionnez qui recevra cette annonce', 'Select who will receive this announcement');
  String get announcementType => _t('Type d\'annonce', 'Announcement type');
  String get selectCenter => _t('Sélectionner un centre', 'Select a center');
  String get chooseCenter => _t('Choisissez un centre', 'Choose a center');
  String get centerRequired => _t('Veuillez sélectionner un centre', 'Please select a center');
  String get selectRecipients => _t('Sélectionner les destinataires', 'Select recipients');
  String get searchByNameOrId => _t('Rechercher par nom ou matricule...', 'Search by name or student ID...');
  String get filterByCenter => _t('Filtrer par centre', 'Filter by center');
  String get allCenters => _t('Tous les centres', 'All centers');
  String get selectAll => _t('Tout', 'All');
  String get selectNone => _t('Aucun', 'None');
  String get noStudentsFound => _t('Aucun étudiant ne correspond à votre recherche', 'No students match your search');
  String get noStudentsAvailable => _t('Aucun étudiant disponible', 'No students available');
  String get studentsSelected => _t(' étudiant(s) sélectionné(s)', ' student(s) selected');
  String get selectRecipientsMessage => _t('Sélectionnez les destinataires', 'Select recipients');
  String get verifyAndSend => _t('Vérifiez et envoyez', 'Verify and send');
  String get verifyBeforeSending => _t('Vérifiez les informations avant l\'envoi', 'Verify information before sending');
  String get messagePreview => _t('Aperçu du message', 'Message preview');
  String get recipients => _t('Destinataires', 'Recipients');
  String get notificationsIrreversible => _t(' notifications. Cette action est irréversible.', ' notifications. This action is irreversible.');
  String get back => _t('Retour', 'Back');
  String get next => _t('Suivant', 'Next');
  String get sending => _t('Envoi en cours...', 'Sending...');
  String get sendAnnouncement => _t('Envoyer l\'annonce', 'Send announcement');
  String get recipientsCount => _t(' destinataire(s)', ' recipient(s)');
  String get errorSending => _t('Erreur: ', 'Error: ');
  String get deleteTooltip => _t('Supprimer', 'Delete');
  String get totalLabel => _t('Total', 'Total');
  String get generalLabel => _t('Générale', 'General');
  String get byCenterLabel => _t('Par centre', 'By center');
  String get studentsLabel => _t('Étudiants', 'Students');
  String get recipientsCountLabel => _t(' destinataire(s)', ' recipient(s)');
  // Annonces Admin – correspondance exacte avec le code
  String get announcementsAndNotifications => _t('Annonces & Notifications', 'Announcements & Notifications');
  String get sendImportantNotificationsToStudents => _t('Envoyez des notifications importantes aux étudiants', 'Send important notifications to students');
  String get deleteAnnouncement => _t('Supprimer l\'annonce', 'Delete announcement');
  String get confirmDeleteAnnouncement => _t('Voulez-vous vraiment supprimer cette annonce ?', 'Do you really want to delete this announcement?');
  String get announcementDeletedSuccess => _t('Annonce supprimée avec succès', 'Announcement deleted successfully');
  String destinatairesCount(int count) => _t('$count destinataire(s)', '$count recipient(s)');
  String sendingToAll(int count) => _t('Envoi à tous les étudiants ($count)', 'Sending to all students ($count)');
  String sendingToCenter(String centreName, int count) => _t('Envoi au centre: $centreName ($count étudiant(s))', 'Sending to center: $centreName ($count student(s))');
  String sendingToSelected(int count) => _t('Envoi à $count étudiant(s) sélectionné(s)', 'Sending to $count selected student(s)');
  String irreversibleAction(int count) => _t('Vous allez envoyer $count notifications. Cette action est irréversible.', 'You are about to send $count notifications. This action is irreversible.');
  String announcementSent(int count) => _t('Annonce envoyée à $count destinataire(s)', 'Announcement sent to $count recipient(s)');
  String centerSelected(String centreName) => _t('Centre: $centreName', 'Center: $centreName');

  // Paiements Admin
  String get searchStudentReference => _t('Rechercher un étudiant, référence...', 'Search student, reference...');
  String get hideFilters => _t('Masquer filtres', 'Hide filters');
  String get moreFilters => _t('Plus de filtres', 'More filters');
  String get reset => _t('Reinitialiser', 'Reset');
  String get export => _t('Exporter', 'Export');
  String get advancedFilters => _t('Filtres avances', 'Advanced filters');
  String get startDate => _t('Date debut', 'Start date');
  String get endDate => _t('Date fin', 'End date');
  String get select => _t('Selectionner', 'Select');
  String get apply => _t('Appliquer', 'Apply');
  String get student => _t('Étudiant', 'Student');
  String get actions => _t('Actions', 'Actions');
  String get viewDetails => _t('Voir details', 'View details');
  String get fullDetails => _t('Details complets', 'Full details');
  String get markAsFailed => _t('Marquer comme echec', 'Mark as failed');
  String get exportReceipt => _t('Exporter recu', 'Export receipt');
  String totalPaymentsCount(int count) => _t('Total: $count paiements', 'Total: $count payments');
  String pageOf(int current, int total) => _t('Page $current / $total', 'Page $current / $total');
  String centerRoom(String centre, String chambre) => _t('$centre - Ch. $chambre', '$centre - Rm. $chambre');
  String get noPaymentsFound => _t('Aucun paiement trouve', 'No payments found');
  String get adjustFiltersOrWait => _t('Ajustez vos filtres ou attendez de nouveaux paiements', 'Adjust your filters or wait for new payments');
  String get resetFilters => _t('Reinitialiser les filtres', 'Reset filters');
  String get pendingStatus => _t('En attente', 'Pending');
  String get confirmedStatus => _t('Confirme', 'Confirmed');
  String get failedStatus => _t('Echec', 'Failed');
  String get all => _t('Tous', 'All');
  String get orangeMoney => _t('Orange Money', 'Orange Money');
  String get moovMoney => _t('Moov Money', 'Moov Money');
  String get cash => _t('Especes', 'Cash');
  String get transfer => _t('Virement', 'Transfer');
  String get paymentType => _t('Type paiement', 'Payment type');
  String get rent => _t('Loyer', 'Rent');
  String get paymentDate => _t('Date paiement', 'Payment date');
  String get notDefined => _t('Non définie', 'Not defined');
  String get monthlyPrice => _t('Prix mensuel', 'Monthly price');
  String get city => _t('Ville', 'City');
  String get confirmPaymentTitle => _t('Confirmer le paiement', 'Confirm payment');
  String get confirmPaymentQuestion => _t('Etes-vous sur de vouloir confirmer ce paiement ?', 'Are you sure you want to confirm this payment?');
  String get optionalComment => _t('Commentaire (optionnel)', 'Comment (optional)');
  String get paymentConfirmedSuccess => _t('Paiement confirme avec succes', 'Payment confirmed successfully');
  String get markAsFailedTitle => _t('Marquer comme echec', 'Mark as failed');
  String get indicateFailureReason => _t('Veuillez indiquer la raison de l\'echec :', 'Please indicate the reason for failure:');
  String get reason => _t('Raison', 'Reason');
  String get failureReasonHint => _t('Ex: Transaction expiree, montant incorrect...', 'Ex: Expired transaction, incorrect amount...');
  String get validate => _t('Valider', 'Validate');
  String get paymentMarkedAsFailed => _t('Paiement marque comme echec', 'Payment marked as failed');
  String exportReceiptFor(String ref) => _t('Export du recu pour $ref', 'Export receipt for $ref');
  String get noPaymentsToExport => _t('Aucun paiement a exporter', 'No payments to export');
  String get exportPayments => _t('Exporter les paiements', 'Export payments');
  String get chooseExportFormat => _t('Choisissez le format d\'export :', 'Choose export format:');
  String generatingFormat(String format) => _t('Generation $format en cours...', 'Generating $format...');
  String get exportError => _t('Erreur lors de l\'export', 'Export error');
  String get successRate => _t('Taux Reussite', 'Success Rate');
  String get rate => _t('Taux', 'Rate');

// Export Preview
  String exportPreviewTitle(String format) => _t('Aperçu Export $format', 'Export Preview $format');
  String get generateAndDownload => _t('Générer et télécharger', 'Generate and download');
  String get generatingInProgress => _t('Génération en cours...', 'Generation in progress...');
  String get pleaseWait => _t('Veuillez patienter', 'Please wait');
  String get paymentReportTitle => _t('Rapport des Paiements CENOU', 'CENOU Payments Report');
  String formatLabel(String format) => _t('Format: $format', 'Format: $format');
  String generatedOn(String date) => _t('Généré le $date', 'Generated on $date');
  String get appliedFilters => _t('Filtres appliqués:', 'Applied filters:');
  String get dataPreview => _t('Aperçu des données', 'Data preview');
  String paymentsFound(int count) => _t('$count paiements trouvés', '$count payments found');
  String andMorePayments(int count) => _t('... et $count autres paiements', '... and $count more payments');
  String get viewFullPreview => _t('Voir l\'aperçu complet', 'View full preview');
  String get exportWebOnly => _t('Export disponible uniquement sur web', 'Export available only on web');
  String formatNotAvailable(String format) => _t('Format $format pas encore disponible.\nVeuillez utiliser PDF ou CSV pour le moment.', 'Format $format not yet available.\nPlease use PDF or CSV for now.');
  String unsupportedFormat(String format) => _t('Format non supporté: $format', 'Unsupported format: $format');
  String generateSuccess(String format) => _t('✅ $format généré avec succès', '✅ $format generated successfully');
  String generationError(String error) => _t('Erreur lors de la génération: $error', 'Generation error: $error');
  String get shareReport => _t('Partager le rapport', 'Share report');
  String get featureInDevelopment => _t('Cette fonctionnalité est en cours de développement.', 'This feature is under development.');
  String get fromDate => _t('À partir du', 'From');
  String get toDate => _t('Jusqu\'au', 'To');
  String get search => _t('Recherche', 'Search');
  String get roomType => _t('Type chambre', 'Room type');

// Dialogue d'envoi – étapes
  String get message => _t('Message', 'Message');
  String get summary => _t('Résumé', 'Summary');

// Dialogue d'envoi – Message
  String get announcementTitle => _t('Titre de l\'annonce', 'Announcement title');
  String get titleExample => _t('Ex: Coupure d\'eau programmée ce soir', 'Ex: Scheduled water outage tonight');
  String get messageContent => _t('Contenu du message', 'Message content');
  String get writeDetailedContent => _t('Rédigez le contenu détaillé de votre annonce...', 'Write the detailed content of your announcement...');
  String get writingTip => _t('Conseil : Rédigez un titre accrocheur et un message clair pour maximiser l\'engagement', 'Tip: Write a catchy title and a clear message to maximize engagement');

// Dialogue d'envoi – Destinataires
  String get selectWhoWillReceive => _t('Sélectionnez qui recevra cette annonce', 'Select who will receive this announcement');
  String get noCentersAvailable => _t('Aucun centre disponible. Vérifiez la connexion.', 'No centers available. Check connection.');
  String get pleaseSelectCenter => _t('Veuillez sélectionner un centre', 'Please select a center');
  String selectedCenter(String centreName) => _t('Centre: $centreName', 'Center: $centreName');
  String get custom => _t('Personnalisée', 'Custom');
  String studentInfo(String matricule, String centre) => _t('$matricule • $centre', '$matricule • $centre');
  String get searchByNameOrMatricule => _t('Rechercher par nom ou matricule...', 'Search by name or student ID...');
  String get none => _t('Aucun', 'None');
  String sendToAllStudents(int count) => _t('Envoi à tous les étudiants ($count)', 'Sending to all students ($count)');
  String sendToCenter(String centreName, int count) => _t('Envoi au centre: $centreName ($count étudiant(s))', 'Sending to center: $centreName ($count student(s))');
  String sendToSelectedStudents(int count) => _t('Envoi à $count étudiant(s) sélectionné(s)', 'Sending to $count selected student(s)');
  String get pleaseSelectAtLeastOneStudent => _t('Veuillez sélectionner au moins un étudiant', 'Please select at least one student');
  String get allStudents => _t('Tous les étudiants', 'All students');
  String centerColon(String centreName) => _t('Centre : $centreName', 'Center: $centreName');
  String selectedStudentsCount(int count) => _t('$count étudiant(s) sélectionné(s)', '$count selected student(s)');
  String announcementSentTo(int count) => _t('Annonce envoyée à $count destinataire(s)', 'Announcement sent to $count recipient(s)');
  String get noStudentMatchesSearch => _t('Aucun étudiant ne correspond à votre recherche', 'No students match your search');
  String get sendingInProgress => _t('Envoi en cours...', 'Sending...');
  String massNotificationWarning(int count) => _t('Vous allez envoyer $count notifications. Cette action est irréversible.', 'You are about to send $count notifications. This action is irreversible.');
  String get verifyInfoBeforeSending => _t('Vérifiez les informations avant l\'envoi', 'Verify information before sending');
  String get generalAnnouncement => _t('Générale', 'General');
  String notificationsWillBeSent(int count) => _t('$count notification(s) seront envoyées', '$count notification(s) will be sent');
  String get date => _t('Date', 'Date');

  // Rapports
  String get financialReport => _t('Rapport Financier', 'Financial Report');
  String get occupancyReport => _t('Rapport d\'Occupation', 'Occupancy Report');
  String get analysisPeriod => _t('Période d\'analyse', 'Analysis period');
  String get currentMonth => _t('Mois en cours', 'Current month');
  String get lastMonth => _t('Mois dernier', 'Last month');
  String get quarter => _t('Trimestre', 'Quarter');
  String get selectDate => _t('Sélectionner une date', 'Select a date');
  String get centerOptional => _t('Centre (optionnel)', 'Center (optional)');
  String get generateReport => _t('Générer le rapport', 'Generate report');
  String get importantInformation => _t('Informations importantes', 'Important information');
  String get reportInfoMessage => _t('Les rapports sont générés en temps réel avec les données actualisées. Les fichiers PDF sont optimisés pour l\'impression, tandis que les fichiers Excel contiennent les données brutes pour analyse approfondie.', 'Reports are generated in real time with up-to-date data. PDF files are optimized for printing, while Excel files contain raw data for in-depth analysis.');
  String get financialReportGenerated => _t('Rapport financier généré avec succès', 'Financial report generated successfully');
  String get occupancyReportGenerated => _t('Rapport d\'occupation généré avec succès', 'Occupancy report generated successfully');
  String reportFormatTitle(String reportType) => _t('Format du rapport $reportType', 'Report format $reportType');
  String get pdfFormatDescription => _t('Format optimisé pour l\'impression', 'Format optimized for printing');
  String get excelFormatDescription => _t('Format modifiable avec données brutes', 'Editable format with raw data');
  String get occupancyReportDescription => _t('Analysez le taux d\'occupation, les logements disponibles et les attributions en cours.', 'Analyze occupancy rate, available housing, and current assignments.');

  // Signalements Admin
  String get searchReportHint => _t('Rechercher étudiant, numéro de suivi, description...', 'Search student, tracking number, description...');
  String get totalReports => _t('Total Signalements', 'Total Reports');
  String get resolutionRate => _t('Taux Résolution', 'Resolution Rate');
  String get takeCharge => _t('Prendre en charge', 'Take charge');
  String get cancelReport => _t('Annuler le signalement', 'Cancel report');
  String get markAsResolved => _t('Marquer comme résolu', 'Mark as resolved');
  String get viewPhotos => _t('Voir les photos', 'View photos');
  String totalReportsCount(int count) => _t('Total: $count signalements', 'Total: $count reports');
  String get noReportsFound => _t('Aucun signalement trouvé', 'No reports found');
  String get localization => _t('Localisation', 'Location');
  String get problem => _t('Problème', 'Problem');
  String get fullName => _t('Nom complet', 'Full name');
  String get descriptionLabel => _t('Description', 'Description');
  String get statusLabel => _t('Statut', 'Status');
  String get creationDate => _t('Date création', 'Creation date');
  String get resolutionDate => _t('Date résolution', 'Resolution date');
  String get comment => _t('Commentaire', 'Comment');
  String get noPhotosAvailable => _t('Aucune photo disponible', 'No photos available');
  String photoCount(int count) => _t('$count photo${count > 1 ? "s" : ""}', '$count photo${count > 1 ? "s" : ""}');
  String reportStatusUpdated(String status) => _t('Signalement ${status.toLowerCase()} avec succès', 'Report ${status.toLowerCase()} successfully');
  String get resolutionComment => _t('Commentaire de résolution', 'Resolution comment');
  String get cancellationReason => _t('Raison de l\'annulation', 'Cancellation reason');
  String get describeResolution => _t('Décrivez comment le problème a été résolu...', 'Describe how the problem was resolved...');
  String get indicateCancellationReason => _t('Indiquez la raison de l\'annulation...', 'Indicate the reason for cancellation...');
  String get dataRefreshed => _t('Données actualisées avec succès', 'Data refreshed successfully');

// Statuts
  String get resolvedStatus => _t('Résolu', 'Resolved');
  String get cancelledStatus => _t('Annulé', 'Cancelled');

  // User Admin Screen
  String get searchUserHint => _t('Rechercher nom, matricule, email...', 'Search name, student ID, email...');
  String get newUser => _t('Nouveau', 'New');
  String get managers => _t('Gestionnaires', 'Managers');
  String get admins => _t('Admins', 'Admins');
  String get otherFilterOptions => _t('Autres options de filtrage seront ajoutées ici', 'Other filtering options will be added here');
  String get user => _t('Utilisateur', 'User');
  String get dateCreation => _t('Date création', 'Creation date');
  String get deactivate => _t('Désactiver', 'Deactivate');
  String get suspend => _t('Suspendre', 'Suspend');
  String get reactivate => _t('Réactiver', 'Reactivate');
  String get noUsersFound => _t('Aucun utilisateur trouvé', 'No users found');
  String get adjustFiltersOrCreate => _t('Ajustez vos filtres ou créez un nouvel utilisateur', 'Adjust filters or create a new user');
  String get createNewUser => _t('Créer un nouvel utilisateur', 'Create a new user');
  String get userDetails => _t('Détails de l\'utilisateur', 'User details');
  String get personalInformation => _t('Informations personnelles', 'Personal information');
  String get account => _t('Compte', 'Account');
  String get lastModification => _t('Dernière modification', 'Last modification');
  String get housing => _t('Logement', 'Housing');
  String get roomNumber => _t('Numéro de chambre', 'Room number');
  String get confirmModification => _t('Confirmer la modification', 'Confirm modification');
  String confirmStatusChange(String status) => _t('Voulez-vous vraiment ${status.toLowerCase()} cet utilisateur ?', 'Do you really want to ${status.toLowerCase()} this user?');
  String userStatusUpdated(String status) => _t('Utilisateur ${status.toLowerCase()} avec succès', 'User ${status.toLowerCase()} successfully');
  String get confirmDeletion => _t('Confirmer la suppression', 'Confirm deletion');
  String get confirmDeleteUser => _t('Voulez-vous vraiment supprimer définitivement cet utilisateur ?\nCette action est irréversible.', 'Do you really want to permanently delete this user?\nThis action is irreversible.');
  String get userDeleted => _t('Utilisateur supprimé avec succès', 'User deleted successfully');
  String get sendAnnouncementTo => _t('Envoyer une annonce à', 'Send announcement to');
  String get title => _t('Titre *', 'Title *');
  String get announcementSentToUser => _t('Annonce envoyée à', 'Announcement sent to');
  String get fillAllFields => _t('Veuillez remplir tous les champs', 'Please fill in all fields');
  String get newStudent => _t('Nouvel étudiant', 'New student');
  String get fillStudentInfo => _t('Remplissez les informations de l\'étudiant', 'Fill in student information');
  String get matriculeRequired => _t('Le matricule est requis', 'Student ID is required');
  String get matriculeMinLength => _t('Au moins 5 caractères', 'At least 5 characters');
  String get lastNameRequired => _t('Le nom est requis', 'Last name is required');
  String get lastNameMinLength => _t('Au moins 2 caractères', 'At least 2 characters');
  String get firstNameRequired => _t('Le prénom est requis', 'First name is required');
  String get firstNameMinLength => _t('Au moins 2 caractères', 'At least 2 characters');
  String get housingOptional => _t('Logement (optionnel)', 'Housing (optional)');
  String get noHousingAvailable => _t('Aucun logement disponible', 'No housing available');
  String get generatePassword => _t('Générer un mot de passe automatiquement', 'Generate password automatically');
  String get passwordLabel => _t('Mot de passe *', 'Password *');
  String get passwordUppercase => _t('Au moins une majuscule', 'At least one uppercase');
  String get passwordDigit => _t('Au moins un chiffre', 'At least one digit');
  String get confirmPasswordLabel => _t('Confirmer le mot de passe *', 'Confirm password *');
  String get confirmPasswordRequired => _t('Confirmation requise', 'Confirmation required');
  String get passwordsMismatch => _t('Les mots de passe ne correspondent pas', 'Passwords do not match');
  String get securePasswordGenerated => _t('Un mot de passe sécurisé sera généré automatiquement.', 'A secure password will be generated automatically.');
  String get createStudent => _t('Créer l\'étudiant', 'Create student');
  String get creating => _t('Création...', 'Creating...');
  String get studentCreated => _t('Étudiant créé avec succès', 'Student created successfully');
  String get editUser => _t('Modifier l\'utilisateur', 'Edit user');
  String get saving => _t('Enregistrement...', 'Saving...');
  String get userUpdated => _t('Utilisateur mis à jour avec succès', 'User updated successfully');
  String get confirmAction => _t('Confirmer', 'Confirm');
  String get deleteAction => _t('Supprimer', 'Delete');
  String get studentRole => _t('Étudiant', 'Student');
  String get managerRole => _t('Gestionnaire', 'Manager');
  String get adminRole => _t('Administrateur', 'Administrator');
  String get activeStatus => _t('Actif', 'Active');
  String get inactiveStatus => _t('Inactif', 'Inactive');
  String get suspendedStatus => _t('Suspendu', 'Suspended');
  String get noCenter => _t('Aucun centre', 'No center');
  String get noHousing => _t('Aucun logement', 'No housing');

  // Activités récentes
  String get justNow => _t('À l\'instant', 'Just now');
  String timeWeeksAgo(int weeks) => _t('Il y a $weeks sem', '$weeks wk ago');
  String timeMonthsAgo(int months) => _t('Il y a $months mois', '$months mo ago');
  String get unknownRoom => _t('Chambre inconnue', 'Unknown room');
  String get unknownUser => _t('Utilisateur inconnu', 'Unknown user');
  String get unknownActivity => _t('Activité inconnue', 'Unknown activity');
  String get reportResolved => _t('Signalement résolu', 'Report resolved');
  String get reportAssigned => _t('Signalement affecté', 'Report assigned');
  String reportCreatedDesc(String type, String room) => _t('Signalement $type - $room', '$type report - $room');
  String paymentConfirmedDesc(String amount, String room) => _t('Paiement de $amount FCFA - $room', 'Payment of $amount FCFA - $room');
  String paymentInitiatedDesc(String amount, String room) => _t('Paiement initié de $amount FCFA - $room', 'Payment initiated of $amount FCFA - $room');
  String userCreatedDesc(String user) => _t('$user a été créé', '$user was created');
  String reportResolvedDesc(String type) => _t('Signalement $type résolu', '$type report resolved');
  String reportAssignedDesc(String type) => _t('Signalement $type affecté', '$type report assigned');
  String get newReport => _t('Nouveau signalement', 'New report');
  // ── Activités (contexte dashboard) ────────────────────────────────────────
  String get actNewUser       => _t('Nouvel utilisateur', 'New user');
  String get actPaymentConf   => _t('Paiement confirmé', 'Payment confirmed');
  String get actPaymentInit   => _t('Paiement initié', 'Payment initiated');
  String get actReportCreated => _t('Nouveau signalement', 'New report');
  String get actReportResolved=> _t('Signalement résolu', 'Report resolved');
  String get actReportAssigned=> _t('Signalement affecté', 'Report assigned');

// Description inscription (format API : "Inscription: NOM PRENOM (ROLE)")
  String registrationDesc(String name, String role) =>
      _t('Inscription : $name ($role)', 'Registration: $name ($role)');

  String get dashboard => _t('Tableau de bord', 'Dashboard');
  String get users => _t('Utilisateurs', 'Users');
  String get announcements => _t('Annonces', 'Announcements');
  String get reportsStats => _t('Rapports', 'Reports');
  String get adminDashboard => _t('Dashboard Admin', 'Admin Dashboard');
  String get admin => _t('Admin', 'Admin');
  String get manager => _t('Gestionnaire', 'Manager');
  String get paymentManagement => _t('Gestion des Paiements', 'Payment Management');
  String get reportManagement => _t('Gestion des Signalements', 'Report Management');
  String get userManagement => _t('Gestion des Utilisateurs', 'User Management');
  String get announcementManagement => _t('Gestion des Annonces', 'Announcement Management');
  String get reportsStatistics => _t('Rapports & Statistiques', 'Reports & Statistics');
  String get systemSettings => _t('Paramètres du Système', 'System Settings');
  String get welcomeDashboard => _t('Bienvenue sur le Dashboard', 'Welcome to the Dashboard');
  String get manageResidencesRealtime => _t('Gérez vos résidences universitaires en temps réel.', 'Manage your university residences in real time.');
  String get totalStudents => _t('Total Étudiants', 'Total Students');
  String get activeReports => _t('Signalements Actifs', 'Active Reports');
  String get revenue30Days => _t('Revenus 30j', 'Revenue 30d');
  String get monthlyRevenue => _t('Revenus Mensuels', 'Monthly Revenue');
  String get reportsByType => _t('Signalements par Type', 'Reports by Type');
  String get problemDistribution => _t('Distribution des problèmes signalés', 'Reported problem distribution');
  String get recentActivity => _t('Activité Récente', 'Recent Activity');
  String get viewAllActivities => _t('Voir toutes les activités', 'View all activities');
  String get noRecentActivity => _t('Aucune activité récente', 'No recent activity');
  String get newActivitiesWillAppear => _t('Les nouvelles activités apparaîtront ici', 'New activities will appear here');
  String get noData => _t('Aucune donnée', 'No data');
  String get noDataAvailable => _t('Aucune donnée disponible', 'No data available');
  String get reportsTooltipFormat => _t('point.x : point.y signalements', 'point.x : point.y reports');
  String get mustReconnect => _t('Vous devrez vous reconnecter pour accéder au dashboard.', 'You will need to log in again to access the dashboard.');
  String get featureComingSoon => _t('Cette fonctionnalité sera disponible prochainement.', 'This feature will be available soon.');
  String get web => _t('Web', 'Web');
  String get receiveImportantAlerts => _t('Recevoir les alertes importantes', 'Receive important alerts');
  String get interfaceTheme => _t('Thème de l\'interface', 'Interface theme');
  String get selectInterfaceTheme => _t('Sélectionnez le thème de l\'interface administrateur', 'Select the admin interface theme');
  String get selectInterfaceLanguage => _t('Sélectionnez la langue de l\'interface', 'Select the interface language');
  String get french => _t('Français', 'French');
  String get english => _t('English', 'English');
  String get accountSecurity => _t('Compte & Sécurité', 'Account & Security');
  String lastChangeDaysAgo(int days) => _t('Dernière modification: il y a $days jours', 'Last change: $days days ago');
  String occupancyRate(String rate) => _t('$rate% occ.', '$rate% occ.');
  String resolvedCount(String count) => _t('$count résolus', '$count resolved');
  String averageRevenue(String amount) => _t('Moy: $amount', 'Avg: $amount');
  String get occupancy => _t('occ.', 'occ.');
  String languageChanged(String language) =>
      _t('Langue changée en $language', 'Language changed to $language');
  String get weekdaysShort => _t('Lun,Mar,Mer,Jeu,Ven,Sam,Dim', 'Mon,Tue,Wed,Thu,Fri,Sat,Sun');
  String get monthsShort => _t('Jan,Fév,Mar,Avr,Mai,Juin,Juil,Août,Sep,Oct,Nov,Déc', 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec');


}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}