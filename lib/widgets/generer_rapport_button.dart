// lib/widgets/generer_rapport_button.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/rapport_service.dart';

class GenererRapportButton extends StatefulWidget {
  final String typeRapport; // 'financier' ou 'occupation'
  final Map<String, dynamic>? parametres;

  const GenererRapportButton({
    Key? key,
    required this.typeRapport,
    this.parametres,
  }) : super(key: key);

  @override
  _GenererRapportButtonState createState() => _GenererRapportButtonState();
}

class _GenererRapportButtonState extends State<GenererRapportButton> {
  bool _isLoading = false;

  Future<void> _genererEtPartager() async {
    setState(() => _isLoading = true);

    try {
      // 1. Demander le format
      final format = await _showFormatDialog();
      if (format == null) return;

      // 2. Générer le rapport (le service gère lui-même le téléchargement)
      if (widget.typeRapport == 'financier') {
        await RapportService.genererRapportFinancier(
          context: context,
          format: format,
          periode: widget.parametres?['periode'],
          centreId: widget.parametres?['centreId'],
          dateDebut: widget.parametres?['dateDebut'],
          dateFin: widget.parametres?['dateFin'],
        );
      } else {
        await RapportService.genererRapportOccupation(
          context: context,
          format: format,
          centreId: widget.parametres?['centreId'],
        );
      }

      // 3. Montrer un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport généré avec succès, téléchargement en cours...'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showFormatDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir le format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('PDF'),
              subtitle: Text('Format imprimable'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Excel'),
              subtitle: Text('Format modifiable'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showActionDialog(String format) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rapport généré'),
        content: Text('Que voulez-vous faire avec ce fichier ${format.toUpperCase()} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'ouvrir'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_browser),
                SizedBox(width: 8),
                Text('Ouvrir'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'partager'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share),
                SizedBox(width: 8),
                Text('Partager'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'telecharger'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download),
                SizedBox(width: 8),
                Text('Télécharger'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _partagerFichier(File fichier) async {
    try {
      final xFile = XFile(fichier.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Rapport ${widget.typeRapport} - CENOU',
        subject: 'Rapport ${widget.typeRapport}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _telechargerFichier(File fichier) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le rapport',
        fileName: 'rapport_${widget.typeRapport}_${DateTime.now().millisecondsSinceEpoch}.${fichier.path.split('.').last}',
        type: fichier.path.endsWith('.pdf')
            ? FileType.custom
            : FileType.any,
        allowedExtensions: fichier.path.endsWith('.pdf')
            ? ['pdf']
            : ['xlsx', 'xls'],
      );

      if (result != null) {
        await fichier.copy(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _genererEtPartager,
      icon: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(Icons.assessment),
      label: Text(
        _isLoading ? 'Génération...' : 'Générer Rapport',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}