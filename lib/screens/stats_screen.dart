import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProv = context.watch<TodoProvider>();
    final all = todoProv.tasks; // supposed getter

    final total = all.length;
    final haute = all.where((t) => t.urgence == 'haute').length;
    final moyenne = all.where((t) => t.urgence == 'moyenne').length;
    final basse = all.where((t) => t.urgence == 'basse').length;

    Widget bar(int count, Color color) {
      final double frac = total == 0 ? 0.0 : count / total;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, color: color),
              const SizedBox(width: 8),
              Text('$count'),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                    value: frac,
                    color: color,
                    backgroundColor: color.withOpacitySafe(0.2)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total tâches: $total',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            bar(haute, Colors.red),
            bar(moyenne, Colors.orange),
            bar(basse, Colors.green),
            const SizedBox(height: 24),
            const Text('Distribution par statut / autres vues à venir'),
          ],
        ),
      ),
    );
  }
}
