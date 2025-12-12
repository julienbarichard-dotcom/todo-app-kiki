import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app_kiki/models/todo_task.dart';
import 'package:todo_app_kiki/widgets/todo_task_card.dart';

void main() {
  // Groupe de tests pour le widget TodoTaskCard
  group('TodoTaskCard', () {
    // Crée une tâche de test
    final testTask = TodoTask(
      id: '1',
      titre: 'Faire les courses',
      description: 'Acheter du lait et du pain',
      urgence: Urgence.moyenne,
      dateCreation: DateTime.now(),
    );

    testWidgets('devrait afficher le titre et la description de la tâche',
        (WidgetTester tester) async {
      // Construit le widget dans un environnement de test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoTaskCard(
              tache: testTask,
              onToggleComplete: () {},
              onDelete: () {},
              onEdit: () {},
            ),
          ),
        ),
      );

      // Vérifie que le titre et la description sont bien présents
      expect(find.text('Faire les courses'), findsOneWidget);
      expect(find.text('Acheter du lait et du pain'), findsOneWidget);
    });
  });
}
