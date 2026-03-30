import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../widgets/custom_button.dart';

class InitierPaiementScreen extends StatefulWidget {
  const InitierPaiementScreen({Key? key}) : super(key: key);

  @override
  State<InitierPaiementScreen> createState() => _InitierPaiementScreenState();
}

class _InitierPaiementScreenState extends State<InitierPaiementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();

  String? _modePaiement;
  bool _isLoading = false;
  bool _isLoadingLoyer = true;

  // Données loyer
  double? _loyerMensuel;
  String? _numeroChambre;
  String? _nomCentre;

  // Sélection mois
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de récupérer le loyer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  double get _montantTotal => (_loyerMensuel ?? 0) * _nombreMois;

  DateTime get _dateFin {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _nombreMois, now.day - 1);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modePaiement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await _showConfirmDialog();
    if (!confirm) return;

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
      await _showSuccessDialog(result);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmer le paiement',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Loyer mensuel', '${fmt.format(_loyerMensuel)} FCFA', isDark),
            _row('Nombre de mois', '$_nombreMois mois', isDark),
            const Divider(height: 20),
            _row('Montant total', '${fmt.format(_montantTotal)} FCFA', isDark, bold: true),
            _row('Mode', _getModeLabel(_modePaiement!), isDark),
            _row('Numéro', _telephoneController.text, isDark),
            _row('Période', '${DateFormat('dd/MM/yyyy').format(DateTime.now())} → ${DateFormat('dd/MM/yyyy').format(_dateFin)}', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _row(String label, String value, bool isDark, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey[600], fontSize: 14)),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          )),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paiement = result['paiement'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Paiement initié',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre demande a été enregistrée.',
                style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
            const SizedBox(height: 12),
            if (paiement != null) ...[
              Text('Référence: ${paiement['reference']}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
              const SizedBox(height: 4),
              Text('Période: ${paiement['date_debut']} → ${paiement['date_fin']}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
            const SizedBox(height: 8),
            Text('Vous recevrez une notification de confirmation.',
                style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      default: return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Nouveau paiement')),
      body: _isLoadingLoyer
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Carte loyer info ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_nomCentre - Ch. $_numeroChambre',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87)),
                          Text('Loyer mensuel : ${fmt.format(_loyerMensuel)} FCFA',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Sélection nombre de mois ──
              Text('Durée du paiement',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 12),

              // Boutons rapides
              Row(
                children: _optionsMois.map((mois) {
                  final isSelected = _nombreMois == mois;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _nombreMois = mois),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text('$mois',
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white
                                          : (isDark ? Colors.white : Colors.black87))),
                              Text('mois',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.white70
                                          : (isDark ? Colors.grey.shade400 : Colors.grey))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Résumé montant ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Text('${fmt.format(_montantTotal)} FCFA',
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    Text('$_nombreMois × ${fmt.format(_loyerMensuel)} FCFA',
                        style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(DateTime.now())} → ${DateFormat('dd/MM/yyyy').format(_dateFin)}',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade300 : Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Mode de paiement ──
              Text('Mode de paiement',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 12),

              _buildModeCard('ORANGE_MONEY', 'Orange Money',
                  'assets/images/logo_orange.png', const Color(0xFFFF6600), isDark),
              const SizedBox(height: 12),
              _buildModeCard('MOOV_MONEY', 'Moov Money',
                  'assets/images/logo_moov.png', const Color(0xFF0066CC), isDark),

              const SizedBox(height: 28),

              // ── Numéro de téléphone ──
              Text('Numéro de téléphone',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                    fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: '+226 70 XX XX XX',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
                  prefixIcon: Icon(Icons.phone,
                      color: Theme.of(context).colorScheme.primary),
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
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'PAYER ${fmt.format(_montantTotal)} FCFA',
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                icon: Icons.payment,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String value, String label, String logo, Color color, bool isDark) {
    final isSelected = _modePaiement == value;
    return GestureDetector(
      onTap: () => setState(() => _modePaiement = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 3 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(logo,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.phone_android, color: color, size: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87)),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : (isDark ? Colors.grey.shade600 : Colors.grey[400]),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}