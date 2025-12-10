import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
// ReminderPicker removed: notifications are controlled via Switch + minutes dropdown

/// Écran pour créer ou modifier une tâche
class AddTaskScreen extends StatefulWidget {
  final String utilisateur;
  final TodoTask? tache; // Tâche existante pour la modification

  const AddTaskScreen({super.key, required this.utilisateur, this.tache});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Valeurs sélectionnées
  Urgence _urgenceSelectionnee = Urgence.moyenne;
  DateTime? _dateSelectionnee;
  final List<String> _assignedToPrenoms = [];
  final List<SubTask> _subTasks = [];
  final _subTaskController = TextEditingController();
  String? _labelSelectionne;
  Statut _statutSelectionne = Statut.enAttente;

  // Paramètres de notifications
  // Paramètres de notifications supprimés de l'UI (rappels désactivés)

  // Rappels personnalisés (liste JSON)
  // Reminders list removed to avoid duplication with notificationEnabled

  // Multi-validation collaborative
  bool _isMultiValidation = false;

  bool get _isEditing => widget.tache != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Pré-remplir les champs si on est en mode édition
      final task = widget.tache!;
      _titreController.text = task.titre;
      _descriptionController.text = task.description;
      _urgenceSelectionnee = task.urgence;
      _dateSelectionnee = task.dateEcheance;
      _assignedToPrenoms.addAll(task.assignedTo);
      // notification fields intentionally not loaded into the edit form
      _subTasks.addAll(task.subTasks);
      _labelSelectionne = task.label;
      _statutSelectionne = task.statut;
      _isMultiValidation = task.isMultiValidation;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mintGreen = Color(0xFF1DB679);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la tâche' : 'Nouvelle tâche'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            TextFormField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: 'Titre de la tâche',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Urgence
            _buildUrgenceSection(),
            const SizedBox(height: 16),

            // Label/Catégorie
            _buildLabelSection(mintGreen),
            const SizedBox(height: 16),

            // Statut
            _buildStatutSection(),
            const SizedBox(height: 16),

            // Sélection de prénoms assignés
            _buildAssignedToSection(context, mintGreen),
            const SizedBox(height: 16),

            // Multi-validation collaborative
            _buildMultiValidationSection(mintGreen),
            const SizedBox(height: 16),

            // Date d'échéance
            _buildDatePickerSection(context),
            const SizedBox(height: 16),

            // Paramètres de notifications (activation + délai)
            _buildNotificationSection(mintGreen),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            // Sous-tâches
            _buildSubTasksSection(mintGreen),
            const SizedBox(height: 32),

