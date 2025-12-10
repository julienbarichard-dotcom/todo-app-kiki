import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/color_extensions.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
// Notifications disabled in UI: notification service wrapper is no-op

class TaskDetailScreen extends StatefulWidget {
  final TodoTask tache;

  const TaskDetailScreen({super.key, required this.tache});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const Color mintGreen = Color(0xFF1DB679);

  Color _getUrgenceColor(Urgence urgence) {
    switch (urgence) {
      case Urgence.basse:
        return Colors.green;
      case Urgence.moyenne:
        return Colors.orange;
      case Urgence.haute:
        return Colors.red;
    }
  }

  String _getUrgenceLabel(Urgence urgence) {
    switch (urgence) {
      case Urgence.basse:
        return 'Basse';
      case Urgence.moyenne:
        return 'Moyenne';
      case Urgence.haute:
        return 'Haute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgenceColor = _getUrgenceColor(widget.tache.urgence);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacitySafe(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Détails de la tâche',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Checkbox pour marquer comme complète
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: widget.tache.estComplete,
                      activeColor: mintGreen,
                      onChanged: (value) {
                        context
                            .read<TodoProvider>()
                            .toggleTacheComplete(widget.tache.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge urgence
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: urgenceColor.withOpacitySafe(0.2),
                              border: Border.all(color: urgenceColor, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.priority_high,
                                  color: urgenceColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getUrgenceLabel(widget.tache.urgence),
                                  style: TextStyle(
                                    color: urgenceColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge statut (cliquable)
                          GestureDetector(
                            onTap: () => _showStatutDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: widget.tache.statut.color
                                    .withOpacitySafe(0.2),
                                border: Border.all(
                                    color: widget.tache.statut.color, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    color: widget.tache.statut.color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.tache.statut.label,
                                    style: TextStyle(
                                      color: widget.tache.statut.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    color: widget.tache.statut.color,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Badge label
                          if (widget.tache.label != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: mintGreen.withOpacitySafe(0.2),
                                border: Border.all(color: mintGreen, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.label,
                                    color: mintGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.tache.label!,
                                    style: const TextStyle(
                                      color: mintGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Titre
                    Text(
                      widget.tache.titre,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: widget.tache.estComplete
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                    ),

                    const SizedBox(height: 32),

                    // Description
                    if (widget.tache.description.isNotEmpty) ...[
                      _buildSection(
                        context,
                        icon: Icons.description,
                        title: 'Description',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacitySafe(0.3),
                            ),
                          ),
                          child: Text(
                            widget.tache.description,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.5,
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Date d'échéance and reminders removed from UI

                    // Assigné à
                    _buildSection(
                      context,
                      icon: Icons.people,
                      title: 'Assigné à',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.tache.assignedTo.map((person) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: mintGreen.withOpacitySafe(0.1),
                              border: Border.all(color: mintGreen),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: mintGreen,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  person,
                                  style: const TextStyle(
                                    color: mintGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sous-tâches
                    if (widget.tache.subTasks.isNotEmpty) ...[
                      _buildSection(
                        context,
                        icon: Icons.checklist,
                        title:
                            'Sous-tâches (${widget.tache.subTasks.where((st) => st.estComplete).length}/${widget.tache.subTasks.length})',
                        child: Column(
                          children: [
                            // Barre de progression
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacitySafe(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Progression',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${widget.tache.pourcentageAvancement.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: widget.tache
                                                      .pourcentageAvancement >=
                                                  100
                                              ? Colors.green
                                              : widget.tache
                                                          .pourcentageAvancement >=
                                                      50
                                                  ? Colors.blue
                                                  : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value:
                                          widget.tache.pourcentageAvancement /
                                              100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.tache.pourcentageAvancement >=
                                                100
                                            ? Colors.green
                                            : widget.tache
                                                        .pourcentageAvancement >=
                                                    50
                                                ? Colors.blue
                                                : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Liste des sous-tâches
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacitySafe(0.3),
                                ),
                              ),
                              child: Column(
                                children: widget.tache.subTasks.map((subTask) {
                                  return CheckboxListTile(
                                    value: subTask.estComplete,
                                    onChanged: (value) async {
                                      // Mettre à jour localement pour l'affichage immédiat
                                      setState(() {
                                        subTask.estComplete = value ?? false;
                                      });

                                      // Sauvegarder dans la base
                                      final updatedSubTasks =
                                          List<SubTask>.from(
                                              widget.tache.subTasks);
                                      final updatedTask = widget.tache
                                          .copyWith(subTasks: updatedSubTasks);
                                      await context
                                          .read<TodoProvider>()
                                          .modifierTache(updatedTask);
                                    },
                                    title: Text(
                                      subTask.titre,
                                      style: TextStyle(
                                        decoration: subTask.estComplete
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: subTask.estComplete
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    activeColor: mintGreen,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Date de création
                    _buildSection(
                      context,
                      icon: Icons.access_time,
                      title: 'Créée le',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacitySafe(0.3),
                          ),
                        ),
                        child: Text(
                          _formatDate(widget.tache.dateCreation),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Statut
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: widget.tache.estComplete
                              ? mintGreen.withOpacitySafe(0.2)
                              : Colors.grey.withOpacitySafe(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.tache.estComplete
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: widget.tache.estComplete
                                  ? mintGreen
                                  : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.tache.estComplete
                                  ? 'Terminée'
                                  : 'En cours',
                              style: TextStyle(
                                color: widget.tache.estComplete
                                    ? mintGreen
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: mintGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mintGreen,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    // Afficher l'heure si elle n'est pas à minuit
    if (date.hour != 0 || date.minute != 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$dateStr à $hour:$minute';
    }

    return dateStr;
  }

  void _showStatutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Statut.values.map((statut) {
            return ListTile(
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: statut.color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(statut.label),
              onTap: () async {
                final tacheModifiee = widget.tache.copyWith(statut: statut);
                await context.read<TodoProvider>().modifierTache(tacheModifiee);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
