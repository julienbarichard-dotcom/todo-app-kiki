import 'package:flutter/material.dart';

/// Boîte de dialogue réutilisable pour sélectionner l'heure avec des curseurs pour les heures et minutes
/// Extrait pour éviter la duplication entre add_task_screen et edit_task_screen
class TimePickerDialog {
  /// Affiche une boîte de dialogue de sélection d'heure avec des curseurs pour les heures et minutes
  ///
  /// [context] Le contexte de construction pour afficher la boîte de dialogue
  /// [initialTime] L'heure initiale à afficher, par défaut l'heure actuelle si null
  ///
  /// Renvoie le [TimeOfDay] sélectionné ou null si annulé
  static Future<TimeOfDay?> show({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    int selectedHour = initialTime?.hour ?? DateTime.now().hour;
    int selectedMinute = initialTime?.minute ?? 0;

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sélectionner l\'heure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Affichage de l'heure sélectionnée
              Text(
                '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Curseurs pour les heures et minutes
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Heure'),
                        Slider(
                          value: selectedHour.toDouble(),
                          min: 0,
                          max: 23,
                          divisions: 23,
                          onChanged: (value) =>
                              setState(() => selectedHour = value.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Minutes'),
                        Slider(
                          value: selectedMinute.toDouble(),
                          min: 0,
                          max: 59,
                          divisions: 59,
                          onChanged: (value) =>
                              setState(() => selectedMinute = value.toInt()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                TimeOfDay(hour: selectedHour, minute: selectedMinute),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
