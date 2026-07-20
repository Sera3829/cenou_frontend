import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/admin_user.dart';
import 'package:cenou_mobile/models/admin/centre.dart';
import 'package:cenou_mobile/providers/auth_provider.dart';
import 'package:cenou_mobile/providers/web/user_admin_provider.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/utils/user_display.dart';
import 'user_form_fields.dart';

IconData _roleIcon(String role) {
  switch (role) {
    case 'ADMIN':
      return Icons.admin_panel_settings;
    case 'GESTIONNAIRE':
      return Icons.manage_accounts;
    default:
      return Icons.school;
  }
}

String _createdMessage(String role, AppLocalizations l10n) {
  switch (role) {
    case 'ADMIN':
      return l10n.adminCreated;
    case 'GESTIONNAIRE':
      return l10n.managerCreated;
    default:
      return l10n.studentCreated;
  }
}

/// Dialogue de création d'un utilisateur (étudiant / gestionnaire / admin).
Future<void> showCreateUserDialog(BuildContext context, AppLocalizations l10n) async {
  final provider = Provider.of<UserAdminProvider>(context, listen: false);
  final authProv = Provider.of<AuthProvider>(context, listen: false);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isAdmin = authProv.isAdmin; // seul ADMIN peut créer ADMIN/GESTIONNAIRE

  if (provider.centres.isEmpty) await provider.loadCentres();

  final matriculeController = TextEditingController();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final telephoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final availableRoles =
      isAdmin ? ['ETUDIANT', 'GESTIONNAIRE', 'ADMIN'] : ['ETUDIANT'];

  String selectedRole = 'ETUDIANT';
  String selectedStatut = 'ACTIF';
  int? selectedCentreId;
  int? selectedLogementId;
  bool generatePassword = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isSaving = false;
  List<Map<String, dynamic>> availableLogements = [];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        String dialogTitle;
        String dialogSubtitle;
        IconData dialogIcon;
        switch (selectedRole) {
          case 'ADMIN':
            dialogTitle = l10n.newAdmin;
            dialogSubtitle = l10n.fillAdminInfo;
            dialogIcon = Icons.admin_panel_settings;
            break;
          case 'GESTIONNAIRE':
            dialogTitle = l10n.newManager;
            dialogSubtitle = l10n.fillManagerInfo;
            dialogIcon = Icons.manage_accounts;
            break;
          default:
            dialogTitle = l10n.newStudent;
            dialogSubtitle = l10n.fillStudentInfo;
            dialogIcon = Icons.school;
        }

        final isEtudiant = selectedRole == 'ETUDIANT';
        final isGestionnaire = selectedRole == 'GESTIONNAIRE';

        return Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(dialogIcon,
                            color: Theme.of(context).colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dialogTitle,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextPrimary(context))),
                            const SizedBox(height: 4),
                            Text(dialogSubtitle,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(context))),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Sélecteur de rôle (ADMIN uniquement) ──
                    if (isAdmin) ...[
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: userDropdownDecoration(context, l10n.role, Icons.badge, isDark),
                        dropdownColor: AppTheme.getCardBackground(context),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        items: availableRoles
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Row(children: [
                                    Icon(_roleIcon(r), size: 16, color: userRoleColor(r)),
                                    const SizedBox(width: 8),
                                    Text(userRoleLabel(r, l10n),
                                        style: TextStyle(color: AppTheme.getTextPrimary(context))),
                                  ]),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          selectedRole = v!;
                          if (selectedRole != 'ETUDIANT') {
                            selectedLogementId = null;
                            availableLogements = [];
                          }
                          if (selectedRole == 'ADMIN') {
                            selectedCentreId = null;
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Matricule ──
                    userFormField(
                      context,
                      controller: matriculeController,
                      label: '${l10n.matricule} *',
                      hint:
                          'Ex: ${selectedRole == 'ETUDIANT' ? 'ETUD2024001' : selectedRole == 'GESTIONNAIRE' ? 'GEST001' : 'ADMIN001'}',
                      icon: Icons.badge,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.matriculeRequired;
                        if (v.trim().length < 5) return l10n.matriculeMinLength;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Nom + Prénom ──
                    Row(children: [
                      Expanded(
                        child: userFormField(
                          context,
                          controller: nomController,
                          label: '${l10n.lastName} *',
                          hint: l10n.lastNameHint,
                          icon: Icons.person,
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.lastNameRequired;
                            if (v.trim().length < 2) return l10n.lastNameMinLength;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: userFormField(
                          context,
                          controller: prenomController,
                          label: '${l10n.firstName} *',
                          hint: l10n.firstNameHint,
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.firstNameRequired;
                            if (v.trim().length < 2) return l10n.firstNameMinLength;
                            return null;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Email ──
                    userFormField(
                      context,
                      controller: emailController,
                      label: '${l10n.email} *',
                      hint: l10n.emailHint,
                      icon: Icons.email,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return l10n.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Téléphone ──
                    userFormField(
                      context,
                      controller: telephoneController,
                      label: l10n.phoneOptional,
                      hint: l10n.phoneHint,
                      icon: Icons.phone,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // ── Centre + Chambre (ETUDIANT, obligatoire) ──
                    if (isEtudiant) ...[
                      DropdownButtonFormField<int>(
                        value: selectedCentreId,
                        decoration: userDropdownDecoration(
                            context, '${l10n.center} *', Icons.location_city, isDark),
                        dropdownColor: AppTheme.getCardBackground(context),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        items: provider.centres
                            .map((centre) => DropdownMenuItem<int>(
                                  value: centre.id,
                                  child: Text(centre.nom,
                                      style: TextStyle(color: AppTheme.getTextPrimary(context))),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          setState(() {
                            selectedCentreId = value;
                            selectedLogementId = null;
                            availableLogements = [];
                          });
                          if (value != null) {
                            await provider.loadAvailableLogements(value);
                            setState(() => availableLogements = provider.availableLogements);
                          }
                        },
                        validator: (v) => v == null ? l10n.centerRequired : null,
                      ),
                      if (selectedCentreId != null) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedLogementId,
                          decoration:
                              userDropdownDecoration(context, '${l10n.room} *', Icons.home, isDark),
                          dropdownColor: AppTheme.getCardBackground(context),
                          style: TextStyle(color: AppTheme.getTextPrimary(context)),
                          items: availableLogements.isEmpty
                              ? [
                                  DropdownMenuItem<int>(
                                    value: null,
                                    child: Text(l10n.noHousingAvailable,
                                        style:
                                            TextStyle(color: AppTheme.getTextTertiary(context))),
                                  )
                                ]
                              : availableLogements
                                  .map((l) => DropdownMenuItem<int>(
                                        value: l['id'],
                                        child: Text(
                                          '${l10n.room} ${l['numero_chambre']} — ${l['type_chambre']} (${l['prix_mensuel']} FCFA/mois)',
                                          style: TextStyle(color: AppTheme.getTextPrimary(context)),
                                        ),
                                      ))
                                  .toList(),
                          onChanged: (v) => setState(() => selectedLogementId = v),
                          validator: (v) =>
                              v == null ? 'La chambre est obligatoire pour un étudiant' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // ── Centre (GESTIONNAIRE, obligatoire) ──
                    if (isGestionnaire) ...[
                      DropdownButtonFormField<int>(
                        value: selectedCentreId,
                        decoration: userDropdownDecoration(
                            context, '${l10n.center} *', Icons.location_city, isDark),
                        dropdownColor: AppTheme.getCardBackground(context),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        items: provider.centres
                            .map((centre) => DropdownMenuItem<int>(
                                  value: centre.id,
                                  child: Text(centre.nom,
                                      style: TextStyle(color: AppTheme.getTextPrimary(context))),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedCentreId = value),
                        validator: (v) => v == null ? l10n.centerRequired : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Mot de passe ──
                    CheckboxListTile(
                      value: generatePassword,
                      onChanged: (v) => setState(() {
                        generatePassword = v ?? true;
                        if (generatePassword) {
                          passwordController.clear();
                          confirmPasswordController.clear();
                        }
                      }),
                      title: Text(l10n.generatePassword,
                          style:
                              TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!generatePassword) ...[
                      const SizedBox(height: 8),
                      userPasswordField(
                        context,
                        controller: passwordController,
                        label: l10n.passwordLabel,
                        hint: l10n.passwordHint,
                        isVisible: isPasswordVisible,
                        isDark: isDark,
                        onToggle: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        validator: (v) {
                          if (!generatePassword) {
                            if (v == null || v.trim().isEmpty) return l10n.passwordRequired;
                            if (v.length < 6) return l10n.passwordMinLength;
                            if (!RegExp(r'[A-Z]').hasMatch(v)) return l10n.passwordUppercase;
                            if (!RegExp(r'[0-9]').hasMatch(v)) return l10n.passwordDigit;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      userPasswordField(
                        context,
                        controller: confirmPasswordController,
                        label: l10n.confirmPasswordLabel,
                        hint: l10n.confirmPasswordHint,
                        isVisible: isConfirmPasswordVisible,
                        isDark: isDark,
                        icon: Icons.lock_outline,
                        onToggle: () =>
                            setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                        validator: (v) {
                          if (!generatePassword) {
                            if (v == null || v.trim().isEmpty) return l10n.confirmPasswordRequired;
                            if (v != passwordController.text) return l10n.passwordsMismatch;
                          }
                          return null;
                        },
                      ),
                    ],
                    if (generatePassword) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(l10n.securePasswordGenerated,
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Boutons ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: Text(l10n.cancel,
                              style: TextStyle(color: AppTheme.getTextSecondary(context))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    if (isEtudiant && selectedLogementId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: const Text('Veuillez sélectionner une chambre'),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                      return;
                                    }
                                    final sm = ScaffoldMessenger.of(context);
                                    setState(() => isSaving = true);
                                    try {
                                      await provider.createUser(
                                        matricule: matriculeController.text.trim(),
                                        nom: nomController.text.trim(),
                                        prenom: prenomController.text.trim(),
                                        email: emailController.text.trim(),
                                        telephone: telephoneController.text.trim().isEmpty
                                            ? null
                                            : telephoneController.text.trim(),
                                        role: selectedRole,
                                        statut: selectedStatut,
                                        motDePasse: generatePassword
                                            ? null
                                            : passwordController.text.trim(),
                                        centreId: (isEtudiant || isGestionnaire)
                                            ? selectedCentreId
                                            : null,
                                        logementId: isEtudiant ? selectedLogementId : null,
                                        dateDebut: isEtudiant && selectedLogementId != null
                                            ? DateTime.now().toIso8601String()
                                            : null,
                                      );
                                      Navigator.pop(context);
                                      sm.showSnackBar(SnackBar(
                                        content: Text(_createdMessage(selectedRole, l10n)),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    } catch (e) {
                                      setState(() => isSaving = false);
                                      sm.showSnackBar(SnackBar(
                                        content: Text('${l10n.error}: $e'),
                                        backgroundColor: const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(isSaving ? l10n.creating : l10n.createUser,
                              style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  matriculeController.dispose();
  nomController.dispose();
  prenomController.dispose();
  emailController.dispose();
  telephoneController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
}

/// Dialogue d'édition d'un utilisateur existant.
Future<void> showEditUserDialog(
    BuildContext context, AdminUser user, UserAdminProvider provider, AppLocalizations l10n) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (provider.centres.isEmpty) await provider.loadCentres();

  final matriculeController = TextEditingController(text: user.matricule);
  final nomController = TextEditingController(text: user.nom);
  final prenomController = TextEditingController(text: user.prenom);
  final emailController = TextEditingController(text: user.email);
  final telephoneController = TextEditingController(text: user.telephone);
  final formKey = GlobalKey<FormState>();

  String selectedRole = user.role;
  String selectedStatut = user.statut;
  int? selectedCentreId;

  if (user.centreNom != null && user.centreNom!.isNotEmpty) {
    final match = provider.centres
        .firstWhere((c) => c.nom == user.centreNom, orElse: () => Centre(id: 0, nom: ''));
    if (match.id != 0) selectedCentreId = match.id;
  }

  int? selectedLogementId;
  bool isSaving = false;
  List<Map<String, dynamic>> availableLogements = [];

  if (selectedCentreId != null) {
    await provider.loadAvailableLogements(selectedCentreId);
    availableLogements = provider.availableLogements;
    if (user.numeroChambre != null) {
      final cur = availableLogements.firstWhere(
          (l) => l['numero_chambre'] == user.numeroChambre,
          orElse: () => <String, dynamic>{});
      if (cur.isNotEmpty) selectedLogementId = cur['id'] as int?;
    }
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.editUser,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context))),
                          const SizedBox(height: 4),
                          Text(user.fullName,
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.getTextSecondary(context))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  // Matricule (non modifiable)
                  TextFormField(
                    controller: matriculeController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: l10n.matricule,
                      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                      prefixIcon: Icon(Icons.badge, color: AppTheme.getTextSecondary(context)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                    style: TextStyle(color: AppTheme.getTextTertiary(context)),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: userFormField(
                        context,
                        controller: nomController,
                        label: '${l10n.lastName} *',
                        icon: Icons.person,
                        isDark: isDark,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.lastNameRequired : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: userFormField(
                        context,
                        controller: prenomController,
                        label: '${l10n.firstName} *',
                        icon: Icons.person_outline,
                        isDark: isDark,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.firstNameRequired : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  userFormField(
                    context,
                    controller: emailController,
                    label: '${l10n.email} *',
                    icon: Icons.email,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                        return l10n.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  userFormField(
                    context,
                    controller: telephoneController,
                    label: l10n.phone,
                    icon: Icons.phone,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Rôle (non modifiable — affichage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Row(children: [
                      Icon(Icons.badge, color: AppTheme.getTextSecondary(context), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.role,
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.getTextSecondary(context))),
                            const SizedBox(height: 4),
                            Text(userRoleLabel(selectedRole, l10n),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.getTextPrimary(context),
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatut,
                    decoration: userDropdownDecoration(context, l10n.status, Icons.circle, isDark),
                    dropdownColor: AppTheme.getCardBackground(context),
                    items: ['ACTIF', 'INACTIF', 'SUSPENDU'].map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(userStatutLabel(s, l10n),
                            style: TextStyle(
                                color: userStatutColor(s), fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedStatut = v!),
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedCentreId,
                    decoration:
                        userDropdownDecoration(context, l10n.center, Icons.location_city, isDark),
                    dropdownColor: AppTheme.getCardBackground(context),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(l10n.noCenter)),
                      ...provider.centres.map((c) {
                        return DropdownMenuItem<int?>(value: c.id, child: Text(c.nom));
                      }),
                    ],
                    onChanged: (v) async {
                      setState(() {
                        selectedCentreId = v;
                        selectedLogementId = null;
                        availableLogements = [];
                      });
                      if (v != null) {
                        await provider.loadAvailableLogements(v);
                        setState(() => availableLogements = provider.availableLogements);
                      }
                    },
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  if (selectedCentreId != null) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: selectedLogementId,
                      decoration:
                          userDropdownDecoration(context, l10n.housing, Icons.home, isDark),
                      dropdownColor: AppTheme.getCardBackground(context),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(l10n.noHousing)),
                        ...availableLogements.map((l) {
                          return DropdownMenuItem<int?>(
                            value: l['id'] as int,
                            child: Text(
                                '${l10n.room} ${l['numero_chambre']} - ${l['type_chambre']}'),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => selectedLogementId = v),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(context),
                        child: Text(l10n.cancel,
                            style: TextStyle(color: AppTheme.getTextSecondary(context))),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  final sm = ScaffoldMessenger.of(context);
                                  setState(() => isSaving = true);
                                  try {
                                    await provider.updateUser(
                                      userId: user.id,
                                      nom: nomController.text.trim(),
                                      prenom: prenomController.text.trim(),
                                      email: emailController.text.trim(),
                                      telephone: telephoneController.text.trim().isEmpty
                                          ? null
                                          : telephoneController.text.trim(),
                                      statut: selectedStatut,
                                      logementId: selectedLogementId,
                                    );
                                    Navigator.pop(context);
                                    sm.showSnackBar(SnackBar(
                                      content: Text(l10n.userUpdated),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  } catch (e) {
                                    setState(() => isSaving = false);
                                    sm.showSnackBar(SnackBar(
                                      content: Text('${l10n.error}: $e'),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(isSaving ? l10n.saving : l10n.save,
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  matriculeController.dispose();
  nomController.dispose();
  prenomController.dispose();
  emailController.dispose();
  telephoneController.dispose();
}
