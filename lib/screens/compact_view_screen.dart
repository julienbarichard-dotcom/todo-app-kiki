import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

/// Vue Compacte - Affiche les tâches de manière dense et minimale
class CompactViewScreen extends StatefulWidget {
  final String utilisateur;

  const CompactViewScreen({super.key, required this.utilisateur});

  @override
  State<CompactViewScreen> createState() => _CompactViewScreenState();
}

class _CompactViewScreenState extends State<CompactViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        var taches = todoProvider.getTachesPourPersonne(widget.utilisateur);

        // Tri par urgence (haute > moyenne > basse), puis par date
        taches.sort((a, b) {
          final urgenceOrder = {'haute': 0, 'moyenne': 1, 'basse': 2};
          final orderA = urgenceOrder[a.urgence.name] ?? 3;
          final orderB = urgenceOrder[b.urgence.name] ?? 3;

          if (orderA != orderB) return orderA.compareTo(orderB);

          if (a.dateEcheance == null && b.dateEcheance == null) return 0;
          if (a.dateEcheance == null) return 1;
          if (b.dateEcheance == null) return -1;
          return a.dateEcheance!.compareTo(b.dateEcheance!);
        });

        return taches.isEmpty
            ? Center(
                child: Text(
                  'Aucune tâche',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: taches.length,
                itemBuilder: (context, index) {
                  final tache = taches[index];
                  return _buildCompactCard(context, tache, todoProvider);
                },
              );
      },
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    TodoTask tache,
    TodoProvider todoProvider,
  ) {
    final urgenceColor = tache.urgence.color;
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: urgenceColor, width: 3),
            bottom: BorderSide(
              color: Colors.grey.shade700,
              width: 0.5,
            ),
          ),
          color: isComplete ? Colors.grey.shade900 : Colors.black,
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
                    color: urgenceColor,
                    width: 2,
                  ),
                  color: isComplete ? urgenceColor : Colors.transparent,
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Titre et description compacte
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Date courte (si présente)
            if (tache.dateEcheance != null)
              Text(
                '${tache.dateEcheance!.day}/${tache.dateEcheance!.month}',
                style: TextStyle(
                  fontSize: 10,
                  color: isComplete ? Colors.grey : Colors.grey[400],
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
