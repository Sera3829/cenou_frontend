import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../utils/mobile_responsive.dart';
import '../../widgets/custom_button.dart';

class InitierPaiementScreen extends StatefulWidget {
  const InitierPaiementScreen({Key? key}) : super(key: key);

  @override
  State<InitierPaiementScreen> createState() =>
      _InitierPaiementScreenState();
}

class _InitierPaiementScreenState extends State<InitierPaiementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();

  String? _modePaiement;
  bool _isLoading = false;
  bool _isLoadingLoyer = true;

  double? _loyerMensuel;
  String? _numeroChambre;
  String? _nomCentre;

  int _nombreMois = 1;
  final List<int> _optionsMois = [1, 3, 6, 12];

  @override
  void initState() {
    super.initState();
    _loadLoyerInfo();
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLoyerInfo() async {
    try {
      final provider =
      Provider.of<PaiementProvider>(context, listen: false);
      final data = await provider.getLoyerInfo();
      setState(() {
        _loyerMensuel =
            double.tryParse(data['prix_mensuel'].toString());
        _numeroChambre = data['numero_chambre'];
        _nomCentre = data['nom_centre'];
        _isLoadingLoyer = false;
      });
    } catch (e) {
      setState(() => _isLoadingLoyer = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Impossible de récupérer le loyer: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  double get _montantTotal => (_loyerMensuel ?? 0) * _nombreMois;

  DateTime get _dateFin {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _nombreMois, now.day - 1);
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      default: return mode;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modePaiement == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner un mode de paiement'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final confirm = await _showConfirmDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final provider =
      Provider.of<PaiementProvider>(context, listen: false);
      final result = await provider.initierPaiement(
        montant: _montantTotal,
        modePaiement: _modePaiement!,
        numeroTelephone: _telephoneController.text.trim(),
        nombreMois: _nombreMois,
      );
      if (!mounted) return;
      await _showSuccessDialog(result);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');
    final config = ResponsiveConfig.fromConstraints(
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width));

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmer le paiement',
            style: TextStyle(
                fontSize: config.responsive(
                    small: 15, medium: 17, large: 18),
                color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConfirmRow('Loyer mensuel',
                '${fmt.format(_loyerMensuel)} FCFA', isDark, config),
            _ConfirmRow('Nombre de mois', '$_nombreMois mois',
                isDark, config),
            const Divider(height: 20),
            _ConfirmRow(
                'Montant total',
                '${fmt.format(_montantTotal)} FCFA',
                isDark,
                config,
                bold: true),
            _ConfirmRow('Mode',
                _getModeLabel(_modePaiement!), isDark, config),
            _ConfirmRow('Numéro',
                _telephoneController.text, isDark, config),
            _ConfirmRow(
                'Période',
                config.isSmall
                    ? '${DateFormat('dd/MM/yy').format(DateTime.now())} → ${DateFormat('dd/MM/yy').format(_dateFin)}'
                    : '${DateFormat('dd/MM/yyyy').format(DateTime.now())} → ${DateFormat('dd/MM/yyyy').format(_dateFin)}',
                isDark,
                config),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paiement = result['paiement'];
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.check_circle,
              color: AppTheme.successColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Paiement initié',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 17)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre demande a été enregistrée.',
                style: TextStyle(
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.black87)),
            const SizedBox(height: 10),
            if (paiement != null) ...[
              Text('Réf: ${paiement['reference']}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                  'Période: ${paiement['date_debut']} → ${paiement['date_fin']}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
            const SizedBox(height: 8),
            Text(
                'Vous recevrez une notification de confirmation.',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.black87)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau paiement',
            style:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: _isLoadingLoyer
          ? Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary))
          : LayoutBuilder(
        builder: (context, constraints) {
          final config =
          ResponsiveConfig.fromConstraints(constraints);
          final hPad =
          config.isSmall ? 14.0 : 20.0;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  hPad,
                  config.isShortScreen ? 12 : 18,
                  hPad,
                  24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Carte info logement ──────────────────────
                  _LoyerInfoCard(
                    nomCentre: _nomCentre,
                    numeroChambre: _numeroChambre,
                    loyerMensuel: _loyerMensuel,
                    isDark: isDark,
                    config: config,
                    fmt: fmt,
                  ),

                  SizedBox(
                      height: config.isShortScreen ? 18 : 26),

                  // Durée
                  _SectionLabel(
                      text: 'Durée du paiement',
                      isDark: isDark,
                      config: config),
                  const SizedBox(height: 10),
                  _MoisSelector(
                    options: _optionsMois,
                    selected: _nombreMois,
                    isDark: isDark,
                    config: config,
                    onSelect: (m) =>
                        setState(() => _nombreMois = m),
                  ),

                  SizedBox(
                      height: config.isShortScreen ? 14 : 18),

                  // ── Résumé montant ───────────────────────────
                  _MontantResume(
                    montantTotal: _montantTotal,
                    loyerMensuel: _loyerMensuel,
                    nombreMois: _nombreMois,
                    dateFin: _dateFin,
                    isDark: isDark,
                    config: config,
                    fmt: fmt,
                  ),

                  SizedBox(
                      height: config.isShortScreen ? 18 : 26),

                  // ── Mode de paiement ─────────────────────────
                  _SectionLabel(
                      text: 'Mode de paiement',
                      isDark: isDark,
                      config: config),
                  const SizedBox(height: 10),

                  // Sur tablette : côte à côte
                  config.isTablet
                      ? Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          value: 'ORANGE_MONEY',
                          label: 'Orange Money',
                          logo: 'assets/images/logo_orange.png',
                          color: const Color(0xFFFF6600),
                          isDark: isDark,
                          config: config,
                          selected: _modePaiement,
                          onSelect: (v) => setState(
                                  () => _modePaiement = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModeCard(
                          value: 'MOOV_MONEY',
                          label: 'Moov Money',
                          logo: 'assets/images/logo_moov.png',
                          color: const Color(0xFF0066CC),
                          isDark: isDark,
                          config: config,
                          selected: _modePaiement,
                          onSelect: (v) => setState(
                                  () => _modePaiement = v),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _ModeCard(
                        value: 'ORANGE_MONEY',
                        label: 'Orange Money',
                        logo: 'assets/images/logo_orange.png',
                        color: const Color(0xFFFF6600),
                        isDark: isDark,
                        config: config,
                        selected: _modePaiement,
                        onSelect: (v) => setState(
                                () => _modePaiement = v),
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        value: 'MOOV_MONEY',
                        label: 'Moov Money',
                        logo: 'assets/images/logo_moov.png',
                        color: const Color(0xFF0066CC),
                        isDark: isDark,
                        config: config,
                        selected: _modePaiement,
                        onSelect: (v) => setState(
                                () => _modePaiement = v),
                      ),
                    ],
                  ),

                  SizedBox(
                      height: config.isShortScreen ? 18 : 26),

                  // ── Téléphone ────────────────────────────────
                  _SectionLabel(
                      text: 'Numéro de téléphone',
                      isDark: isDark,
                      config: config),
                  const SizedBox(height: 10),
                  _PhoneField(
                    controller: _telephoneController,
                    isDark: isDark,
                    config: config,
                  ),

                  SizedBox(
                      height: config.isShortScreen ? 22 : 30),

                  // ── Bouton payer ─────────────────────────────
                  CustomButton(
                    text: config.isSmall
                        ? 'PAYER ${fmt.format(_montantTotal)} F'
                        : 'PAYER ${fmt.format(_montantTotal)} FCFA',
                    onPressed:
                    _isLoading ? null : _handleSubmit,
                    isLoading: _isLoading,
                    icon: Icons.payment,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets internes : InitierPaiement
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const _SectionLabel(
      {required this.text,
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

class _LoyerInfoCard extends StatelessWidget {
  final String? nomCentre;
  final String? numeroChambre;
  final double? loyerMensuel;
  final bool isDark;
  final ResponsiveConfig config;
  final NumberFormat fmt;
  const _LoyerInfoCard({
    required this.nomCentre,
    required this.numeroChambre,
    required this.loyerMensuel,
    required this.isDark,
    required this.config,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 18, medium: 21, large: 24);
    final pad = config.responsive(small: 12, medium: 14, large: 16);
    final titleSize =
    config.responsive(small: 13, medium: 14, large: 15);
    final loyerSize =
    config.responsive(small: 13, medium: 14, large: 15);

    // Tronquer le nom du centre + chambre
    final label = [
      if (nomCentre != null) nomCentre!,
      if (numeroChambre != null) 'Ch. $numeroChambre',
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
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.home,
              color: Theme.of(context).colorScheme.primary,
              size: iconSize),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color:
                        isDark ? Colors.white : Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  'Loyer: ${fmt.format(loyerMensuel)} FCFA / mois',
                  style: TextStyle(
                      fontSize: loyerSize,
                      color:
                      Theme.of(context).colorScheme.primary,
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

class _MoisSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final bool isDark;
  final ResponsiveConfig config;
  final ValueChanged<int> onSelect;
  const _MoisSelector({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.config,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final numSize =
    config.responsive(small: 17, medium: 19, large: 21);
    final labelSize =
    config.responsive(small: 10, medium: 11, large: 11);
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
                      : (isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white),
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
                                : (isDark
                                ? Colors.white
                                : Colors.black87))),
                    Text('mois',
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

class _MontantResume extends StatelessWidget {
  final double montantTotal;
  final double? loyerMensuel;
  final int nombreMois;
  final DateTime dateFin;
  final bool isDark;
  final ResponsiveConfig config;
  final NumberFormat fmt;
  const _MontantResume({
    required this.montantTotal,
    required this.loyerMensuel,
    required this.nombreMois,
    required this.dateFin,
    required this.isDark,
    required this.config,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final amountSize =
    config.responsive(small: 28, medium: 33, large: 37);
    final subSize =
    config.responsive(small: 12, medium: 13, large: 14);
    final dateSize =
    config.responsive(small: 11, medium: 12, large: 13);
    final pad = config.responsive(small: 14, medium: 18, large: 20);

    final dateStr = config.isSmall
        ? '${DateFormat('dd/MM/yy').format(DateTime.now())} → ${DateFormat('dd/MM/yy').format(dateFin)}'
        : '${DateFormat('dd/MM/yyyy').format(DateTime.now())} → ${DateFormat('dd/MM/yyyy').format(dateFin)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary, width: 2),
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
            '$nombreMois × ${fmt.format(loyerMensuel)} FCFA',
            style: TextStyle(
                fontSize: subSize,
                color: isDark
                    ? Colors.grey.shade400
                    : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today,
                  size: 13,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                dateStr,
                style: TextStyle(
                    fontSize: dateSize,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String value;
  final String label;
  final String logo;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _ModeCard({
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
    final fontSize =
    config.responsive(small: 13, medium: 15, large: 16);
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
                  : (isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300),
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
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.phone_android,
                        color: color,
                        size: logoSize * 0.6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight:
                      isSel ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(
              isSel ? Icons.check_circle : Icons.circle_outlined,
              color: isSel
                  ? color
                  : (isDark
                  ? Colors.grey.shade600
                  : Colors.grey[400]),
              size: checkSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ResponsiveConfig config;
  const _PhoneField({
    required this.controller,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final textSize =
    config.responsive(small: 15, medium: 17, large: 18);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(
          fontSize: textSize,
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: '+226 70 XX XX XX',
        hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
        prefixIcon: Icon(Icons.phone,
            color: Theme.of(context).colorScheme.primary,
            size: config.responsive(small: 20, medium: 22, large: 24)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor:
        isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: config.isSmall ? 14 : 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le numéro de téléphone est requis';
        }
        if (!RegExp(r'^\+?[0-9]{8,15}$')
            .hasMatch(value.replaceAll(' ', ''))) {
          return 'Numéro invalide';
        }
        return null;
      },
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final ResponsiveConfig config;
  final bool bold;

  const _ConfirmRow(this.label, this.value, this.isDark, this.config,
      {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final sz = config.responsive(small: 12, medium: 13, large: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: sz,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey[600])),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: sz,
                    color: isDark ? Colors.white : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}