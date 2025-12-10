import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import 'task_detail_screen.dart';

/// Vue Kanban simple - Affiche les tâches réutilisables depuis KanbanScreen
class KanbanViewWrapper extends StatefulWidget {
  final String utilisateur;

  const KanbanViewWrapper({super.key, required this.utilisateur});

  @override
  State<KanbanViewWrapper> createState() => _KanbanViewWrapperState();
}

class _KanbanViewWrapperState extends State<KanbanViewWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final taches = todoProvider.getTachesPourPersonne(widget.utilisateur);

        // Grouper les tâches par statut
        final tachesAValider = taches
            .where((t) =>
                t.isMultiValidation &&
                t.statut == Statut.aValider &&
                !t.estComplete &&
                !t.isRejected)
            .toList();
        final tachesEnRetard =
            taches.where((t) => t.isReported && !t.estComplete).toList();
        final tachesAFaire = taches
            .where((t) =>
                t.statut == Statut.enAttente && !t.estComplete && !t.isReported)
            .toList();
        final tachesEnCours = taches
            .where((t) =>
                t.statut == Statut.enCours && !t.estComplete && !t.isReported)
            .toList();
        final tachesTerminees = taches
            .where((t) => t.statut == Statut.termine || t.estComplete)
            .toList();

        final colonnes = [
          (
            titre: 'A valider',
            taches: tachesAValider,
            color: const Color(0xFF9C27B0),
          ),
          (
            titre: 'En retard',
            taches: tachesEnRetard,
            color: Colors.orange,
          ),
          (
            titre: 'A faire',
            taches: tachesAFaire,
            color: Colors.grey,
          ),
          (
            titre: 'En cours',
            taches: tachesEnCours,
            color: Colors.blue,
          ),
          (
            titre: 'Terminé',
            taches: tachesTerminees,
            color: Colors.green,
          ),
        ];

        return PageView.builder(
          controller: PageController(viewportFraction: 0.96),
          itemCount: colonnes.length,
          itemBuilder: (context, index) {
            final col = colonnes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildColumn(
                context,
                col.titre,
                col.taches,
                col.color,
                todoProvider,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String titre,
    List<TodoTask> taches,
    Color color,
    TodoProvider todoProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // En-tête de colonne
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${taches.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Liste des tâches
            Expanded(
              child: taches.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune tâche',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: taches.length,
                      itemBuilder: (context, index) {
                        final tache = taches[index];
                        return _buildKanbanCard(
                          context,
                          tache,
                          todoProvider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanCard(
    BuildContext context,
    TodoTask tache,
    TodoProvider todoProvider,
  ) {
    final isRejected = tache.isRejected;
    final backgroundColor =
        isRejected ? Colors.red.shade700 : const Color(0xFF0A0A0A);
    const textColor = Colors.white;
    const secondaryColor = Colors.white70;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(tache: tache),
            ),
          ).then((_) => setState(() {}));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isRejected ? Colors.red : tache.urgence.color,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + Icônes
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tache.titre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tache.isMultiValidation)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('👥',
                            style: TextStyle(fontSize: 16, color: textColor)),
                      ),
                    if (isRejected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('❌',
                            style: TextStyle(fontSize: 14, color: textColor)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tache.description.isNotEmpty)
                  Text(
                    tache.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                if (tache.dateEcheance != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(tache.dateEcheance!),
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }
}
