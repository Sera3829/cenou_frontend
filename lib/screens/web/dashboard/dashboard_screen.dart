// screens/web/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../../models/admin/activity.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/skeleton/skeletons.dart';
import 'dashboard_layout.dart';
import 'widgets/dashboard_welcome.dart';
import 'widgets/dashboard_stats_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardStatsFuture;
  late Future<Map<String, dynamic>> _dashboardChartsFuture;
  late Future<Map<String, dynamic>> _recentActivityFuture;

  List<ChartData> _revenueData = [];
  List<PieData> _signalementTypesData = [];

  // Évite le double chargement
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger sauf lors du premier chargement
    if (!_isFirstLoad) {
      _loadDashboardData();
    } else {
      _isFirstLoad = false;
    }
  }

  /// Charge toutes les données du tableau de bord.
  void _loadDashboardData() {
    setState(() {
      _dashboardStatsFuture = _apiService.getDashboardStats();
      _dashboardChartsFuture = _apiService.getDashboardCharts(period: 'month');
      _recentActivityFuture = _apiService.getRecentActivity();
    });
  }

  /// Formate une période pour l'affichage sur les axes.
  String _formatChartPeriod(String period, AppLocalizations l10n) {
    try {
      final date = DateTime.parse(period);
      final months = l10n.monthsShort.split(',');
      return months[date.month - 1];
    } catch (e) {
      return period;
    }
  }

  /// Traite les données de graphiques brutes.
  void _processChartData(Map<String, dynamic> chartsData, AppLocalizations l10n) {
    _revenueData = [];
    _signalementTypesData = [];

    final data = chartsData['data'] as Map<String, dynamic>? ?? {};
    final paiementsData = data['paiements'] as List? ?? [];

    if (paiementsData.isNotEmpty) {
      final Map<String, double> revenueByPeriod = {};

      for (var item in paiementsData) {
        final period = item['period']?.toString() ?? '';
        final total = _safeToDouble(item['total']);
        final periodFormatted = _formatChartPeriod(period, l10n);
        revenueByPeriod[periodFormatted] = (revenueByPeriod[periodFormatted] ?? 0) + total;
      }

      _revenueData = revenueByPeriod.entries
          .map((entry) => ChartData(period: entry.key, value: entry.value))
          .toList();
      _revenueData.sort((a, b) => a.period.compareTo(b.period));
    }

    final signalementsTypesData = data['signalements_types'] as List? ?? [];
    if (signalementsTypesData.isNotEmpty) {
      _signalementTypesData = signalementsTypesData
          .map((item) => PieData(
        type: item['type_probleme']?.toString() ?? l10n.other,
        value: _safeToDouble(item['count']),
      ))
          .toList();
    }
  }

  /// Convertit une valeur en double de manière sécurisée.
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(',', '.').replaceAll(' ', '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 0,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 900 ? 32 : 16,
          vertical: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardWelcome(l10n: l10n, onRefresh: _loadDashboardData),
            const SizedBox(height: 32),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardStatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonStatsGrid();
                }
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString(), l10n);
                }
                final stats = snapshot.data?['data'] ?? {};
                return DashboardStatsGrid(stats: stats, l10n: l10n);
              },
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width >= 900) {
                  // Grand écran : côte à côte
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _dashboardChartsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SkeletonChartCard();
                            }
                            if (snapshot.hasData) {
                              _processChartData(snapshot.data!, l10n);
                              return _buildRevenueChart(l10n);
                            }
                            return Container();
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildSignalementsChart(l10n),
                      ),
                    ],
                  );
                } else {
                  // Petit écran : empilés verticalement
                  return Column(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _dashboardChartsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SkeletonChartCard();
                          }
                          if (snapshot.hasData) {
                            _processChartData(snapshot.data!, l10n);
                            return _buildRevenueChart(l10n);
                          }
                          return Container();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSignalementsChart(l10n),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            _buildRecentActivity(l10n),
          ],
        ),
      ),
    );
  }

  /// Section de bienvenue.
  /// Graphique des revenus mensuels.
  Widget _buildRevenueChart(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyRevenue,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _revenueData.isNotEmpty
                ? SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat('#,### F', l10n.locale.languageCode),
                labelStyle: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: _revenueData,
                  xValueMapper: (ChartData data, _) => data.period,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                ),
              ],
            )
                : Center(
              child: Text(
                l10n.noData,
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Graphique des signalements par type.
  Widget _buildSignalementsChart(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardChartsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportsByType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportsByType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          l10n.loadingError,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _processChartData(snapshot.data!, l10n);
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reportsByType,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.problemDistribution,
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: _signalementTypesData.isNotEmpty
                    ? SfCircularChart(
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    format: l10n.reportsTooltipFormat,
                    canShowMarker: false,
                  ),
                  series: <CircularSeries>[
                    PieSeries<PieData, String>(
                      dataSource: _signalementTypesData,
                      xValueMapper: (PieData data, _) => data.type,
                      yValueMapper: (PieData data, _) => data.value,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      explode: true,
                      explodeIndex: 0,
                      enableTooltip: true,
                    ),
                  ],
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: 50,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noDataAvailable,
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section des activités récentes.
  Widget _buildRecentActivity(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recentActivityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecentActivitySkeleton(l10n);
        }

        if (snapshot.hasError) {
          return _buildRecentActivityError(snapshot.error.toString(), l10n);
        }

        final data = snapshot.data?['data'] as Map<String, dynamic>? ?? {};
        final activitiesData = data['activities'] as List? ?? [];

        if (activitiesData.isEmpty) {
          return _buildNoRecentActivity(l10n);
        }

        final activities = activitiesData
            .map((json) => Activity.fromJson(json))
            .toList();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentActivity,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboardData,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.refresh,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activities.take(5).map((activity) => _buildActivityItem(activity, l10n)),
              if (activities.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      l10n.viewAllActivities,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Squelette d'affichage pendant le chargement des activités.
  Widget _buildRecentActivitySkeleton(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildActivitySkeletonItem()),
        ],
      ),
    );
  }

  /// Élément squelette pour une activité.
  Widget _buildActivitySkeletonItem() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une erreur pour les activités récentes.
  Widget _buildRecentActivityError(String error, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentActivity,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.loadingError,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.length > 100 ? '${error.substring(0, 100)}...' : error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage lorsqu'aucune activité récente n'est disponible.
  Widget _buildNoRecentActivity(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentActivity,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 50,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noRecentActivity,
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.newActivitiesWillAppear,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément individuel d'activité.
  Widget _buildActivityItem(Activity activity, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.getLocalizedTitle(l10n),   // ← Titre traduit
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.getLocalizedDescription(l10n),   // ← Description traduite
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.metadata['type_probleme'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activity.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activity.metadata['type_probleme'].toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: activity.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.getLocalizedTimeAgo(l10n),   // ← Temps relatif traduit
                style: TextStyle(
                  color: AppTheme.getTextTertiary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm', l10n.locale.languageCode).format(activity.timestamp),
                style: TextStyle(
                  color: AppTheme.getTextTertiary(context).withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Affiche un widget d'erreur général.
  Widget _buildErrorWidget(String error, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            '${l10n.error}: $error',
            style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// Données pour un graphique en colonnes.
class ChartData {
  final String period;
  final double value;
  ChartData({required this.period, required this.value});
}

/// Données pour un graphique circulaire.
class PieData {
  final String type;
  final double value;
  PieData({required this.type, required this.value});
}