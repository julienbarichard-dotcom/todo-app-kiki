import 'package:flutter/material.dart';

/// Petit widget pour ajouter plusieurs rappels (date+heure + méthode)
class ReminderPicker extends StatefulWidget {
  final List<Map<String, dynamic>>? initialReminders;
  final ValueChanged<List<Map<String, dynamic>>>? onChanged;

  const ReminderPicker({super.key, this.initialReminders, this.onChanged});

  @override
  State<ReminderPicker> createState() => _ReminderPickerState();
}

class _ReminderPickerState extends State<ReminderPicker> {
  late List<Map<String, dynamic>> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = widget.initialReminders != null
        ? List<Map<String, dynamic>>.from(widget.initialReminders!)
        : [];
  }

  Future<void> _addReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (timeOfDay == null) return;
    if (!mounted) return;

    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Méthode de rappel'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'email'),
            child: const Text('Email'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'popup'),
            child: const Text('Notification locale'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'sms'),
            child: const Text('SMS'),
          ),
        ],
      ),
    );

    if (method == null) return;
    if (!mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    setState(() {
      _reminders.add({'when': dt.toIso8601String(), 'method': method});
    });
    widget.onChanged?.call(_reminders);
  }

  void _removeAt(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    widget.onChanged?.call(_reminders);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
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
}
