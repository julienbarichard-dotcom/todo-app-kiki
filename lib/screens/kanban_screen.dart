import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed unused imports (cleaned by Copilot-agent)
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
  // Removed unused color constant

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
          final tasks = todoProvider.getTasksForPerson(utilisateurActuel);

          // Grouper les tâches par statut
          final tasksToValidate = tasks
              .where((t) =>
                  t.isMultiValidation &&
                  t.statut == Statut.aValider &&
                  !t.estComplete &&
                  !t.isRejected)
              .toList();
          final overdueTasks =
              tasks.where((t) => t.isReported && !t.estComplete).toList();
          final tasksToStart = tasks
              .where((t) =>
                  t.statut == Statut.enAttente &&
                  !t.estComplete &&
                  !t.isReported)
              .toList();
          final tasksInProgress = tasks
              .where((t) =>
                  t.statut == Statut.enCours && !t.estComplete && !t.isReported)
              .toList();
          final completedTasks = tasks
              .where((t) => t.statut == Statut.termine || t.estComplete)
              .toList();

          final columns = [
            (
              titre: 'A valider',
              tasks: tasksToValidate,
              color: const Color(0xFF9C27B0),
            ),
            (
              titre: 'En retard',
              tasks: overdueTasks,
              color: Colors.orange,
            ),
            (
              titre: 'A faire',
              tasks: tasksToStart,
              color: Colors.grey,
            ),
            (
              titre: 'En cours',
              tasks: tasksInProgress,
              color: Colors.blue,
            ),
            (
              titre: 'Terminé',
              tasks: completedTasks,
              color: Colors.green,
            ),
          ];

          return PageView.builder(
            controller: PageController(viewportFraction: 0.96),
            itemCount: columns.length,
            itemBuilder: (context, index) {
              final col = columns[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildColumn(
                  context,
                  col.titre,
                  col.tasks,
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
    List<TodoTask> tasks,
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
                    // withOpacity deprecated in analyzer; convert to withAlpha
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
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune tâche',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildKanbanCard(
                          context,
                          task,
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
    TodoTask task,
    TodoProvider todoProvider,
  ) {
    final isRejected = task.isRejected;
    // Cartes : fond noir foncé par défaut, rouge si rejetée
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
                color: isRejected ? Colors.red : task.urgence.color,
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
                        task.titre,
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
                    task.description,
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

  void _validateTask(TodoTask task, TodoProvider todoProvider) {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser?.prenom ?? 'Unknown';

    final updatedValidations = {...tache.validations};
    updatedValidations[currentUser] = true;

    final allValidated = updatedValidations.entries
        .where((e) => task.assignedTo.contains(e.key))
        .every((e) => e.value == true);

    // Si rejet précédent, enlever le rejet quand quelqu'un valide
    final tacheModifiee = task.copyWith(
      validations: updatedValidations,
      statut: allValidated ? Statut.termine : Statut.aValider,
      estComplete: allValidated,
      isRejected: false, // Enlever le rejet si quelqu'un valide
    );

    todoProvider.updateTask(tacheModifiee);
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

  void _rejectTask(TodoTask task, TodoProvider todoProvider) {
    final tacheModifiee = task.copyWith(
      isRejected: true,
      statut: Statut.enCours,
    );

    todoProvider.updateTask(tacheModifiee);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tâche rejetée. Elle passe en rouge.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCommentsDialog(TodoTask task, TodoProvider todoProvider) {
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
                    itemCount: task.comments.length,
                    itemBuilder: (context, index) {
                      final comment = task.comments[index];
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
                            task.copyWith(comments: updatedComments);

                        todoProvider.updateTask(tacheModifiee);
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
