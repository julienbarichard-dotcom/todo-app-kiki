import 'package:flutter/material.dart';

/// Reusable multi-validation section widget
/// Extracted to avoid duplication between add_task_screen and edit_task_screen
class MultiValidationSection extends StatelessWidget {
  final bool isMultiValidation;
  final ValueChanged<bool> onChanged;
  final int assignedPersonCount;
  final Color accentColor;

  const MultiValidationSection({
    super.key,
    required this.isMultiValidation,
    required this.onChanged,
    required this.assignedPersonCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Multi-validation collaborative',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Checkbox(
                  value: isMultiValidation,
                  activeColor: accentColor,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ],
            ),
            if (isMultiValidation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Text(
                  'ℹ️ Chaque participant assigné devra valider cette tâche avant sa clôture.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (assignedPersonCount < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Text(
                      '⚠️ Minimum 2 personnes requises pour la multi-validation',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
