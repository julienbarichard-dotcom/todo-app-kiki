import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../utils/color_extensions.dart';

class EditTaskScreen extends StatefulWidget {
  final TodoTask tache;

  const EditTaskScreen({super.key, required this.tache});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late Urgence _urgenceSelectionnee;
  DateTime? _dateEcheance;
  late List<String> _personnesAssignees;
  final List<SubTask> _subTasks = [];
  final _subTaskController = TextEditingController();
  String? _labelSelectionne;
  late Statut _statutSelectionne;
  late bool _isMultiValidation;

  static const Color mintGreen = Color(0xFF1DB679);

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.tache.titre);
    _descriptionController = TextEditingController(
      text: widget.tache.description,
    );
    _urgenceSelectionnee = widget.tache.urgence;
    _dateEcheance = widget.tache.dateEcheance;
    _personnesAssignees = List.from(widget.tache.assignedTo);
    _subTasks.addAll(widget.tache.subTasks);
    _labelSelectionne = widget.tache.label;
    _statutSelectionne = widget.tache.statut;
    _isMultiValidation = widget.tache.isMultiValidation;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateEcheance ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: mintGreen,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Conserver l'heure existante si elle existe, sinon minuit
        if (_dateEcheance != null) {
          _dateEcheance = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _dateEcheance!.hour,
            _dateEcheance!.minute,
          );
        } else {
          _dateEcheance = DateTime(picked.year, picked.month, picked.day, 0, 0);
        }
      });
    }
  }

  Future<void> _selectTime() async {
    if (_dateEcheance == null) return;

    int selectedHour = _dateEcheance!.hour;
    int selectedMinute = _dateEcheance!.minute;

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
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
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

    if (time != null) {
      setState(() {
        _dateEcheance = DateTime(
          _dateEcheance!.year,
          _dateEcheance!.month,
          _dateEcheance!.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _togglePersonne(String prenom) {
    setState(() {
      if (_personnesAssignees.contains(prenom)) {
        _personnesAssignees.remove(prenom);
      } else {
        _personnesAssignees.add(prenom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final users = userProvider.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la tâche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _sauvegarderTache,
            tooltip: 'Enregistrer',
          ),
        ],
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
                labelText: 'Titre *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            // Urgence
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.priority_high, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Urgence',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: Urgence.values.map((urgence) {
                        final isSelected = _urgenceSelectionnee == urgence;
                        return ChoiceChip(
                          label: Text(urgence.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _urgenceSelectionnee = urgence;
                            });
                          },
                          selectedColor: urgence.color.withOpacitySafe(0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? urgence.color : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? urgence.color : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Label/Catégorie
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.label, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Catégorie',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Perso',
                        'B2B',
                        'Cuisine',
                        'Administratif',
                        'Loisir',
                        'Autre',
                      ].map((label) {
                        final isSelected = _labelSelectionne == label;
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _labelSelectionne = selected ? label : null;
                            });
                          },
                          selectedColor: mintGreen.withOpacitySafe(0.3),
                          checkmarkColor: mintGreen,
                          side: BorderSide(
                            color: isSelected ? mintGreen : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task_alt, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Statut',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Statut>(
                      initialValue: _statutSelectionne,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: Statut.values
                          .where(
                        (statut) => statut != Statut.termine,
                      ) // Exclure Terminé
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
            ),

            const SizedBox(height: 16),

            // Date et heure d'échéance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Date et heure d\'échéance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_dateEcheance != null)
                      Text(
                        _formatDate(_dateEcheance!),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else
                      Text(
                        'Aucune date',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.event),
                          label: const Text('Choisir date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mintGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_dateEcheance != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.access_time),
                            label: const Text('Choisir heure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mintGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _dateEcheance = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sous-tâches
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checklist, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Sous-tâches',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Liste des sous-tâches
                    if (_subTasks.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subTasks.length,
                        itemBuilder: (context, index) {
                          final subTask = _subTasks[index];
                          return CheckboxListTile(
                            value: subTask.estComplete,
                            onChanged: (value) {
                              setState(() {
                                subTask.estComplete = value ?? false;
                              });
                            },
                            title: Text(
                              subTask.titre,
                              style: TextStyle(
                                decoration: subTask.estComplete
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            activeColor: mintGreen,
                            contentPadding: EdgeInsets.zero,
                            secondary: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _subTasks.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    // Champ d'ajout
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subTaskController,
                            decoration: InputDecoration(
                              hintText: 'Ajouter une sous-tâche',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  _subTasks.add(
                                    SubTask(
                                      id: DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                      titre: value,
                                      estComplete: false,
                                    ),
                                  );
                                  _subTaskController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: mintGreen),
                          onPressed: () {
                            if (_subTaskController.text.isNotEmpty) {
                              setState(() {
                                _subTasks.add(
                                  SubTask(
                                    id: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    titre: _subTaskController.text,
                                    estComplete: false,
                                  ),
                                );
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
            ),

            const SizedBox(height: 16),

            // Multi-validation
            _buildMultiValidationSection(mintGreen),

            const SizedBox(height: 16),

            // Assignation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: mintGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Assigner à',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: users.map((user) {
                        final isSelected = _personnesAssignees.contains(
                          user.prenom,
                        );
                        return FilterChip(
                          label: Text(user.prenom),
                          selected: isSelected,
                          onSelected: (_) => _togglePersonne(user.prenom),
                          selectedColor: mintGreen.withOpacitySafe(0.3),
                          checkmarkColor: mintGreen,
                          side: BorderSide(
                            color: isSelected ? mintGreen : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_personnesAssignees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Sélectionnez au moins une personne',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
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

  void _sauvegarderTache() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_personnesAssignees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez assigner la tâche à au moins une personne'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tacheModifiee = widget.tache.copyWith(
      titre: _titreController.text,
      description: _descriptionController.text,
      urgence: _urgenceSelectionnee,
      dateEcheance: _dateEcheance,
      assignedTo: _personnesAssignees,
      subTasks: _subTasks,
      label: _labelSelectionne,
      // Ne pas forcer à "A valider" quand on coche multi-validation.
      // On garde le statut choisi ; le passage en A valider se fera quand
      // un participant clique sur "Valider" dans le Kanban.
      statut: _statutSelectionne,
      isMultiValidation: _isMultiValidation,
      validations: _isMultiValidation
          ? {
              ...widget.tache.validations,
              for (var p in _personnesAssignees)
                if (!widget.tache.validations.containsKey(p)) p: false,
            }
          : widget.tache.validations,
      comments: widget.tache.comments,
      isRejected: widget.tache.isRejected,
    );

    debugPrint('🔍 Date avant modification: ${widget.tache.dateEcheance}');
    debugPrint('🔍 Date après modification: ${tacheModifiee.dateEcheance}');

    try {
      await context.read<TodoProvider>().updateTask(tacheModifiee);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tâche modifiée avec succès'),
            backgroundColor: mintGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      'décembre',
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';
    if (date.hour != 0 || date.minute != 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$dateStr à $hour:$minute';
    }
    return dateStr;
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
                const Text(
                  'Multi-validation collaborative',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
              if (_personnesAssignees.length < 2)
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
