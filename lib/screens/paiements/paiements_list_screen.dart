import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/paiement.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import 'paiement_detail_screen.dart';
import 'initier_paiement_screen.dart';

/// Écran liste des paiements — responsive mobile/tablette.
class PaiementsListScreen extends StatefulWidget {
  const PaiementsListScreen({Key? key}) : super(key: key);

  @override
  State<PaiementsListScreen> createState() => _PaiementsListScreenState();
}

class _PaiementsListScreenState extends State<PaiementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaiementProvider>(context, listen: false).refresh();
    });
  }

  // ── Navigation vers le paiement (avec vérif connexion) ──────────────────
  void _goToPaiement(BuildContext context, AppLocalizations l10n) {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offlinePaymentRequired),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InitierPaiementScreen()),
    );
  }

  // ── Infos statut ─────────────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(Paiement p) {
    if (p.isConfirme) return _StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    if (p.isEchec) return _StatusInfo(AppTheme.errorColor, Icons.cancel_rounded);
    return _StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'ORANGE_MONEY': return Icons.phone_android_rounded;
      case 'MOOV_MONEY':  return Icons.phone_iphone_rounded;
      case 'WAVE':         return Icons.account_balance_wallet_rounded;
      case 'ESPECES':      return Icons.money_rounded;
      case 'VIREMENT':     return Icons.account_balance_rounded;
      default:             return Icons.payment_rounded;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: _buildAppBar(isDark, l10n),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return Consumer<PaiementProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.paiements.isEmpty) {
                return _LoadingState(config: config, l10n: l10n);
              }
              if (provider.error != null) {
                return _ErrorState(
                  error: provider.error!,
                  isDark: isDark,
                  config: config,
                  onRetry: provider.refresh,
                  l10n: l10n,
                );
              }
              return RefreshIndicator(
                onRefresh: provider.refresh,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _StatsCard(
                        provider: provider,
                        isDark: isDark,
                        config: config,
                        onPay: () => _goToPaiement(context, l10n),
                        l10n: l10n,
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        config.isSmall ? 12 : 16,
                        12,
                        config.isSmall ? 12 : 16,
                        100, // espace pour le FAB
                      ),
                      sliver: provider.paiements.isEmpty
                          ? SliverToBoxAdapter(
                          child: _EmptyState(isDark: isDark, config: config, l10n: l10n))
                          : SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) => _PaiementCard(
                            paiement: provider.paiements[i],
                            isDark: isDark,
                            config: config,
                            statusInfo: _getStatusInfo(provider.paiements[i]),
                            modeIcon: _getModeIcon(provider.paiements[i].modePaiement),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaiementDetailScreen(
                                    paiementId: provider.paiements[i].id),
                              ),
                            ),
                            l10n: l10n,
                          ),
                          childCount: provider.paiements.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFab(context, l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.navPayments,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
      ),
      centerTitle: true,
      actions: [
        Consumer<PaiementProvider>(
          builder: (_, provider, __) {
            if (!provider.isFromCache) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 13, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    l10n.cacheBadge,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {},
          tooltip: l10n.fullHistory,
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    final config = ResponsiveConfig.fromConstraints(
      BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    );
    return FloatingActionButton.extended(
      onPressed: () => _goToPaiement(context, l10n),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        config.isSmall ? l10n.newPaymentShort : l10n.newPayment,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Carte statistiques
// ════════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  final PaiementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onPay;
  final AppLocalizations l10n;

  const _StatsCard({
    required this.provider,
    required this.isDark,
    required this.config,
    required this.onPay,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final margin = config.isSmall ? 12.0 : 16.0;
    final pad = config.responsive(small: 14, medium: 18, large: 22);
    final titleSize = config.responsive(small: 12, medium: 13, large: 14);
    final amountSize = config.responsive(small: 13, medium: 15, large: 16);

    return Container(
      margin: EdgeInsets.fromLTRB(margin, margin, margin, 6),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: Colors.white.withOpacity(0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.financialSummary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: config.isShortScreen ? 10 : 14),

          // 3 stats : Total | Confirmés | En cours
          // Sur tablette → Row directe, sur mobile → GridView
          config.isTablet
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: l10n.totalPayments,
                value: provider.totalPaiements.toString(),
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.white.withOpacity(0.9),
                config: config,
              ),
              _StatItem(
                label: l10n.confirmedPayments,
                value: provider.paiementsConfirmes.toString(),
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green[300]!,
                config: config,
              ),
              _StatItem(
                label: l10n.pendingPayments,
                value: provider.pendingPaiementsCount.toString(),
                icon: Icons.pending_actions_rounded,
                iconColor: Colors.amber[300]!,
                config: config,
              ),
            ],
          )
              : GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: config.isSmall ? 1.0 : 1.2,
            crossAxisSpacing: config.isSmall ? 6 : 10,
            mainAxisSpacing: 0,
            children: [
              _StatItem(
                label: l10n.totalPayments,
                value: provider.totalPaiements.toString(),
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.white.withOpacity(0.9),
                config: config,
              ),
              _StatItem(
                label: l10n.confirmedPayments,
                value: provider.paiementsConfirmes.toString(),
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green[300]!,
                config: config,
              ),
              _StatItem(
                label: l10n.pendingPayments,
                value: provider.pendingPaiementsCount.toString(),
                icon: Icons.pending_actions_rounded,
                iconColor: Colors.amber[300]!,
                config: config,
              ),
            ],
          ),

          SizedBox(height: config.isShortScreen ? 10 : 14),

          // Montant total payé
          _AmountRow(
            icon: Icons.attach_money_rounded,
            iconColor: Colors.white.withOpacity(0.9),
            bgColor: Colors.white.withOpacity(0.1),
            text: l10n.totalPaidAmount(NumberFormat('#,###').format(provider.montantTotal)),
            textColor: Colors.white,
            fontSize: amountSize,
            config: config,
          ),
          const SizedBox(height: 8),

          // Montant à régler
          _AmountRow(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange[300]!,
            bgColor: Colors.orange.withOpacity(0.2),
            text: l10n.amountDue(NumberFormat('#,###').format(provider.montantTotalAttendu)),
            textColor: Colors.orange[300]!,
            fontSize: config.responsive(small: 11, medium: 13, large: 14),
            config: config,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final ResponsiveConfig config;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconPad = config.responsive(small: 6, medium: 8, large: 10);
    final iconSize = config.responsive(small: 16, medium: 19, large: 22);
    final valueSize = config.responsive(small: 14, medium: 17, large: 19);
    final labelSize = config.responsive(small: 9, medium: 10, large: 11);

    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          SizedBox(height: config.isSmall ? 5 : 7),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String text;
  final Color textColor;
  final double fontSize;
  final ResponsiveConfig config;

  const _AmountRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.text,
    required this.textColor,
    required this.fontSize,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 16, medium: 20, large: 22);
    final pad = config.isSmall ? 10.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Carte paiement historique
// ════════════════════════════════════════════════════════════════

class _PaiementCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  final _StatusInfo statusInfo;
  final IconData modeIcon;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _PaiementCard({
    required this.paiement,
    required this.isDark,
    required this.config,
    required this.statusInfo,
    required this.modeIcon,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad = config.responsive(small: 12, medium: 16, large: 18);
    final amountSize = config.responsive(small: 15, medium: 17, large: 19);
    final modeSize = config.responsive(small: 11, medium: 13, large: 14);
    final metaSize = config.responsive(small: 10, medium: 12, large: 12);
    final iconSize = config.responsive(small: 18, medium: 21, large: 23);
    final iconPad = config.responsive(small: 8, medium: 10, large: 11);
    final statusFontSize = config.responsive(small: 10, medium: 12, large: 12);

    // Référence tronquée
    final ref = paiement.referenceTransaction as String? ?? '';
    final displayRef = ref.length > (config.isSmall ? 10 : 16)
        ? '${ref.substring(0, config.isSmall ? 9 : 15)}…'
        : ref;

    // Nom du centre tronqué
    final centre = paiement.nomCentre ?? '';
    final displayCentre = centre.length > (config.isSmall ? 12 : 18)
        ? '${centre.substring(0, config.isSmall ? 11 : 17)}…'
        : centre;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isDark ? 4 : 1,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Ligne 1 : statut + référence ──
                Row(
                  children: [
                    // Badge statut
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: config.isSmall ? 8 : 10,
                        vertical: config.isSmall ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo.icon,
                              color: statusInfo.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _statLabel(paiement.statut, l10n),
                            style: TextStyle(
                              color: statusInfo.color,
                              fontSize: statusFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Référence
                    if (displayRef.isNotEmpty)
                      Text(
                        displayRef,
                        style: TextStyle(
                          fontSize: metaSize,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: config.isSmall ? 10 : 14),

                // ── Ligne 2 : icône mode + montant ──
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPad),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        modeIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: iconSize,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${NumberFormat('#,###').format(paiement.montant)} FCFA',
                            style: TextStyle(
                              fontSize: amountSize,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            paiement.modePaiement.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: modeSize,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Flèche
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? Colors.grey.shade600 : Colors.grey[400],
                    ),
                  ],
                ),

                SizedBox(height: config.isSmall ? 8 : 12),

                // ── Ligne 3 : méta (date | chambre | centre) ──
                Wrap(
                  spacing: config.isSmall ? 8 : 12,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      text: paiement.datePaiement != null
                          ? (config.isSmall
                          ? DateFormat('dd/MM/yy').format(paiement.datePaiement!)
                          : DateFormat('dd MMM yyyy · HH:mm', l10n.locale.languageCode)
                          .format(paiement.datePaiement!))
                          : l10n.pendingPayment,
                      isDark: isDark,
                      fontSize: metaSize,
                    ),
                    if ((paiement.numeroChambre ?? '').isNotEmpty)
                      _MetaChip(
                        icon: Icons.room_rounded,
                        text: l10n.roomAbbr(paiement.numeroChambre!),
                        isDark: isDark,
                        fontSize: metaSize,
                      ),
                    if (displayCentre.isNotEmpty)
                      _MetaChip(
                        icon: Icons.business_rounded,
                        text: displayCentre,
                        isDark: isDark,
                        fontSize: metaSize,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statLabel(String s, AppLocalizations l10n) {
    switch (s.toUpperCase()) {
      case 'EN_ATTENTE': return l10n.pendingStatus;    // "En attente"
      case 'CONFIRME':   return l10n.confirmedStatus;  // "Confirmé"
      case 'ECHEC':      return l10n.failedStatus;     // "Échec"
      default:           return s.replaceAll('_', ' ');
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final double fontSize;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.isDark,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade400 : Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// États : loading / erreur / vide
// ════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const _LoadingState({required this.config, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSize = config.responsive(small: 13, medium: 15, large: 16);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.loadingPayments,
            style: TextStyle(
              fontSize: textSize,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const _EmptyState({required this.isDark, required this.config, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 60, medium: 75, large: 85);
    final titleSize = config.responsive(small: 18, medium: 21, large: 23);
    final bodySize = config.responsive(small: 13, medium: 14, large: 15);
    final hPad = config.responsive(small: 20, medium: 32, large: 48);
    final vPad = config.responsive(small: 40, medium: 55, large: 65);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: iconSize,
            color: isDark ? Colors.grey.shade700 : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noPayments,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noPaymentsSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorState({
    required this.error,
    required this.isDark,
    required this.config,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 56, medium: 68, large: 76);
    final titleSize = config.responsive(small: 17, medium: 19, large: 21);
    final bodySize = config.responsive(small: 12, medium: 14, large: 15);
    final hPad = config.responsive(small: 20, medium: 32, large: 48);

    // Tronquer l'erreur sur petit écran
    final displayError = config.isSmall && error.length > 80
        ? '${error.substring(0, 79)}…'
        : error;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: iconSize,
            color: isDark ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.loadingError,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            displayError,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: config.isSmall ? 20 : 28,
                vertical: config.isSmall ? 11 : 13,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Modèle statut
// ════════════════════════════════════════════════════════════════

class _StatusInfo {
  final Color color;
  final IconData icon;
  const _StatusInfo(this.color, this.icon);
}