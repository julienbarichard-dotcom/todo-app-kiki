import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo_task.dart';
import '../providers/todo_provider.dart';
import '../utils/color_extensions.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color mintGreen = Color(0xFF1DB679);

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TodoTask> _getTasksForDay(DateTime day, List<TodoTask> allTasks) {
    return allTasks.where((task) {
      if (task.estComplete) return false;
      if (task.dateEcheance == null) return false;

      final taskDate = task.dateEcheance!;
      return taskDate.year == day.year &&
          taskDate.month == day.month &&
          taskDate.day == day.day;
    }).toList();
  }

  bool _hasTasksOnDay(DateTime day, List<TodoTask> allTasks) {
    return _getTasksForDay(day, allTasks).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final todoProv = context.watch<TodoProvider>();
    final allTasks = todoProv.tachesTriees;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        title: const Text(' Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => todoProv.loadTasks(),
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<CalendarFormat>(
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Vue mensuelle'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('Vue 2 semaines'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Vue hebdomadaire'),
              ),
            ],
            icon: const Icon(Icons.view_module),
            tooltip: 'Changer la vue',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _hasTasksOnDay(day, allTasks) ? [true] : [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: mintGreen.withOpacitySafe(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: mintGreen,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: mintGreen,
                shape: BoxShape.circle,
              ),
              markerSize: 7.0,
              markersMaxCount: 1,
            ),
            headerStyle: HeaderStyle(
              formatButtonTextStyle: const TextStyle(color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                color: mintGreen,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildTasksList(allTasks),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<TodoTask> allTasks) {
    if (_selectedDay == null) {
      return const Center(child: Text('Sélectionnez un jour'));
    }

    final dayTasks = _getTasksForDay(_selectedDay!, allTasks);

    if (dayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune tâche ce jour',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayTasks.length,
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        final todoProv = context.read<TodoProvider>();
        return _buildTaskCard(task, todoProv);
      },
    );
  }

  Widget _buildTaskCard(TodoTask task, TodoProvider todoProv) {
    final dateFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: task.urgence.color,
              width: 5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.estComplete,
                    onChanged: (_) {
                      todoProv.toggleTacheComplete(task.id);
                    },
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.titre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: task.estComplete
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.isReported)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  '',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: task.urgence.color.withOpacitySafe(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.urgence.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.urgence.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: task.statut.color.withOpacitySafe(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.statut.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.statut.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.dateEcheance != null &&
                      (task.dateEcheance!.hour != 0 ||
                          task.dateEcheance!.minute != 0))
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(task.dateEcheance!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  if (task.assignedTo.isNotEmpty) ...[
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedTo.join(', '),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