            // Bouton créer/modifier
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: mintGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Enregistrer les modifications' : 'Créer la tâche',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urgence',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Urgence.values.map((urgence) {
                final isSelected = _urgenceSelectionnee == urgence;
                return GestureDetector(
                  onTap: () => setState(() => _urgenceSelectionnee = urgence),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? urgence.color.withAlpha(77) : null,
                      border: Border.all(
                          color: urgence.color, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(urgence.label,
                        style: TextStyle(
                            color: urgence.color, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelSection(Color mintGreen) {
    const labels = [
      'Perso',
      'B2B',
      'Cuisine',
      'Administratif',
      'Loisir',
      'Autre'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catégorie',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map((label) {
                final isSelected = _labelSelectionne == label;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _labelSelectionne = selected ? label : null;
                    });
                  },
                  selectedColor: mintGreen.withAlpha(77),
                  side: BorderSide(
                      color: isSelected ? mintGreen : Colors.grey[600]!,
                      width: isSelected ? 2 : 1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Statut>(
              initialValue: _statutSelectionne,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: Statut.values
                  .where(
                      (statut) => statut != Statut.termine) // Exclure Terminé
                  .map((statut) {
                return DropdownMenuItem(
                  value: statut,
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
                      Text(statut.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statutSelectionne = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedToSection(BuildContext context, Color mintGreen) {
    final allUsers = context.read<UserProvider>().users;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assigner à',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allUsers.map((user) {
                final isSelected = _assignedToPrenoms.contains(user.prenom);
                return FilterChip(
                  label: Text(user.prenom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _assignedToPrenoms.add(user.prenom);
                      } else {
                        _assignedToPrenoms.remove(user.prenom);
                      }
                    });
                  },
                  selectedColor: mintGreen.withAlpha(77),
                  side: BorderSide(
                      color: isSelected ? mintGreen : Colors.grey[600]!,
                      width: isSelected ? 2 : 1),
                );
              }).toList(),
            ),
            if (_assignedToPrenoms.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Veuillez sélectionner au moins une personne',
                    style: TextStyle(color: Colors.red[400], fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date d\'échéance (optionnelle)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dateSelectionnee != null
                        ? _formatDateTime(_dateSelectionnee!)
                        : 'Pas de date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dateSelectionnee != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Choisir'),
                ),
                if (_dateSelectionnee != null)
                  IconButton(
                    onPressed: () => setState(() => _dateSelectionnee = null),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    // Dialog pour saisir l'heure au lieu du time picker avec aiguilles
    int selectedHour = (_dateSelectionnee?.hour) ?? DateTime.now().hour;
    int selectedMinute = (_dateSelectionnee?.minute) ?? 0;

    final time = await showDialog<TimeOfDay>(
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
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Sliders pour heure et minutes
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
              onPressed: () => Navigator.pop(context,
                  TimeOfDay(hour: selectedHour, minute: selectedMinute)),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (time == null) return;
    if (!mounted) return;

    setState(() {
      _dateSelectionnee =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _buildNotificationSection(Color mintGreen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Rappels', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Les rappels ont été désactivés dans cette application.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTasksSection(Color mintGreen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sous-tâches (optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Liste des sous-tâches
            ..._subTasks.map((subTask) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: subTask.estComplete,
                        onChanged: (value) {
                          setState(() {
                            subTask.estComplete = value ?? false;
                          });
                        },
                        activeColor: mintGreen,
                      ),
                      Expanded(
                        child: Text(
                          subTask.titre,
                          style: TextStyle(
                            decoration: subTask.estComplete
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _subTasks.remove(subTask);
                          });
                        },
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            // Ajouter une sous-tâche
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(
                      hintText: 'Nouvelle sous-tâche...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: mintGreen),
                  onPressed: () {
                    if (_subTaskController.text.trim().isNotEmpty) {
                      setState(() {
                        _subTasks.add(SubTask(
                          id: const Uuid().v4(),
                          titre: _subTaskController.text.trim(),
                        ));
                        _subTaskController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiValidationSection(Color mintGreen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Multi-validation collaborative',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Checkbox(
                  value: _isMultiValidation,
                  activeColor: mintGreen,
                  onChanged: (value) =>
                      setState(() => _isMultiValidation = value ?? false),
                ),
              ],
            ),
            if (_isMultiValidation) ...[
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
              if (_assignedToPrenoms.length < 2)
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

  void _saveTask() async {
    if (!_formKey.currentState!.validate() || _assignedToPrenoms.isEmpty) {
      if (_assignedToPrenoms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Veuillez assigner la tâche à au moins une personne'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    final todoProvider = context.read<TodoProvider>();

    if (_isEditing) {
      // Modifier la tâche existante
      final updatedTask = widget.tache!.copyWith(
        titre: _titreController.text,
        description: _descriptionController.text,
        urgence: _urgenceSelectionnee,
        dateEcheance: _dateSelectionnee,
        assignedTo: _assignedToPrenoms,
        subTasks: _subTasks,
        label: _labelSelectionne,
        statut: _statutSelectionne,
        // reminders intentionally kept null: notifications are driven by
        // `notificationEnabled` and `notificationMinutesBefore`.
        reminders: null,
      );
      await todoProvider.modifierTache(updatedTask);
    } else {
      // Créer une nouvelle tâche

      final newTask = TodoTask(
        id: const Uuid().v4(),
        titre: _titreController.text,
        description: _descriptionController.text,
        urgence: _urgenceSelectionnee,
        dateEcheance: _dateSelectionnee,
        assignedTo: _assignedToPrenoms,
        dateCreation: DateTime.now(),
        subTasks: _subTasks,
        label: _labelSelectionne,
        statut: _statutSelectionne,
        reminders: null,
        isMultiValidation: _isMultiValidation,
        validations: _isMultiValidation
            ? {for (var p in _assignedToPrenoms) p: false}
            : {},
        comments: [],
        isRejected: false,
      );
      await todoProvider.ajouterTache(newTask);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_isEditing ? 'Tâche modifiée !' : 'Tâche créée !')),
    );
    Navigator.pop(context);
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
