import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/signalement_provider.dart';

/// Écran de profil utilisateur affichant les informations personnelles
/// et permettant la modification du profil ainsi que la déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(context, user, isDark),
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
      body: user == null
          ? const _ProfileLoadingState()
          : CustomScrollView(
        slivers: [
          // En-tête avec avatar
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user),
          ),

          // Section informations
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildInfoSection(user, isDark),
                const SizedBox(height: 32),
                _buildActionsSection(context, authProvider, isDark),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des informations personnelles.
  Widget _buildInfoSection(User user, bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Divider(
            height: 0,
            thickness: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          _buildInfoTile(
            icon: Icons.badge_rounded,
            title: 'Matricule',
            value: user.matricule,
            color: AppTheme.primaryColor,
            isDark: isDark,
          ),
          _buildInfoTile(
            icon: Icons.email_rounded,
            title: 'Adresse email',
            value: user.email,
            color: Colors.blue,
            isDark: isDark,
          ),
          if (user.telephone != null && user.telephone!.isNotEmpty)
            _buildInfoTile(
              icon: Icons.phone_rounded,
              title: 'Téléphone',
              value: user.telephone!,
              color: Colors.green,
              isDark: isDark,
            ),
          _buildInfoTile(
            icon: _getRoleIcon(user.role),
            title: 'Rôle',
            value: _formatRole(user.role),
            color: AppTheme.secondaryColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Construit la section des actions (paramètres, déconnexion).
  Widget _buildActionsSection(BuildContext context, AuthProvider authProvider, bool isDark) {
    return Column(
      children: [
        // Paramètres
        ListTile(
          onTap: () {
            Navigator.pushNamed(context, '/settings');
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.blue.shade700 : Colors.blue[50])!,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: isDark ? Colors.blue.shade300 : Colors.blue,
            ),
          ),
          title: Text(
            'Paramètres',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Personnaliser votre application',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.grey.shade600 : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: isDark ? Colors.blue[900]!.withOpacity(0.2) : Colors.blue[10],
        ),
        const SizedBox(height: 12),

        // Déconnexion
        ListTile(
          onTap: () => _showLogoutDialog(context, authProvider, isDark),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: isDark ? Colors.red.shade300 : AppTheme.errorColor,
            ),
          ),
          title: Text(
            'Déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: AppTheme.errorColor.withOpacity(isDark ? 0.1 : 0.05),
        ),
      ],
    );
  }

  /// Construit une ligne d'information avec icône, titre et valeur.
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? color.withOpacity(0.7) : color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la boîte de dialogue de modification du profil.
  void _showEditProfileDialog(BuildContext context, User? user, bool isDark) {
    if (user == null) return;

    final emailController = TextEditingController(text: user.email);
    final telephoneController = TextEditingController(text: user.telephone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit_rounded,
              color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Modifier le profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info : Nom et matricule non modifiables
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.blue.shade900 : Colors.blue.shade50).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le nom et le matricule ne peuvent pas être modifiés',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Champ Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ Téléphone
                TextFormField(
                  controller: telephoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 8) {
                        return 'Le numéro doit contenir au moins 8 chiffres';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              emailController.dispose();
              telephoneController.dispose();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              // Fermer le dialogue
              Navigator.pop(dialogContext);

              // Afficher overlay de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => PopScope(
                  canPop: false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mise à jour en cours...',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Appeler l'API de mise à jour
                final success = await authProvider.updateProfile(
                  email: emailController.text.trim(),
                  telephone: telephoneController.text.trim().isEmpty
                      ? null
                      : telephoneController.text.trim(),
                );

                // Fermer l'overlay
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (success) {
                  // Afficher succès
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text('Profil mis à jour avec succès'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  // Afficher erreur
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage ?? 'Erreur lors de la mise à jour',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } catch (e) {
                // Fermer l'overlay en cas d'erreur
                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                emailController.dispose();
                telephoneController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.blue.shade700 : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Retourne l'icône correspondant au rôle de l'utilisateur.
IconData _getRoleIcon(String role) {
  switch (role.toUpperCase()) {
    case 'ETUDIANT':
      return Icons.school_rounded;
    case 'GESTIONNAIRE':
      return Icons.business_center_rounded;
    case 'ADMIN':
      return Icons.admin_panel_settings_rounded;
    default:
      return Icons.person_rounded;
  }
}

/// Formate le rôle en libellé lisible.
String _formatRole(String role) {
  switch (role.toUpperCase()) {
    case 'ETUDIANT':
      return 'Étudiant';
    case 'GESTIONNAIRE':
      return 'Gestionnaire';
    case 'ADMIN':
      return 'Administrateur';
    default:
      return role;
  }
}

/// Affiche la boîte de dialogue de confirmation de déconnexion.
Future<void> _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isDark) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.logout_rounded,
            color: isDark ? Colors.red.shade300 : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(
            'Déconnexion',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        'Voulez-vous vraiment vous déconnecter ? '
            'Vous devrez vous reconnecter pour accéder à vos données.',
        style: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.red.shade700 : AppTheme.errorColor,
          ),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );

  if (result == true && context.mounted) {
    print('Deconnexion confirmee');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Déconnexion en cours...',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await authProvider.logout();

      if (context.mounted) {
        try {
          final paiementProvider = Provider.of<PaiementProvider>(context, listen: false);
        } catch (e) {
          print('PaiementProvider non trouve: $e');
        }

        try {
          final signalementProvider = Provider.of<SignalementProvider>(context, listen: false);
        } catch (e) {
          print('SignalementProvider non trouve: $e');
        }
      }

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      print('Erreur deconnexion: $e');

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// En-tête du profil avec avatar et statut.
class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor.withOpacity(0.5),
          ]
              : [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.initiales,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(user.statut),
                  size: 16,
                  color: _getStatusColor(user.statut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            user.nomComplet,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.matricule,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatStatus(user.statut),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIF':
        return Icons.check_circle_rounded;
      case 'INACTIF':
        return Icons.pause_circle_rounded;
      case 'SUSPENDU':
        return Icons.block_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIF':
        return Colors.green;
      case 'INACTIF':
        return Colors.orange;
      case 'SUSPENDU':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIF':
        return 'Compte actif';
      case 'INACTIF':
        return 'Compte inactif';
      case 'SUSPENDU':
        return 'Compte suspendu';
      default:
        return status;
    }
  }
}

/// État de chargement du profil.
class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement du profil...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}