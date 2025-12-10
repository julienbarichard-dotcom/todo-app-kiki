import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_task_card.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

/// Vue Liste - Affiche les tâches dans une liste détaillée
class ListViewScreen extends StatefulWidget {
  final String utilisateur;

  const ListViewScreen({super.key, required this.utilisateur});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  // États des filtres
  String _triDate = 'proche'; // 'proche', 'lointain'
  String _filtrePeriode =
      'jour'; // 'jour', 'semaine', 'mois', 'continue', 'toutes'
  String? _filtreEtat; // null, 'en_cours', 'termine'
  String? _filtreLabel; // null ou nom du label
  bool? _filtreSousTaches; // null, true (avec), false (sans)
  String? _filtrePriorite; // null, 'haute', 'moyenne', 'basse'

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        var taches = todoProvider.getTachesPourPersonne(widget.utilisateur);
        var tachesFiltrees = _appliquerFiltres(taches);

        // Tri
        if (_triDate == 'proche') {
          tachesFiltrees.sort((a, b) {
            if (a.dateEcheance == null && b.dateEcheance == null) return 0;
            if (a.dateEcheance == null) return 1;
            if (b.dateEcheance == null) return -1;
            return a.dateEcheance!.compareTo(b.dateEcheance!);
          });
        } else {
          tachesFiltrees.sort((a, b) {
            if (a.dateEcheance == null && b.dateEcheance == null) return 0;
            if (a.dateEcheance == null) return -1;
            if (b.dateEcheance == null) return 1;
            return b.dateEcheance!.compareTo(a.dateEcheance!);
          });
        }

        return Column(
          children: [
            _buildFiltresSection(),
            Expanded(
              child: tachesFiltrees.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune tâche',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tachesFiltrees.length,
                      itemBuilder: (context, index) {
                        final tache = tachesFiltrees[index];
                        return TodoTaskCard(
                          tache: tache,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(tache: tache),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          onToggleComplete: () {
                            todoProvider.toggleTacheComplete(tache.id);
                          },
                          onDelete: () {
                            _confirmDelete(context, tache.id, todoProvider);
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTaskScreen(tache: tache),
                              ),
                            ).then((modified) {
                              if (modified == true) {
                                setState(() {});
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltresSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tri
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _triDate,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: 'proche', child: Text('📅 Date proche')),
                  DropdownMenuItem(
                      value: 'lointain', child: Text('📅 Date lointaine')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _triDate = value);
                },
              ),
            ),
            const SizedBox(width: 6),
            // Filtre par période
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _filtrePeriode,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: 'toutes', child: Text('📅 Toutes périodes')),
                  DropdownMenuItem(
                      value: 'jour', child: Text('📅 Aujourd\'hui')),
                  DropdownMenuItem(
                      value: 'semaine', child: Text('📅 Cette semaine')),
                  DropdownMenuItem(value: 'mois', child: Text('📅 Ce mois')),
                  DropdownMenuItem(
                      value: 'continue', child: Text('♾️ Sans date')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filtrePeriode = value);
                },
              ),
            ),
            const SizedBox(width: 6),
            // État
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtreEtat,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('✅ Tous états')),
                  DropdownMenuItem(
                      value: 'en_attente', child: Text('⏸️ A faire')),
                  DropdownMenuItem(
                      value: 'en_cours', child: Text('▶️ En cours')),
                ],
                onChanged: (value) => setState(() => _filtreEtat = value),
              ),
            ),
            const SizedBox(width: 6),
            // Priorité
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtrePriorite,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('🎯 Toutes priorités')),
                  DropdownMenuItem(value: 'haute', child: Text('🔴 Haute')),
                  DropdownMenuItem(value: 'moyenne', child: Text('🟠 Moyenne')),
                  DropdownMenuItem(value: 'basse', child: Text('🟢 Basse')),
                ],
                onChanged: (value) => setState(() => _filtrePriorite = value),
              ),
            ),
            const SizedBox(width: 6),
            // Sous-tâches
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<bool?>(
                value: _filtreSousTaches,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('📋 Toutes tâches')),
                  DropdownMenuItem(
                      value: true, child: Text('✅ Avec sous-tâches')),
                  DropdownMenuItem(
                      value: false, child: Text('❌ Sans sous-tâche')),
                ],
                onChanged: (value) => setState(() => _filtreSousTaches = value),
              ),
            ),
            const SizedBox(width: 6),
            // Catégorie
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtreLabel,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 10, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('📌 Toutes')),
                  DropdownMenuItem(value: 'Perso', child: Text('👤 Perso')),
                  DropdownMenuItem(value: 'B2B', child: Text('💼 B2B')),
                  DropdownMenuItem(value: 'Cuisine', child: Text('🍳 Cuisine')),
                  DropdownMenuItem(
                      value: 'Administratif', child: Text('Administratif')),
                  DropdownMenuItem(value: 'Loisir', child: Text('Loisir')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _filtreLabel = value),
              ),
            ),
            // Bouton effacer
            if (_filtreEtat != null ||
                _filtreLabel != null ||
                _filtreSousTaches != null ||
                _filtrePriorite != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Effacer filtres',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  setState(() {
                    _filtreEtat = null;
                    _filtreLabel = null;
                    _filtreSousTaches = null;
                    _filtrePriorite = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TodoTask> _appliquerFiltres(List<TodoTask> taches) {
    return taches.where((tache) {
      // Filtre par période
      if (_filtrePeriode != 'toutes') {
        final now = DateTime.now();
        final debut = DateTime(now.year, now.month, now.day);
        final fin = DateTime(now.year, now.month, now.day, 23, 59, 59);

        if (_filtrePeriode == 'jour') {
          if (tache.dateEcheance != null && !tache.dateEcheance!.isAfter(fin)) {
            if (!tache.dateEcheance!.isBefore(debut)) {
            } else {
              return false;
            }
          } else if (tache.dateEcheance == null) {
            return false;
          }
        } else if (_filtrePeriode == 'semaine') {
          if (tache.dateEcheance == null) return false;
          final semaineFin = debut.add(const Duration(days: 7));
          if (tache.dateEcheance!.isBefore(debut) ||
              tache.dateEcheance!.isAfter(semaineFin)) {
            return false;
          }
        } else if (_filtrePeriode == 'mois') {
          if (tache.dateEcheance == null) return false;
          if (tache.dateEcheance!.month != now.month ||
              tache.dateEcheance!.year != now.year) {
            return false;
          }
        } else if (_filtrePeriode == 'continue') {
          if (tache.dateEcheance != null) return false;
        }
      }

      // Filtre par état
      if (_filtreEtat != null) {
        if (_filtreEtat == 'en_attente' && tache.statut != Statut.enAttente) {
          return false;
        }
        if (_filtreEtat == 'en_cours' && tache.statut != Statut.enCours) {
          return false;
        }
      }

      // Filtre par label
      if (_filtreLabel != null && tache.label != _filtreLabel) {
        return false;
      }

      // Filtre par sous-tâches
      if (_filtreSousTaches != null) {
        final hasSubTasks = tache.subTasks.isNotEmpty;
        if (_filtreSousTaches! && !hasSubTasks) return false;
        if (_filtreSousTaches == false && hasSubTasks) return false;
      }

      // Filtre par priorité
      if (_filtrePriorite != null) {
        if (tache.urgence.name != _filtrePriorite) {
          return false;
        }
      }

      return true;
    }).toList();
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
