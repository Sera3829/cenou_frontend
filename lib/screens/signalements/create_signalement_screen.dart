import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../utils/mobile_responsive.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Écran de création de signalement — responsive mobile/tablette.
class CreateSignalementScreen extends StatefulWidget {
  const CreateSignalementScreen({Key? key}) : super(key: key);

  @override
  State<CreateSignalementScreen> createState() =>
      _CreateSignalementScreenState();
}

class _CreateSignalementScreenState extends State<CreateSignalementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _typeProbleme = 'PLOMBERIE';
  List<File> _photos = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _typesProblemes = [
    {'value': 'PLOMBERIE',   'label': 'Plomberie',   'icon': Icons.plumbing},
    {'value': 'ELECTRICITE', 'label': 'Électricité', 'icon': Icons.electrical_services},
    {'value': 'TOITURE',     'label': 'Toiture',     'icon': Icons.roofing},
    {'value': 'SERRURE',     'label': 'Serrure',     'icon': Icons.lock},
    {'value': 'MOBILIER',    'label': 'Mobilier',    'icon': Icons.chair},
    {'value': 'AUTRE',       'label': 'Autre',       'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Sélection photo ──────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= 5) {
      _snack('Maximum 5 photos autorisées', bg: AppTheme.warningColor);
      return;
    }
    try {
      final image = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (image != null) setState(() => _photos.add(File(image.path)));
    } catch (e) {
      String msg = 'Erreur lors de l\'accès à la caméra';
      if (e.toString().contains('denied') || e.toString().contains('restricted')) {
        msg = 'Accès à la caméra refusé. Autorisez-le dans les paramètres.';
      }
      if (mounted) _snack(msg, bg: Colors.orange);
    }
  }

  Future<void> _pickMultiple() async {
    if (_photos.length >= 5) {
      _snack('Maximum 5 photos autorisées', bg: AppTheme.warningColor);
      return;
    }
    try {
      final images = await _picker.pickMultiImage(
          maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      final remaining = 5 - _photos.length;
      setState(() => _photos.addAll(images.take(remaining).map((x) => File(x.path))));
      if (images.length > remaining) {
        _snack('Seulement $remaining photo(s) ajoutée(s) (max 5)',
            bg: AppTheme.warningColor);
      }
    } catch (e) {
      _snack('Erreur: $e', bg: AppTheme.errorColor);
    }
  }

  void _snack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Soumission ───────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      _snack('Veuillez ajouter au moins une photo', bg: AppTheme.warningColor);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<SignalementProvider>(context, listen: false);
      final signalement = await provider.creerSignalement(
        typeProbleme: _typeProbleme,
        description: _descriptionController.text.trim(),
        photos: _photos,
      );
      if (!mounted) return;
      await _showSuccessDialog(signalement);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), bg: AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(dynamic signalement) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Signalement créé',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87))),
        ]),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre signalement a été enregistré avec succès.',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
              const SizedBox(height: 10),
              Text('Numéro de suivi: ${signalement.numeroSuivi}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 6),
              Text('Vous serez notifié de son traitement.',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
            ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Signaler un problème',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          final hPad = config.isSmall ? 14.0 : 20.0;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  hPad, config.isShortScreen ? 12 : 18, hPad, 24),
              child: config.isTablet
                  ? _buildTabletLayout(isDark, config)
                  : _buildMobileLayout(isDark, config),
            ),
          );
        },
      ),
    );
  }

  // ── Layout mobile : colonnes empilées ────────────────────────────────────
  Widget _buildMobileLayout(bool isDark, ResponsiveConfig config) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _InfoBanner(isDark: isDark, config: config),
      SizedBox(height: config.isShortScreen ? 16 : 22),

      _SectionLabel(text: 'Type de problème', isDark: isDark, config: config),
      const SizedBox(height: 10),
      _TypeSelector(
        types: _typesProblemes,
        selected: _typeProbleme,
        isDark: isDark,
        config: config,
        crossAxisCount: 3,
        onSelect: (v) => setState(() => _typeProbleme = v),
      ),
      SizedBox(height: config.isShortScreen ? 16 : 22),

      _SectionLabel(text: 'Description', isDark: isDark, config: config),
      const SizedBox(height: 10),
      _DescriptionField(
          controller: _descriptionController, isDark: isDark, config: config),
      SizedBox(height: config.isShortScreen ? 16 : 22),

      _SectionLabel(
          text: 'Photos (${_photos.length}/5)', isDark: isDark, config: config),
      const SizedBox(height: 10),
      _PhotoSection(
        photos: _photos,
        isDark: isDark,
        config: config,
        onPickCamera: () => _pickImage(ImageSource.camera),
        onPickGallery: _pickMultiple,
        onRemove: (i) => setState(() => _photos.removeAt(i)),
      ),
      SizedBox(height: config.isShortScreen ? 22 : 30),

      CustomButton(
        text: 'CRÉER LE SIGNALEMENT',
        onPressed: _isLoading ? null : _handleSubmit,
        isLoading: _isLoading,
        icon: Icons.send,
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── Layout tablette : type + description côte à côte ────────────────────
  Widget _buildTabletLayout(bool isDark, ResponsiveConfig config) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _InfoBanner(isDark: isDark, config: config),
      const SizedBox(height: 24),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Colonne gauche : type de problème
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel(
                text: 'Type de problème', isDark: isDark, config: config),
            const SizedBox(height: 10),
            _TypeSelector(
              types: _typesProblemes,
              selected: _typeProbleme,
              isDark: isDark,
              config: config,
              crossAxisCount: 2,
              onSelect: (v) => setState(() => _typeProbleme = v),
            ),
          ]),
        ),
        const SizedBox(width: 24),
        // Colonne droite : description
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel(text: 'Description', isDark: isDark, config: config),
            const SizedBox(height: 10),
            _DescriptionField(
                controller: _descriptionController,
                isDark: isDark,
                config: config),
          ]),
        ),
      ]),
      const SizedBox(height: 24),

      _SectionLabel(
          text: 'Photos (${_photos.length}/5)', isDark: isDark, config: config),
      const SizedBox(height: 10),
      _PhotoSection(
        photos: _photos,
        isDark: isDark,
        config: config,
        onPickCamera: () => _pickImage(ImageSource.camera),
        onPickGallery: _pickMultiple,
        onRemove: (i) => setState(() => _photos.removeAt(i)),
      ),
      const SizedBox(height: 32),

      CustomButton(
        text: 'CRÉER LE SIGNALEMENT',
        onPressed: _isLoading ? null : _handleSubmit,
        isLoading: _isLoading,
        icon: Icons.send,
      ),
      const SizedBox(height: 16),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const _SectionLabel(
      {required this.text, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: config.responsive(small: 14, medium: 15, large: 16),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87));
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  final ResponsiveConfig config;
  const _InfoBanner({required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final textSize = config.responsive(small: 12, medium: 13, large: 14);
    return Card(
      elevation: isDark ? 4 : 0,
      color: AppTheme.infoColor.withOpacity(isDark ? 0.2 : 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(config.responsive(small: 12, medium: 14, large: 16)),
        child: Row(children: [
          Icon(Icons.info_outline,
              color: AppTheme.infoColor,
              size: config.responsive(small: 18, medium: 20, large: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Décrivez le problème et ajoutez des photos pour un traitement rapide',
              style: TextStyle(
                  fontSize: textSize,
                  color: isDark ? Colors.grey.shade300 : Colors.black87),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> types;
  final String selected;
  final bool isDark;
  final ResponsiveConfig config;
  final int crossAxisCount;
  final ValueChanged<String> onSelect;

  const _TypeSelector({
    required this.types,
    required this.selected,
    required this.isDark,
    required this.config,
    required this.crossAxisCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 24, medium: 29, large: 33);
    final labelSize = config.responsive(small: 10, medium: 12, large: 13);
    final ratio = config.responsive(small: 0.95, medium: 1.05, large: 1.15);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ratio,
        crossAxisSpacing: config.isSmall ? 8 : 12,
        mainAxisSpacing: config.isSmall ? 8 : 12,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSel = selected == type['value'];

        return InkWell(
          onTap: () => onSelect(type['value']),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: isSel ? 4 : (isDark ? 2 : 1),
            color: isDark ? const Color(0xFF1E1E1E) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: isSel ? AppTheme.errorColor : Colors.transparent,
                  width: 2),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type['icon'],
                      color: isSel
                          ? AppTheme.errorColor
                          : (isDark ? Colors.grey.shade400 : Colors.grey[600]),
                      size: iconSize),
                  SizedBox(height: config.isSmall ? 5 : 7),
                  Text(type['label'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: labelSize,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel
                              ? AppTheme.errorColor
                              : (isDark ? Colors.white : Colors.black87))),
                ]),
          ),
        );
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ResponsiveConfig config;
  const _DescriptionField(
      {required this.controller, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Description détaillée',
      hint: 'Décrivez le problème en détail…',
      prefixIcon: Icons.description,
      maxLines: config.isTablet ? 8 : 5,
      maxLength: 1000,
      validator: (v) {
        if (v == null || v.isEmpty) return 'La description est requise';
        if (v.length < 10) return 'Au moins 10 caractères';
        return null;
      },
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final List<File> photos;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<int> onRemove;

  const _PhotoSection({
    required this.photos,
    required this.isDark,
    required this.config,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis = config.isTablet ? 5 : 3;
    final btnPad = EdgeInsets.symmetric(
        vertical: config.isSmall ? 10 : 12);

    return Column(children: [
      // Grille photos sélectionnées
      if (photos.isNotEmpty) ...[
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            childAspectRatio: 1,
            crossAxisSpacing: config.isSmall ? 6 : 8,
            mainAxisSpacing: config.isSmall ? 6 : 8,
          ),
          itemCount: photos.length,
          itemBuilder: (_, i) => Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(config.isSmall ? 6 : 8),
              child: Image.file(photos[i],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppTheme.errorColor, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(height: config.isSmall ? 8 : 12),
      ],

      // Boutons caméra / galerie
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: photos.length < 5 ? onPickCamera : null,
            icon: Icon(Icons.camera_alt,
                color: isDark ? Colors.white : Colors.black87,
                size: config.responsive(small: 18, medium: 20, large: 22)),
            label: Text(config.isSmall ? 'Caméra' : 'Caméra',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: config.responsive(small: 12, medium: 14, large: 14))),
            style: OutlinedButton.styleFrom(
              padding: btnPad,
              side: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
        ),
        SizedBox(width: config.isSmall ? 8 : 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: photos.length < 5 ? onPickGallery : null,
            icon: Icon(Icons.photo_library,
                color: isDark ? Colors.white : Colors.black87,
                size: config.responsive(small: 18, medium: 20, large: 22)),
            label: Text('Galerie',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: config.responsive(small: 12, medium: 14, large: 14))),
            style: OutlinedButton.styleFrom(
              padding: btnPad,
              side: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
        ),
      ]),

      if (photos.isEmpty) ...[
        SizedBox(height: config.isSmall ? 10 : 14),
        Text('Ajoutez au moins une photo du problème',
            style: TextStyle(
                fontSize: config.responsive(small: 11, medium: 12, large: 13),
                color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      ],
    ]);
  }
}