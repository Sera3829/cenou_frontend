import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/signalement.dart';
import '../../utils/mobile_responsive.dart';
import 'signalement_detail_screen.dart';
import 'create_signalement_screen.dart';

/// Écran liste des signalements — responsive mobile/tablette.
class SignalementsListScreen extends StatefulWidget {
  const SignalementsListScreen({Key? key}) : super(key: key);

  @override
  State<SignalementsListScreen> createState() => _SignalementsListScreenState();
}

class _SignalementsListScreenState extends State<SignalementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProvider>(context, listen: false).loadSignalements();
    });
  }

  // ── Navigation vers créer signalement (avec vérif connexion) ────────────
  void _goToCreate(BuildContext context) {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connexion internet requise pour créer un signalement'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSignalementScreen()),
    );
  }

  // ── Infos statut ─────────────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(Signalement s) {
    if (s.isResolu)  return _StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    if (s.isEnCours) return _StatusInfo(AppTheme.infoColor,    Icons.build_rounded);
    if (s.isAnnule)  return _StatusInfo(Colors.grey,           Icons.cancel_rounded);
    return _StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
  }

  IconData _getProblemIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PLOMBERIE':   return Icons.plumbing_rounded;
      case 'ELECTRICITE': return Icons.electrical_services_rounded;
      case 'TOITURE':     return Icons.roofing_rounded;
      case 'SERRURE':     return Icons.lock_rounded;
      case 'MOBILIER':    return Icons.chair_rounded;
      default:            return Icons.more_horiz_rounded;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: _buildAppBar(isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return Consumer<SignalementProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.signalements.isEmpty) {
                return _LoadingState(config: config);
              }
              if (provider.error != null) {
                return _ErrorState(
                  error: provider.error!,
                  isDark: isDark,
                  config: config,
                  onRetry: provider.refresh,
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
                      ),
                    ),
                    if (provider.signalements.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          config.isSmall ? 12 : 20,
                          8,
                          config.isSmall ? 12 : 20,
                          4,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _ListHeader(
                            provider: provider,
                            isDark: isDark,
                            config: config,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        config.isSmall ? 12 : 16,
                        4,
                        config.isSmall ? 12 : 16,
                        100,
                      ),
                      sliver: provider.signalements.isEmpty
                          ? SliverToBoxAdapter(
                          child: _EmptyState(isDark: isDark, config: config))
                          : SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) => _SignalementCard(
                            signalement: provider.signalements[i],
                            isDark: isDark,
                            config: config,
                            statusInfo: _getStatusInfo(provider.signalements[i]),
                            problemIcon: _getProblemIcon(provider.signalements[i].typeProbleme),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SignalementDetailScreen(
                                    signalementId: provider.signalements[i].id),
                              ),
                            ),
                          ),
                          childCount: provider.signalements.length,
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
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text(
        'Mes Signalements',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
      ),
      centerTitle: true,
      actions: [
        Consumer<SignalementProvider>(
          builder: (_, provider, __) {
            if (!provider.isFromCache) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 13, color: Colors.white),
                  SizedBox(width: 3),
                  Text('Cache',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: _showInfoDialog,
          tooltip: 'Types de problèmes',
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    final config = ResponsiveConfig.fromConstraints(
      BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    );
    return FloatingActionButton.extended(
      heroTag: 'btn_ajouter_signalement',
      onPressed: () => _goToCreate(context),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        config.isSmall ? 'Signalement' : 'Créer un signalement',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppTheme.errorColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    );
  }

  void _showInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final problems = [
      {'type': 'PLOMBERIE',   'desc': 'Fuite d\'eau, robinets, sanitaires'},
      {'type': 'ÉLECTRICITÉ', 'desc': 'Pannes, prises, interrupteurs'},
      {'type': 'TOITURE',     'desc': 'Infiltrations, tuiles, gouttières'},
      {'type': 'SERRURE',     'desc': 'Portes, fenêtres, fermetures'},
      {'type': 'MOBILIER',    'desc': 'Lits, tables, chaises, armoires'},
      {'type': 'AUTRE',       'desc': 'Autres problèmes non listés'},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text('Types de problèmes',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ]),
              const SizedBox(height: 16),
              Text('Catégories de signalements disponibles :',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              ...problems.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['type']!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(p['desc']!,
                        style: TextStyle(fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
                  ])),
                ]),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Carte statistiques
