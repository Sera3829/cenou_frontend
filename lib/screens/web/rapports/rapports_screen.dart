import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/rapport_service.dart';
import '../../../providers/web/rapport_provider.dart';
import '../../../models/admin/centre.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../config/theme.dart';

/// Écran de génération des rapports (financier et occupation).
class RapportsScreen extends StatefulWidget {
  const RapportsScreen({Key? key}) : super(key: key);

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  String _selectedPeriod = 'current_month';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCentreId;
  bool _isLoadingFinancial = false;
  bool _isLoadingOccupancy = false;

  @override
  void initState() {
    super.initState();
    // Charger les centres au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCentres();
    });
  }

  /// Charge la liste des centres via le provider.
  Future<void> _loadCentres() async {
    final provider = Provider.of<RapportProvider>(context, listen: false);
    if (provider.centres.isEmpty) {
      await provider.loadCentres();
    }
  }

  /// Génère le rapport financier dans le format demandé.
  Future<void> _generateFinancialReport(String format) async {
    setState(() => _isLoadingFinancial = true);

    try {
      String? periodeApi;

      // Mapper les valeurs de période
      switch (_selectedPeriod) {
        case 'current_month':
          periodeApi = 'mois_en_cours';
          break;
        case 'last_month':
          periodeApi = 'mois_dernier';
          break;
        case 'quarter':
          periodeApi = 'trimestre';
          break;
        case 'custom':
          periodeApi = null;
          break;
        default:
          periodeApi = _selectedPeriod;
      }

      await RapportService.genererRapportFinancier(
        context: context,
        format: format,
        periode: periodeApi,
        centreId: _selectedCentreId,
        dateDebut: _startDate,
        dateFin: _endDate,
      );

      _showSuccessSnackBar('Rapport financier généré avec succès');
    } catch (error) {
      _showErrorSnackBar('Erreur lors de la génération: ${error.toString()}');
    } finally {
      setState(() => _isLoadingFinancial = false);
    }
  }

  /// Génère le rapport d'occupation dans le format demandé.
  Future<void> _generateOccupancyReport(String format) async {
    setState(() => _isLoadingOccupancy = true);

    try {
      await RapportService.genererRapportOccupation(
        context: context,
        format: format,
        centreId: _selectedCentreId,
      );

      _showSuccessSnackBar("Rapport d'occupation généré avec succès");
    } catch (error) {
      _showErrorSnackBar('Erreur lors de la génération: ${error.toString()}');
    } finally {
      setState(() => _isLoadingOccupancy = false);
    }
  }

  /// Affiche la feuille de sélection du format (PDF/Excel).
  Future<void> _showFormatSelection(String reportType) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFormatBottomSheet(reportType, isDark),
    );

    if (format != null && mounted) {
      if (reportType == 'Financier') {
        await _generateFinancialReport(format);
      } else {
        await _generateOccupancyReport(format);
      }
    }
  }

  /// Construit la feuille inférieure de choix du format.
  Widget _buildFormatBottomSheet(String reportType, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Format du rapport $reportType',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),
          _buildFormatOption(
            icon: Icons.picture_as_pdf,
            color: Colors.red,
            title: 'PDF',
            subtitle: 'Format optimisé pour l\'impression',
            value: 'pdf',
            onTap: () => Navigator.pop(context, 'pdf'),
          ),
          _buildFormatOption(
            icon: Icons.table_chart,
            color: Colors.green,
            title: 'Excel',
            subtitle: 'Format modifiable avec données brutes',
            value: 'excel',
            onTap: () => Navigator.pop(context, 'excel'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Élément de choix de format dans la feuille.
  Widget _buildFormatOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.getTextSecondary(context),
          fontSize: 14,
        ),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
      ),
      onTap: onTap,
    );
  }

  /// Ouvre le sélecteur de date de début.
  Future<void> _selectStartDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: AppTheme.getCardBackground(context),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: AppTheme.getTextPrimary(context)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  /// Ouvre le sélecteur de date de fin.
  Future<void> _selectEndDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: AppTheme.getCardBackground(context),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: AppTheme.getTextPrimary(context)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  /// Affiche un message de succès.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Affiche un message d'erreur.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 5,
      child: Consumer<RapportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.centres.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.loadCentres(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte rapport financier
                _buildReportCard(
                  title: 'Rapport Financier',
                  icon: Icons.attach_money_rounded,
                  iconColor: AppTheme.successColor,
                  buttonColor: AppTheme.successColor,
                  isLoading: _isLoadingFinancial,
                  onGenerate: () => _showFormatSelection('Financier'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période d\'analyse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPeriodChip('Mois en cours', 'current_month'),
                          _buildPeriodChip('Mois dernier', 'last_month'),
                          _buildPeriodChip('Trimestre', 'quarter'),
                          _buildPeriodChip('Personnalisée', 'custom'),
                        ],
                      ),
                      if (_selectedPeriod == 'custom') ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'Date de début',
                                date: _startDate,
                                onTap: _selectStartDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'Date de fin',
                                date: _endDate,
                                onTap: _selectEndDate,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildCentreDropdown(provider.centres),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Carte rapport d'occupation
                _buildReportCard(
                  title: "Rapport d'Occupation",
                  icon: Icons.hotel_rounded,
                  iconColor: AppTheme.infoColor,
                  buttonColor: AppTheme.infoColor,
                  isLoading: _isLoadingOccupancy,
                  onGenerate: () => _showFormatSelection('Occupation'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Analysez le taux d'occupation, les logements disponibles et les attributions en cours.",
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCentreDropdown(provider.centres),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Panneau d'information
                _buildInfoPanel(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit une carte de rapport (titre, contenu, bouton).
  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color buttonColor,
    required bool isLoading,
    required VoidCallback onGenerate,
    required Widget content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Séparateur
          Container(
              height: 1,
              color: AppTheme.getBorderColor(context)
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
          // Bouton de génération
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: isLoading
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assessment_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Générer le rapport',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un chip de période sélectionnable.
  Widget _buildPeriodChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPeriod == value;
    final selectedColor = Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedPeriod = value;
          if (value != 'custom') {
            _startDate = null;
            _endDate = null;
          }
        });
      },
      selectedColor: selectedColor,
      backgroundColor: isDark ? Colors.grey.shade800.withOpacity(0.3) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? selectedColor : AppTheme.getBorderColor(context),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Construit un champ de sélection de date.
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: date != null
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.getTextTertiary(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 15,
                      color: date != null
                          ? AppTheme.getTextPrimary(context)
                          : AppTheme.getTextTertiary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le menu déroulant de sélection du centre.
  Widget _buildCentreDropdown(List<Centre> centres) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centre (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
          ),
          value: _selectedCentreId,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Tous les centres',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            ),
            ...centres.map((centre) {
              return DropdownMenuItem(
                value: centre.id,
                child: Text(
                  centre.nom,
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
              );
            }).toList(),
          ],
          onChanged: (value) => setState(() => _selectedCentreId = value),
          borderRadius: BorderRadius.circular(10),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.getTextTertiary(context)),
          dropdownColor: AppTheme.getCardBackground(context),
        ),
      ],
    );
  }

  /// Construit le panneau d'information explicative.
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900.withOpacity(0.3)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.infoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations importantes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les rapports sont générés en temps réel avec les données actualisées. '
                      'Les fichiers PDF sont optimisés pour l\'impression, '
                      'tandis que les fichiers Excel contiennent les données brutes pour analyse approfondie.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}