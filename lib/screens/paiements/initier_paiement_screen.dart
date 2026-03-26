import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final _montantController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _montantFocusNode = FocusNode();
  final _telephoneFocusNode = FocusNode();

  int _currentStep = 0;
  String? _modePaiement;
  bool _isLoading = false;

  @override
  void dispose() {
    _montantController.dispose();
    _telephoneController.dispose();
    _montantFocusNode.dispose();
    _telephoneFocusNode.dispose();
    super.dispose();
  }

  bool _canProceedToStep(int step) {
    switch (step) {
      case 1:
      // Peut passer à l'étape 2 si montant valide
        final montant = double.tryParse(_montantController.text);
        return montant != null && montant > 0 && montant <= 1000000;
      case 2:
      // Peut passer à l'étape 3 si mode de paiement sélectionné
        return _modePaiement != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_canProceedToStep(_currentStep + 1)) {
      setState(() {
        _currentStep++;
      });
      // Donner le focus au champ téléphone à la dernière étape
      if (_currentStep == 2) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _telephoneFocusNode.requestFocus();
        });
      }
    } else {
      // Afficher un message d'erreur
      String message = '';
      if (_currentStep == 0) {
        message = 'Veuillez entrer un montant valide';
      } else if (_currentStep == 1) {
        message = 'Veuillez sélectionner un mode de paiement';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final montant = double.parse(_montantController.text);
    final telephone = _telephoneController.text.trim();

    // Confirmation
    final confirm = await _showConfirmDialog(montant);
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final paiementProvider = Provider.of<PaiementProvider>(context, listen: false);

      final result = await paiementProvider.initierPaiement(
        montant: montant,
        modePaiement: _modePaiement!,
        numeroTelephone: telephone,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmDialog(double montant) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Confirmer le paiement',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Montant', '${montant.toStringAsFixed(0)} FCFA', isDark),
            Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            _buildConfirmRow('Mode', _getPaymentMethodLabel(_modePaiement!), isDark),
            Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            _buildConfirmRow('Numéro', _telephoneController.text, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildConfirmRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'MOOV_MONEY':
        return 'Moov Money';
      default:
        return method;
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentUrl = result['paiement']?['payment_url'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Paiement initié',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre demande de paiement a été enregistrée.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (paymentUrl != null) ...[
              Text(
                'Suivez les instructions sur votre téléphone pour confirmer le paiement.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Référence: ${result['paiement']?['reference']}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600]
                ),
              ),
            ] else ...[
              Text(
                'Vous recevrez une notification de confirmation.',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau paiement'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicateur d'étapes
            _buildStepIndicator(isDark),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(isDark),
              ),
            ),

            // Boutons de navigation
            _buildNavigationButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(0, 'Montant', isDark),
          _buildStepLine(0, isDark),
          _buildStepCircle(1, 'Mode', isDark),
          _buildStepLine(1, isDark),
          _buildStepCircle(2, 'Téléphone', isDark),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool isDark) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.grey.shade800 : Colors.grey[300]),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey[600]),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step, bool isDark) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : (isDark ? Colors.grey.shade800 : Colors.grey[300]),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildMontantStep(isDark);
      case 1:
        return _buildModePaiementStep(isDark);
      case 2:
        return _buildTelephoneStep(isDark);
      default:
        return Container();
    }
  }

  Widget _buildMontantStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Quel montant souhaitez-vous payer ?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 32),

        // Champ de saisie du montant
        Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _montantController,
                      focusNode: _montantFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        final montant = double.tryParse(value);
                        if (montant == null || montant <= 0) {
                          return 'Montant invalide';
                        }
                        if (montant > 1000000) {
                          return 'Max: 1 000 000 FCFA';
                        }
                        return null;
                      },
                    ),
                  ),
                  Text(
                    'FCFA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Montants suggérés
        Text(
          'Montants suggérés',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1000, 2000, 3000, 5000, 10000, 20000].map((montant) {
            return ActionChip(
              label: Text(
                '${montant.toStringAsFixed(0)} F',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onPressed: () {
                _montantController.text = montant.toString();
              },
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey[300]!),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        Text(
          'Limite maximale : 1 000 000 FCFA',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildModePaiementStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Choisissez votre mode de paiement',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Montant: ${_montantController.text} FCFA',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        _buildPaymentMethodCard(
          'ORANGE_MONEY',
          'Orange Money',
          'assets/images/logo_orange.png',
          const Color(0xFFFF6600),
          isDark,
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodCard(
          'MOOV_MONEY',
          'Moov Money',
          'assets/images/logo_moov.png',
          const Color(0xFF0066CC),
          isDark,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
      String value,
      String label,
      String logoPath,
      Color color,
      bool isDark,
      ) {
    final isSelected = _modePaiement == value;

    return InkWell(
      onTap: () {
        setState(() {
          _modePaiement = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey[300]!),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            // Logo (utilise Image.asset si disponible, sinon fallback sur icône)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  logoPath,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback si l'image n'existe pas
                    return Icon(
                      Icons.phone_android,
                      color: color,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 32)
            else
              Icon(
                  Icons.circle_outlined,
                  color: isDark ? Colors.grey.shade600 : Colors.grey[400],
                  size: 32
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelephoneStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Entrez votre numéro de téléphone',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Montant: ${_montantController.text} FCFA · ${_getPaymentMethodLabel(_modePaiement!)}',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextFormField(
            controller: _telephoneController,
            focusNode: _telephoneFocusNode,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '+226 70 XX XX XX',
              hintStyle: TextStyle(
                fontSize: 24,
                color: isDark ? Colors.grey.shade600 : Colors.grey[400],
              ),
              prefixIcon: Icon(
                Icons.phone,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro de téléphone est requis';
              }
              if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value.replaceAll(' ', ''))) {
                return 'Numéro de téléphone invalide';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.shade900.withOpacity(0.3)
                : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue.shade300 : Colors.blue[700],
                  size: 20
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous recevrez une notification pour confirmer le paiement',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.blue.shade300 : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Précédent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _currentStep > 0 ? 1 : 1,
              child: CustomButton(
                text: _currentStep < 2 ? 'Continuer' : 'Payer',
                onPressed: _isLoading
                    ? null
                    : (_currentStep < 2 ? _nextStep : _handleSubmit),
                isLoading: _isLoading,
                icon: _currentStep < 2 ? Icons.arrow_forward : Icons.check,
              ),
            ),
          ],
        ),
      ),
    );
  }
}