// ════════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  final SignalementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;

  const _StatsCard({
    required this.provider,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final margin = config.isSmall ? 12.0 : 16.0;
    final pad    = config.responsive(small: 14, medium: 18, large: 22);
    final titleSize = config.responsive(small: 12, medium: 13, large: 14);

    return Container(
      margin: EdgeInsets.fromLTRB(margin, margin, margin, 6),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded,
                color: Colors.white.withOpacity(0.9), size: 18),
            const SizedBox(width: 8),
            Text('Aperçu des signalements',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: config.isShortScreen ? 10 : 14),

          config.isTablet
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Total',      value: provider.totalSignalements.toString(),    icon: Icons.report_problem_rounded,  iconColor: Colors.white.withOpacity(0.9), config: config),
              _StatItem(label: 'En attente', value: provider.signalementsEnAttente.toString(), icon: Icons.pending_actions_rounded, iconColor: Colors.amber[300]!,           config: config),
              _StatItem(label: 'En cours',   value: provider.signalementsEnCours.toString(),   icon: Icons.build_rounded,          iconColor: Colors.blue[300]!,            config: config),
              _StatItem(label: 'Résolus',    value: provider.signalementsResolus.toString(),   icon: Icons.check_circle_rounded,   iconColor: Colors.green[300]!,           config: config),
            ],
          )
              : GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: config.isSmall ? 0.85 : 1.0,
            crossAxisSpacing: config.isSmall ? 6 : 10,
            mainAxisSpacing: 0,
            children: [
              _StatItem(label: 'Total',      value: provider.totalSignalements.toString(),    icon: Icons.report_problem_rounded,  iconColor: Colors.white.withOpacity(0.9), config: config),
              _StatItem(label: 'En attente', value: provider.signalementsEnAttente.toString(), icon: Icons.pending_actions_rounded, iconColor: Colors.amber[300]!,           config: config),
              _StatItem(label: 'En cours',   value: provider.signalementsEnCours.toString(),   icon: Icons.build_rounded,          iconColor: Colors.blue[300]!,            config: config),
              _StatItem(label: 'Résolus',    value: provider.signalementsResolus.toString(),   icon: Icons.check_circle_rounded,   iconColor: Colors.green[300]!,           config: config),
            ],
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
    final iconPad   = config.responsive(small: 5, medium: 7, large: 9);
    final iconSize  = config.responsive(small: 15, medium: 18, large: 21);
    final valueSize = config.responsive(small: 13, medium: 16, large: 18);
    final labelSize = config.responsive(small: 8,  medium: 10, large: 11);

    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          SizedBox(height: config.isSmall ? 4 : 6),
          Text(value,
              style: TextStyle(
                  color: Colors.white, fontSize: valueSize, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// En-tête de liste
// ════════════════════════════════════════════════════════════════

class _ListHeader extends StatelessWidget {
  final SignalementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;

  const _ListHeader({
    required this.provider,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 13, medium: 15, large: 16);
    final badgeSize = config.responsive(small: 10, medium: 12, large: 12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Historique (${provider.totalSignalements})',
          style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey[700]),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: config.isSmall ? 8 : 12,
              vertical: config.isSmall ? 3 : 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${provider.totalSignalements} signalement${provider.totalSignalements > 1 ? "s" : ""}',
            style: TextStyle(
                fontSize: badgeSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Carte signalement
// ════════════════════════════════════════════════════════════════

class _SignalementCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final _StatusInfo statusInfo;
  final IconData problemIcon;
  final VoidCallback onTap;

  const _SignalementCard({
    required this.signalement,
    required this.isDark,
    required this.config,
    required this.statusInfo,
    required this.problemIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad       = config.responsive(small: 12, medium: 16, large: 18);
    final typeSize      = config.responsive(small: 14, medium: 16, large: 17);
    final descSize      = config.responsive(small: 12, medium: 13, large: 14);
    final metaSize      = config.responsive(small: 10, medium: 11, large: 12);
    final iconSize      = config.responsive(small: 18, medium: 21, large: 23);
    final iconPad       = config.responsive(small: 7,  medium: 9,  large: 10);
    final statusFont    = config.responsive(small: 10, medium: 11, large: 12);

    // Numéro tronqué
    final num = signalement.numeroSuivi;
    final displayNum = num.length > (config.isSmall ? 10 : 16)
        ? '${num.substring(0, config.isSmall ? 9 : 15)}…'
        : num;

    // Date formatée
    final dateStr = config.isSmall
        ? DateFormat('dd/MM/yy').format(signalement.createdAt)
        : DateFormat('dd MMM yyyy · HH:mm').format(signalement.createdAt);

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
                // ── Ligne 1 : statut + numéro suivi ──
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: config.isSmall ? 8 : 10,
                        vertical: config.isSmall ? 4 : 5),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusInfo.icon, color: statusInfo.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        signalement.statut.replaceAll('_', ' '),
                        style: TextStyle(
                            color: statusInfo.color,
                            fontSize: statusFont,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (displayNum.isNotEmpty)
                    Text(displayNum,
                        style: TextStyle(
                            fontSize: metaSize,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                ]),

                SizedBox(height: config.isSmall ? 10 : 14),

                // ── Ligne 2 : icône + type problème ──
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(iconPad),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(problemIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: iconSize),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      signalement.typeProbleme.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: typeSize,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
                ]),

                SizedBox(height: config.isSmall ? 8 : 10),

                // ── Description tronquée ──
                Text(
                  signalement.description,
                  style: TextStyle(
                      fontSize: descSize,
                      color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                      height: 1.4),
                  maxLines: config.isSmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: config.isSmall ? 8 : 12),

                // ── Méta : date | photos | chambre ──
                Wrap(
                  spacing: config.isSmall ? 8 : 12,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                        icon: Icons.calendar_today_rounded,
                        text: dateStr,
                        isDark: isDark,
                        fontSize: metaSize),
                    if (signalement.photos.isNotEmpty)
                      _MetaChip(
                          icon: Icons.photo_library_rounded,
                          text: '${signalement.photos.length}',
                          isDark: isDark,
                          fontSize: metaSize),
                    if ((signalement.numeroChambre ?? '').isNotEmpty)
                      _MetaChip(
                          icon: Icons.room_rounded,
                          text: signalement.numeroChambre!,
                          isDark: isDark,
                          fontSize: metaSize),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final double fontSize;

  const _MetaChip(
      {required this.icon,
        required this.text,
        required this.isDark,
        required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade400 : Colors.grey[600]!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text,
          style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════
// États : loading / erreur / vide
// ════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  final ResponsiveConfig config;
  const _LoadingState({required this.config});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(
            strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text('Chargement des signalements…',
            style: TextStyle(
                fontSize: config.responsive(small: 13, medium: 15, large: 16),
                color: isDark ? Colors.grey.shade300 : Colors.grey[600])),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final ResponsiveConfig config;
  const _EmptyState({required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 60, medium: 75, large: 85);
    final titleSize = config.responsive(small: 18, medium: 21, large: 23);
    final bodySize  = config.responsive(small: 13, medium: 14, large: 15);
    final hPad      = config.responsive(small: 20, medium: 32, large: 48);
    final vPad      = config.responsive(small: 40, medium: 55, large: 65);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.report_problem_outlined,
            size: iconSize, color: isDark ? Colors.grey.shade700 : Colors.grey[300]),
        const SizedBox(height: 20),
        Text('Aucun signalement',
            style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey.shade300 : Colors.grey[600])),
        const SizedBox(height: 10),
        Text('Vous n\'avez effectué aucun signalement pour le moment',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: bodySize,
                color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                height: 1.5)),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onRetry;

  const _ErrorState(
      {required this.error,
        required this.isDark,
        required this.config,
        required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 56, medium: 68, large: 76);
    final titleSize = config.responsive(small: 17, medium: 19, large: 21);
    final bodySize  = config.responsive(small: 12, medium: 14, large: 15);
    final hPad      = config.responsive(small: 20, medium: 32, large: 48);

    final displayError =
    config.isSmall && error.length > 80 ? '${error.substring(0, 79)}…' : error;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded,
            size: iconSize, color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
        const SizedBox(height: 20),
        Text('Erreur de chargement',
            style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey[600])),
        const SizedBox(height: 10),
        Text(displayError,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: bodySize,
                color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
                horizontal: config.isSmall ? 20 : 28,
                vertical: config.isSmall ? 11 : 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
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