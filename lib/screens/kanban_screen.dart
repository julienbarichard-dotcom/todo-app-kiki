import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import 'task_detail_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  static const Color mintGreen = Color(0xFF1DB679);

  String get utilisateurActuel {
    final userProvider = context.read<UserProvider>();
    return userProvider.currentUser?.prenom ?? 'Unknown';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vue Kanban'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final taches = todoProvider.getTachesPourPersonne(utilisateurActuel);

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
                  t.statut == Statut.enAttente &&
                  !t.estComplete &&
                  !t.isReported)
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
      ),
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
                    color: color.withOpacity(0.2),
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
    final backgroundColor = isRejected ? Colors.red[700] : Colors.grey[900];
    final textColor = Colors.white;

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
                        style: TextStyle(
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
                            style: TextStyle(
                                fontSize: 16,
                                color:
                                    isRejected ? Colors.white : Colors.blue)),
                      ),
                    if (isRejected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('❌', style: TextStyle(fontSize: 14)),
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
                      color: isRejected ? Colors.white70 : Colors.grey[300],
                    ),
                  ),
                if (tache.dateEcheance != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12,
                          color:
                              isRejected ? Colors.white70 : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(tache.dateEcheance!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isRejected ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                if (tache.isMultiValidation) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _validateTask(tache, todoProvider),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Valider',
                            style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rejectTask(tache, todoProvider),
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text('Rejeter',
                            style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showCommentsDialog(tache, todoProvider),
                        icon: const Icon(Icons.comment, size: 14),
                        label: const Text('💬', style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
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

  void _validateTask(TodoTask tache, TodoProvider todoProvider) {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser?.prenom ?? 'Unknown';

    final updatedValidations = {...tache.validations};
    updatedValidations[currentUser] = true;

    final allValidated = updatedValidations.entries
        .where((e) => tache.assignedTo.contains(e.key))
        .every((e) => e.value == true);

    // Si rejet précédent, enlever le rejet quand quelqu'un valide
    final tacheModifiee = tache.copyWith(
      validations: updatedValidations,
      statut: allValidated ? Statut.termine : Statut.aValider,
      estComplete: allValidated,
      isRejected: false, // Enlever le rejet si quelqu'un valide
    );

    todoProvider.modifierTache(tacheModifiee);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allValidated
            ? 'Tâche validée par tous ! ✅'
            : 'Vous avez validé. En attente des autres...'),
        backgroundColor: allValidated ? Colors.green : Colors.blue,
      ),
    );
  }

  void _rejectTask(TodoTask tache, TodoProvider todoProvider) {
    final tacheModifiee = tache.copyWith(
      isRejected: true,
      statut: Statut.enCours,
    );

    todoProvider.modifierTache(tacheModifiee);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tâche rejetée. Elle passe en rouge.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCommentsDialog(TodoTask tache, TodoProvider todoProvider) {
    final commentController = TextEditingController();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser?.prenom ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Commentaires',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (tache.comments.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tache.comments.length,
                    itemBuilder: (context, index) {
                      final comment = tache.comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${comment.author} - ${_formatCommentDate(comment.timestamp)}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(comment.text,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(8),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        final newComment = TaskComment(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          author: currentUser,
                          text: commentController.text,
                          timestamp: DateTime.now(),
                        );

                        final updatedComments = [...tache.comments, newComment];
                        final tacheModifiee =
                            tache.copyWith(comments: updatedComments);

                        todoProvider.modifierTache(tacheModifiee);
                        Navigator.pop(context);
                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Commentaire ajouté !'),
                              backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
