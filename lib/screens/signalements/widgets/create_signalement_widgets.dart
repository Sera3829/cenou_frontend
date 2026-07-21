import 'dart:io';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../l10n/app_localizations.dart';

class CreateSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const CreateSectionLabel(
      {super.key,
      required this.text,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: config.responsive(small: 14, medium: 15, large: 16),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87));
  }
}

class CreateInfoBanner extends StatelessWidget {
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const CreateInfoBanner(
      {super.key,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final textSize = config.responsive(small: 12, medium: 13, large: 14);
    return Card(
      elevation: isDark ? 4 : 0,
      color: AppTheme.infoColor.withOpacity(isDark ? 0.2 : 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding:
            EdgeInsets.all(config.responsive(small: 12, medium: 14, large: 16)),
        child: Row(children: [
          Icon(Icons.info_outline,
              color: AppTheme.infoColor,
              size: config.responsive(small: 18, medium: 20, large: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.reportInfoBanner,
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

class TypeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> types;
  final String selected;
  final bool isDark;
  final ResponsiveConfig config;
  final int crossAxisCount;
  final ValueChanged<String> onSelect;

  const TypeSelector({
    super.key,
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
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const DescriptionField(
      {super.key,
      required this.controller,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: l10n.detailedDescription,
      hint: l10n.detailedDescriptionHint,
      prefixIcon: Icons.description,
      maxLines: config.isTablet ? 8 : 5,
      maxLength: 1000,
      validator: (v) {
        if (v == null || v.isEmpty) return l10n.descriptionRequired;
        if (v.length < 10) return l10n.descriptionMinLength;
        return null;
      },
    );
  }
}

class PhotoSection extends StatelessWidget {
  final List<File> photos;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<int> onRemove;
  final AppLocalizations l10n;

  const PhotoSection({
    super.key,
    required this.photos,
    required this.isDark,
    required this.config,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis = config.isTablet ? 5 : 3;
    final btnPad = EdgeInsets.symmetric(vertical: config.isSmall ? 10 : 12);

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
              top: 4,
              right: 4,
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
            label: Text(l10n.camera,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize:
                        config.responsive(small: 12, medium: 14, large: 14))),
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
            label: Text(l10n.gallery,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize:
                        config.responsive(small: 12, medium: 14, large: 14))),
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
        Text(l10n.addAtLeastOnePhotoHint,
            style: TextStyle(
                fontSize: config.responsive(small: 11, medium: 12, large: 13),
                color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      ],
    ]);
  }
}
