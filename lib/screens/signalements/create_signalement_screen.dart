import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateSignalementScreen extends StatefulWidget {
  const CreateSignalementScreen({Key? key}) : super(key: key);

  @override
  State<CreateSignalementScreen> createState() => _CreateSignalementScreenState();
}

class _CreateSignalementScreenState extends State<CreateSignalementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _typeProbleme = 'PLOMBERIE';
  List<File> _photos = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _typesProblemes = [
    {'value': 'PLOMBERIE', 'label': 'Plomberie', 'icon': Icons.plumbing},
    {'value': 'ELECTRICITE', 'label': 'Électricité', 'icon': Icons.electrical_services},
    {'value': 'TOITURE', 'label': 'Toiture', 'icon': Icons.roofing},
    {'value': 'SERRURE', 'label': 'Serrure', 'icon': Icons.lock},
    {'value': 'MOBILIER', 'label': 'Mobilier', 'icon': Icons.chair},
    {'value': 'AUTRE', 'label': 'Autre', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 photos autorisées'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      String message = 'Erreur lors de l\'accès à la caméra';

      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('photo_access_denied')) {
        message = 'Accès à la caméra refusé. Veuillez l\'autoriser dans les paramètres de votre téléphone.';
      } else if (e.toString().contains('camera_access_restricted')) {
        message = 'L\'accès à la caméra est restreint sur cet appareil.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: e.toString().contains('denied') ? SnackBarAction(
              label: 'Paramètres',
              textColor: Colors.white,
              onPressed: () {
                // Ouvrir les paramètres de l'app
              },
            ) : null,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 photos autorisées'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      final remaining = 5 - _photos.length;
      setState(() {
        final toAdd = images.take(remaining).map((x) => File(x.path)).toList();
        _photos.addAll(toAdd);
      });

      if (images.length > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seulement $remaining photo(s) ajoutée(s) (max 5)'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter au moins une photo'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signalementProvider = Provider.of<SignalementProvider>(context, listen: false);

      final signalement = await signalementProvider.creerSignalement(
        typeProbleme: _typeProbleme,
        description: _descriptionController.text.trim(),
        photos: _photos,
      );

      if (!mounted) return;

      // Afficher succès
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Signalement créé',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre signalement a été enregistré avec succès.',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Numéro de suivi: ${signalement.numeroSuivi}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous serez notifié de son traitement.',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer dialog
                  Navigator.pop(context); // Retour à la liste
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Signaler un problème'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                elevation: isDark ? 4 : 0,
                color: isDark
                    ? AppTheme.infoColor.withOpacity(0.2)
                    : AppTheme.infoColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.infoColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Décrivez le problème et ajoutez des photos pour un traitement rapide',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade300 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Type de problème
              Text(
                'Type de problème',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildTypeProblemeSelector(isDark),
              const SizedBox(height: 24),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description détaillée',
                hint: 'Décrivez le problème en détail...',
                prefixIcon: Icons.description,
                maxLines: 5,
                maxLength: 1000,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  if (value.length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Photos
              Text(
                'Photos (${_photos.length}/5)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildPhotoSection(isDark),
              const SizedBox(height: 32),

              // Bouton de soumission
              CustomButton(
                text: 'CRÉER LE SIGNALEMENT',
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeProblemeSelector(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _typesProblemes.length,
      itemBuilder: (context, index) {
        final type = _typesProblemes[index];
        final isSelected = _typeProbleme == type['value'];

        return InkWell(
          onTap: () {
            setState(() {
              _typeProbleme = type['value'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: isSelected ? 4 : (isDark ? 2 : 1),
            color: isDark ? Color(0xFF1E1E1E) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppTheme.errorColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'],
                  color: isSelected
                      ? AppTheme.errorColor
                      : (isDark ? Colors.grey.shade400 : Colors.grey[600]),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  type['label'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.errorColor
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    return Column(
      children: [
        // Photos existantes
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _photos[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_photos.isNotEmpty) const SizedBox(height: 12),

        // Boutons d'ajout de photos
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _photos.length < 5 ? () => _pickImage(ImageSource.camera) : null,
                icon: Icon(
                  Icons.camera_alt,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                label: Text(
                  'Caméra',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _photos.length < 5 ? _pickMultipleImages : null,
                icon: Icon(
                  Icons.photo_library,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                label: Text(
                  'Galerie',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_photos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Ajoutez au moins une photo du problème',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}