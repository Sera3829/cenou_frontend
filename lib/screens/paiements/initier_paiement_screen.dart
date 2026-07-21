import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../utils/mobile_responsive.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/initier_paiement_widgets.dart';
import 'dialogs/confirm_paiement_dialog.dart';
import 'dialogs/paiement_success_dialog.dart';

class InitierPaiementScreen extends StatefulWidget {
  const InitierPaiementScreen({super.key});

  @override
  State<InitierPaiementScreen> createState() => _InitierPaiementScreenState();
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
    final l10n = AppLocalizations.of(context);
    try {
      final provider = Provider.of<PaiementProvider>(context, listen: false);
      final data = await provider.getLoyerInfo();
      setState(() {
        _loyerMensuel = double.tryParse(data['prix_mensuel'].toString());
        _numeroChambre = data['numero_chambre'];
        _nomCentre = data['nom_centre'];
        _isLoadingLoyer = false;
      });
    } catch (e) {
      setState(() => _isLoadingLoyer = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.cannotLoadRent(e.toString())),
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
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'MOOV_MONEY':
        return 'Moov Money';
      default:
        return mode;
    }
  }

  /// Récapitulatif présenté avant validation. Le dialogue ne connaît rien du
  /// paiement : il reçoit des lignes déjà formatées.
  List<LigneRecap> _lignesRecapitulatif(AppLocalizations l10n) {
    final langue = l10n.locale.languageCode;
    final fmt = NumberFormat('#,###', langue);
    final format = ResponsiveConfig.fromConstraints(
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width))
            .isSmall
        ? 'dd/MM/yy'
        : 'dd/MM/yyyy';
    final periode = '${DateFormat(format, langue).format(DateTime.now())}'
        ' → ${DateFormat(format, langue).format(_dateFin)}';

    return [
      LigneRecap(l10n.monthlyRent, '${fmt.format(_loyerMensuel)} FCFA'),
      LigneRecap(l10n.numberOfMonths, '$_nombreMois ${l10n.months}'),
      const LigneRecap.separateur(),
      LigneRecap(l10n.totalAmount, '${fmt.format(_montantTotal)} FCFA',
          accentue: true),
      LigneRecap(l10n.paymentMethod, _getModeLabel(_modePaiement!)),
      LigneRecap(l10n.phoneNumber, _telephoneController.text),
      LigneRecap(l10n.period, periode),
    ];
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_modePaiement == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.selectPaymentMethod),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final confirm = await showConfirmPaiementDialog(
      context,
      lignes: _lignesRecapitulatif(l10n),
      isDark: Theme.of(context).brightness == Brightness.dark,
      config: ResponsiveConfig.fromConstraints(
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width)),
      l10n: l10n,
    );
    if (!confirm) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<PaiementProvider>(context, listen: false);
      final result = await provider.initierPaiement(
        montant: _montantTotal,
        modePaiement: _modePaiement!,
        numeroTelephone: _telephoneController.text.trim(),
        nombreMois: _nombreMois,
      );
      if (!mounted) return;
      await showPaiementSuccessDialog(context, result);

      // Le dialogue est bloquant : l'écran peut avoir disparu entre-temps.
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###', l10n.locale.languageCode);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.newPayment,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: _isLoadingLoyer
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : LayoutBuilder(
              builder: (context, constraints) {
                final config = ResponsiveConfig.fromConstraints(constraints);
                final hPad = config.isSmall ? 14.0 : 20.0;

                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        hPad, config.isShortScreen ? 12 : 18, hPad, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Carte info logement ──────────────────────
                        LoyerInfoCard(
                          nomCentre: _nomCentre,
                          numeroChambre: _numeroChambre,
                          loyerMensuel: _loyerMensuel,
                          isDark: isDark,
                          config: config,
                          fmt: fmt,
                          l10n: l10n,
                        ),

                        SizedBox(height: config.isShortScreen ? 18 : 26),

                        // Durée
                        SectionLabel(
                            text: l10n.paymentDuration,
                            isDark: isDark,
                            config: config),
                        const SizedBox(height: 10),
                        MoisSelector(
                          options: _optionsMois,
                          selected: _nombreMois,
                          isDark: isDark,
                          config: config,
                          onSelect: (m) => setState(() => _nombreMois = m),
                          l10n: l10n,
                        ),

                        SizedBox(height: config.isShortScreen ? 14 : 18),

                        // ── Résumé montant ───────────────────────────
                        MontantResume(
                          montantTotal: _montantTotal,
                          loyerMensuel: _loyerMensuel,
                          nombreMois: _nombreMois,
                          dateFin: _dateFin,
                          isDark: isDark,
                          config: config,
                          fmt: fmt,
                          l10n: l10n,
                        ),

                        SizedBox(height: config.isShortScreen ? 18 : 26),

                        // ── Mode de paiement ─────────────────────────
                        SectionLabel(
                            text: l10n.paymentMethod,
                            isDark: isDark,
                            config: config),
                        const SizedBox(height: 10),

                        // Sur tablette : côte à côte
                        config.isTablet
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ModeCard(
                                      value: 'ORANGE_MONEY',
                                      label: 'Orange Money',
                                      logo: 'assets/images/logo_orange.png',
                                      color: const Color(0xFFFF6600),
                                      isDark: isDark,
                                      config: config,
                                      selected: _modePaiement,
                                      onSelect: (v) =>
                                          setState(() => _modePaiement = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ModeCard(
                                      value: 'MOOV_MONEY',
                                      label: 'Moov Money',
                                      logo: 'assets/images/logo_moov.png',
                                      color: const Color(0xFF0066CC),
                                      isDark: isDark,
                                      config: config,
                                      selected: _modePaiement,
                                      onSelect: (v) =>
                                          setState(() => _modePaiement = v),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  ModeCard(
                                    value: 'ORANGE_MONEY',
                                    label: 'Orange Money',
                                    logo: 'assets/images/logo_orange.png',
                                    color: const Color(0xFFFF6600),
                                    isDark: isDark,
                                    config: config,
                                    selected: _modePaiement,
                                    onSelect: (v) =>
                                        setState(() => _modePaiement = v),
                                  ),
                                  const SizedBox(height: 10),
                                  ModeCard(
                                    value: 'MOOV_MONEY',
                                    label: 'Moov Money',
                                    logo: 'assets/images/logo_moov.png',
                                    color: const Color(0xFF0066CC),
                                    isDark: isDark,
                                    config: config,
                                    selected: _modePaiement,
                                    onSelect: (v) =>
                                        setState(() => _modePaiement = v),
                                  ),
                                ],
                              ),

                        SizedBox(height: config.isShortScreen ? 18 : 26),

                        // ── Téléphone ────────────────────────────────
                        SectionLabel(
                            text: l10n.phoneNumber,
                            isDark: isDark,
                            config: config),
                        const SizedBox(height: 10),
                        PhoneField(
                          controller: _telephoneController,
                          isDark: isDark,
                          config: config,
                          l10n: l10n,
                        ),

                        SizedBox(height: config.isShortScreen ? 22 : 30),

                        // ── Bouton payer ─────────────────────────────
                        CustomButton(
                          text: config.isSmall
                              ? l10n.payShort(fmt.format(_montantTotal))
                              : l10n.pay(fmt.format(_montantTotal)),
                          onPressed: _isLoading ? null : _handleSubmit,
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
