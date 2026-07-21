import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../utils/mobile_responsive.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/create_signalement_widgets.dart';

/// Écran de création de signalement — responsive mobile/tablette.
class CreateSignalementScreen extends StatefulWidget {
  const CreateSignalementScreen({super.key});

  @override
  State<CreateSignalementScreen> createState() =>
      _CreateSignalementScreenState();
}

class _CreateSignalementScreenState extends State<CreateSignalementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _typeProbleme = 'PLOMBERIE';
  final List<File> _photos = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _getTypesProblemes(AppLocalizations l10n) {
    return [
      {'value': 'PLOMBERIE', 'label': l10n.plumbing, 'icon': Icons.plumbing},
      {
        'value': 'ELECTRICITE',
        'label': l10n.electricity,
        'icon': Icons.electrical_services
      },
      {'value': 'TOITURE', 'label': l10n.roofing, 'icon': Icons.roofing},
      {'value': 'SERRURE', 'label': l10n.locks, 'icon': Icons.lock},
      {'value': 'MOBILIER', 'label': l10n.furniture, 'icon': Icons.chair},
      {'value': 'AUTRE', 'label': l10n.other, 'icon': Icons.more_horiz},
    ];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Sélection photo ──────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
    if (_photos.length >= 5) {
      _snack(l10n.maxPhotosReached, bg: AppTheme.warningColor);
      return;
    }
    try {
      final image = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (image != null) setState(() => _photos.add(File(image.path)));
    } catch (e) {
      String msg = l10n.cameraError;
      if (e.toString().contains('denied') ||
          e.toString().contains('restricted')) {
        msg = l10n.cameraPermissionDenied;
      }
      if (mounted) _snack(msg, bg: Colors.orange);
    }
  }

  Future<void> _pickMultiple(AppLocalizations l10n) async {
    if (_photos.length >= 5) {
      _snack(l10n.maxPhotosReached, bg: AppTheme.warningColor);
      return;
    }
    try {
      final images = await _picker.pickMultiImage(
          maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      final remaining = 5 - _photos.length;
      setState(() =>
          _photos.addAll(images.take(remaining).map((x) => File(x.path))));
      if (images.length > remaining) {
        _snack(l10n.photosAddedLimit(remaining), bg: AppTheme.warningColor);
      }
    } catch (e) {
      _snack('${l10n.error}: $e', bg: AppTheme.errorColor);
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
  Future<void> _handleSubmit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      _snack(l10n.addAtLeastOnePhoto, bg: AppTheme.warningColor);
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
      await _showSuccessDialog(signalement, l10n);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), bg: AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(
      dynamic signalement, AppLocalizations l10n) async {
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
              child: Text(l10n.reportCreated,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87))),
        ]),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reportCreatedSuccess,
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
              const SizedBox(height: 10),
              Text(l10n.trackingNumber(signalement.numeroSuivi),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 6),
              Text(l10n.willBeNotified,
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
            ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.reportIssue,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
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
                  ? _buildTabletLayout(isDark, config, l10n)
                  : _buildMobileLayout(isDark, config, l10n),
            ),
          );
        },
      ),
    );
  }

  // ── Layout mobile : colonnes empilées ────────────────────────────────────
  Widget _buildMobileLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    final types = _getTypesProblemes(l10n);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CreateInfoBanner(isDark: isDark, config: config, l10n: l10n),
      SizedBox(height: config.isShortScreen ? 16 : 22),
      CreateSectionLabel(
          text: l10n.problemType, isDark: isDark, config: config),
      const SizedBox(height: 10),
      TypeSelector(
        types: types,
        selected: _typeProbleme,
        isDark: isDark,
        config: config,
        crossAxisCount: 3,
        onSelect: (v) => setState(() => _typeProbleme = v),
      ),
      SizedBox(height: config.isShortScreen ? 16 : 22),
      CreateSectionLabel(
          text: l10n.description, isDark: isDark, config: config),
      const SizedBox(height: 10),
      DescriptionField(
          controller: _descriptionController,
          isDark: isDark,
          config: config,
          l10n: l10n),
      SizedBox(height: config.isShortScreen ? 16 : 22),
      CreateSectionLabel(
          text: l10n.photosCount(_photos.length),
          isDark: isDark,
          config: config),
      const SizedBox(height: 10),
      PhotoSection(
        photos: _photos,
        isDark: isDark,
        config: config,
        onPickCamera: () => _pickImage(ImageSource.camera, l10n),
        onPickGallery: () => _pickMultiple(l10n),
        onRemove: (i) => setState(() => _photos.removeAt(i)),
        l10n: l10n,
      ),
      SizedBox(height: config.isShortScreen ? 22 : 30),
      CustomButton(
        text: l10n.createReportButton,
        onPressed: _isLoading ? null : () => _handleSubmit(l10n),
        isLoading: _isLoading,
        icon: Icons.send,
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── Layout tablette : type + description côte à côte ────────────────────
  Widget _buildTabletLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    final types = _getTypesProblemes(l10n);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CreateInfoBanner(isDark: isDark, config: config, l10n: l10n),
      const SizedBox(height: 24),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Colonne gauche : type de problème
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CreateSectionLabel(
                text: l10n.problemType, isDark: isDark, config: config),
            const SizedBox(height: 10),
            TypeSelector(
              types: types,
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CreateSectionLabel(
                text: l10n.description, isDark: isDark, config: config),
            const SizedBox(height: 10),
            DescriptionField(
                controller: _descriptionController,
                isDark: isDark,
                config: config,
                l10n: l10n),
          ]),
        ),
      ]),
      const SizedBox(height: 24),
      CreateSectionLabel(
          text: l10n.photosCount(_photos.length),
          isDark: isDark,
          config: config),
      const SizedBox(height: 10),
      PhotoSection(
        photos: _photos,
        isDark: isDark,
        config: config,
        onPickCamera: () => _pickImage(ImageSource.camera, l10n),
        onPickGallery: () => _pickMultiple(l10n),
        onRemove: (i) => setState(() => _photos.removeAt(i)),
        l10n: l10n,
      ),
      const SizedBox(height: 32),
      CustomButton(
        text: l10n.createReportButton,
        onPressed: _isLoading ? null : () => _handleSubmit(l10n),
        isLoading: _isLoading,
        icon: Icons.send,
      ),
      const SizedBox(height: 16),
    ]);
  }
}
