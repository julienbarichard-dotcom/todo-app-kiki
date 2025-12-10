import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/color_extensions.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';

/// Widget Card pour afficher une tâche
class TodoTaskCard extends StatelessWidget {
  final TodoTask tache;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final Function(Statut)? onChangeStatut;

  const TodoTaskCard({
    super.key,
    required this.tache,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
    this.onChangeStatut,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = tache.isRejected;
    final backgroundColor = isRejected ? Colors.red[700] : Colors.grey[900];
    final textColor = isRejected ? Colors.white : Colors.white;
    final textColorSecondary = isRejected ? Colors.white70 : Colors.white70;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isRejected ? Colors.red : tache.urgence.color,
                width: 5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Checkbox, Titre et Urgence
                Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        onToggleComplete();
                      },
                      child: Checkbox(
                        value: tache.estComplete,
                        onChanged: (_) => onToggleComplete(),
                        activeColor: Colors.green,
                      ),
                    ),
                    // Titre et urgence
                    Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tache.titre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                decoration: tache.estComplete
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Badges : urgence, statut, etc.
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRejected
                                        ? Colors.red[600]
                                        : tache.urgence.color
                                            .withOpacitySafe(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tache.urgence.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isRejected
                                          ? Colors.white
                                          : tache.urgence.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Badge statut
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRejected
                                        ? Colors.red[600]
                                        : tache.statut.color
                                            .withOpacitySafe(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRejected
                                          ? Colors.red[400]!
                                          : tache.statut.color
                                              .withOpacitySafe(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tache.statut.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isRejected
                                          ? Colors.white
                                          : tache.statut.color,
                                    ),
                                  ),
                                ),
                                // Petit triangle si tâche reportée
                                if (tache.isReported) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '🔺',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                                // Logo multi-validation collaboratif
                                if (tache.isMultiValidation) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '👥',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                                // Badge label/catégorie
                                if (tache.label != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRejected
                                          ? Colors.red[600]
                                          : const Color(0xFF1DB679)
                                              .withOpacitySafe(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isRejected
                                            ? Colors.red[400]!
                                            : const Color(0xFF1DB679)
                                                .withOpacitySafe(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tache.label!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isRejected
                                            ? Colors.white
                                            : const Color(0xFF1DB679),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Boutons d'action
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: onEdit,
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        if (onChangeStatut != null)
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const Text('Changer statut:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                ...Statut.values.map((statut) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      onChangeStatut!(statut);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: statut.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(statut.label,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const Divider(),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Rappels désactivés : contrôle retiré de la carte UI
                  ],
                ),
                // Description
                if (tache.description.isNotEmpty)
                  GestureDetector(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 48),
                      child: Text(
                        tache.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColorSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                // Sous-tâches
                if (tache.subTasks.isNotEmpty)
                  GestureDetector(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${tache.subTasks.where((st) => st.estComplete).length}/${tache.subTasks.length} sous-tâches',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColorSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${tache.pourcentageAvancement.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColorSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Barre de progression
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: tache.pourcentageAvancement / 100,
                              minHeight: 6,
                              backgroundColor: isRejected
                                  ? Colors.red[400]
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tache.pourcentageAvancement >= 100
                                    ? Colors.green
                                    : tache.pourcentageAvancement >= 50
                                        ? Colors.blue
                                        : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Infos bas : Personnes et Date
                GestureDetector(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, left: 48),
                    child: Row(
                      children: [
                        // Personnes assignées
                        Icon(Icons.people, size: 16, color: textColorSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tache.assignedTo.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: textColorSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formater la date en format lisible
  String _formatDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year;
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour/$mois/$annee $heure:$minute';
  }
}
