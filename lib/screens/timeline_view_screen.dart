import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';
import 'package:intl/intl.dart';

/// Vue Timeline - Affiche les tâches groupées par date de manière chronologique
class TimelineViewScreen extends StatefulWidget {
  final String utilisateur;

  const TimelineViewScreen({super.key, required this.utilisateur});

  @override
  State<TimelineViewScreen> createState() => _TimelineViewScreenState();
}

class _TimelineViewScreenState extends State<TimelineViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        var taches = todoProvider.getTachesPourPersonne(widget.utilisateur);

        // Grouper par date (avec date vs sans date)
        final Map<String, List<TodoTask>> tachesByDate = {};
        final List<TodoTask> tachesSansDate = [];

        for (var tache in taches) {
          if (tache.dateEcheance != null) {
            final dateKey =
                DateFormat('yyyy-MM-dd').format(tache.dateEcheance!);
            tachesByDate.putIfAbsent(dateKey, () => []);
            tachesByDate[dateKey]!.add(tache);
          } else {
            tachesSansDate.add(tache);
          }
        }

        // Trier les dates
        final sortedDates = tachesByDate.keys.toList();
        sortedDates.sort();

        return tachesByDate.isEmpty && tachesSansDate.isEmpty
            ? Center(
                child: Text(
                  'Aucune tâche',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Afficher les tâches avec date d'abord
                  for (var dateKey in sortedDates)
                    _buildDateSection(
                      context,
                      dateKey,
                      tachesByDate[dateKey]!,
                      todoProvider,
                    ),
                  // Puis les tâches sans date
                  if (tachesSansDate.isNotEmpty)
                    _buildDateSection(
                      context,
                      'Sans date',
                      tachesSansDate,
                      todoProvider,
                    ),
                ],
              );
      },
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateLabel,
    List<TodoTask> taches,
    TodoProvider todoProvider,
  ) {
    // Parser la date pour l'affichage
    late String displayDate;
    late DateTime parsedDate;

    if (dateLabel == 'Sans date') {
      displayDate = 'Sans date d\'échéance';
    } else {
      parsedDate = DateTime.parse(dateLabel);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final dateToCheck =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (dateToCheck == today) {
        displayDate = 'Aujourd\'hui';
      } else if (dateToCheck == tomorrow) {
        displayDate = 'Demain';
      } else if (dateToCheck == yesterday) {
        displayDate = 'Hier';
      } else {
        displayDate =
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate);
      }
    }

    // Tri par urgence dans chaque section
    taches.sort((a, b) {
      final urgenceOrder = {'haute': 0, 'moyenne': 1, 'basse': 2};
      final orderA = urgenceOrder[a.urgence.name] ?? 3;
      final orderB = urgenceOrder[b.urgence.name] ?? 3;
      return orderA.compareTo(orderB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de date
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB679),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                displayDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${taches.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tâches de cette date
        for (var tache in taches)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: _buildTimelineTask(context, tache, todoProvider),
          ),
      ],
    );
  }

  Widget _buildTimelineTask(
    BuildContext context,
    TodoTask tache,
    TodoProvider todoProvider,
  ) {
    final isComplete = tache.estComplete;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(tache: tache),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isComplete ? Colors.grey.shade900 : Colors.black,
          border: Border(
            left: BorderSide(
              color: tache.urgence.color,
              width: 3,
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => todoProvider.toggleTacheComplete(tache.id),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tache.urgence.color,
                    width: 2,
                  ),
                  color: isComplete ? tache.urgence.color : Colors.transparent,
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Titre + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tache.titre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration:
                          isComplete ? TextDecoration.lineThrough : null,
                      color: isComplete ? Colors.grey : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tache.description.isNotEmpty)
                    Text(
                      tache.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isComplete ? Colors.grey : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (tache.label != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '📌 ${tache.label}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Menu actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditTaskScreen(tache: tache),
                    ),
                  ).then((modified) {
                    if (modified == true) setState(() {});
                  });
                } else if (value == 'delete') {
                  _confirmDelete(context, tache.id, todoProvider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String tacheId,
    TodoProvider todoProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text('Êtes-vous sûr ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              todoProvider.supprimerTache(tacheId);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
