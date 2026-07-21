import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const SectionLabel(
      {super.key,
      required this.text,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: config.responsive(small: 14, medium: 15, large: 16),
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class LoyerInfoCard extends StatelessWidget {
  final String? nomCentre;
  final String? numeroChambre;
  final double? loyerMensuel;
  final bool isDark;
  final ResponsiveConfig config;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  const LoyerInfoCard({
    super.key,
    required this.nomCentre,
    required this.numeroChambre,
    required this.loyerMensuel,
    required this.isDark,
    required this.config,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 18, medium: 21, large: 24);
    final pad = config.responsive(small: 12, medium: 14, large: 16);
    final titleSize = config.responsive(small: 13, medium: 14, large: 15);
    final loyerSize = config.responsive(small: 13, medium: 14, large: 15);

    // Tronquer le nom du centre + chambre
    final label = [
      if (nomCentre != null) nomCentre!,
      if (numeroChambre != null) l10n.roomAbbr(numeroChambre!),
    ].join(' - ');
    final displayLabel = config.isSmall && label.length > 22
        ? '${label.substring(0, 21)}…'
        : label;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.home,
              color: Theme.of(context).colorScheme.primary, size: iconSize),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color: isDark ? Colors.white : Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  l10n.rentPerMonth(fmt.format(loyerMensuel)),
                  style: TextStyle(
                      fontSize: loyerSize,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoisSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final bool isDark;
  final ResponsiveConfig config;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;
  const MoisSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.isDark,
    required this.config,
    required this.onSelect,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final numSize = config.responsive(small: 17, medium: 19, large: 21);
    final labelSize = config.responsive(small: 10, medium: 11, large: 11);
    final pad = config.isSmall ? 10.0 : 13.0;

    return Row(
      children: options.map((mois) {
        final isSel = selected == mois;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelect(mois),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: pad),
                decoration: BoxDecoration(
                  color: isSel
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel
                        ? Theme.of(context).colorScheme.primary
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text('$mois',
                        style: TextStyle(
                            fontSize: numSize,
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87))),
                    Text(l10n.months,
                        style: TextStyle(
                            fontSize: labelSize,
                            color: isSel
                                ? Colors.white70
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey))),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MontantResume extends StatelessWidget {
  final double montantTotal;
  final double? loyerMensuel;
  final int nombreMois;
  final DateTime dateFin;
  final bool isDark;
  final ResponsiveConfig config;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  const MontantResume({
    super.key,
    required this.montantTotal,
    required this.loyerMensuel,
    required this.nombreMois,
    required this.dateFin,
    required this.isDark,
    required this.config,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final amountSize = config.responsive(small: 28, medium: 33, large: 37);
    final subSize = config.responsive(small: 12, medium: 13, large: 14);
    final dateSize = config.responsive(small: 11, medium: 12, large: 13);
    final pad = config.responsive(small: 14, medium: 18, large: 20);

    final dateStr = config.isSmall
        ? '${DateFormat('dd/MM/yy', l10n.locale.languageCode).format(DateTime.now())} → ${DateFormat('dd/MM/yy', l10n.locale.languageCode).format(dateFin)}'
        : '${DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(DateTime.now())} → ${DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(dateFin)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '${fmt.format(montantTotal)} FCFA',
            style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.monthsTimesRent(nombreMois, fmt.format(loyerMensuel)),
            style: TextStyle(
                fontSize: subSize,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today,
                  size: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                dateStr,
                style: TextStyle(
                    fontSize: dateSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  final String value;
  final String label;
  final String logo;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  final String? selected;
  final ValueChanged<String> onSelect;
  const ModeCard({
    super.key,
    required this.value,
    required this.label,
    required this.logo,
    required this.color,
    required this.isDark,
    required this.config,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = selected == value;
    final logoSize = config.responsive(small: 38, medium: 44, large: 48);
    final fontSize = config.responsive(small: 13, medium: 15, large: 16);
    final pad = config.responsive(small: 12, medium: 15, large: 16);
    final checkSize = config.responsive(small: 22, medium: 25, large: 28);

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSel
                  ? color
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSel ? 2.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(logo,
                    errorBuilder: (_, __, ___) => Icon(Icons.phone_android,
                        color: color, size: logoSize * 0.6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(
              isSel ? Icons.check_circle : Icons.circle_outlined,
              color: isSel
                  ? color
                  : (isDark ? Colors.grey.shade600 : Colors.grey[400]),
              size: checkSize,
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const PhoneField({
    super.key,
    required this.controller,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = config.responsive(small: 15, medium: 17, large: 18);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(
          fontSize: textSize, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: l10n.phoneHint,
        hintStyle:
            TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
        prefixIcon: Icon(Icons.phone,
            color: Theme.of(context).colorScheme.primary,
            size: config.responsive(small: 20, medium: 22, large: 24)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: config.isSmall ? 14 : 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.phoneRequired;
        }
        if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value.replaceAll(' ', ''))) {
          return l10n.phoneInvalid;
        }
        return null;
      },
    );
  }
}
