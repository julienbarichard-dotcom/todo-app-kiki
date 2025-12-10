import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/view_preference.dart';
import '../providers/user_provider.dart';

/// Widget sélecteur de vue avec affichage des options disponibles
class ViewSelector extends StatelessWidget {
  const ViewSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentView = userProvider.viewPreference;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<ViewPreference>(
            initialValue: currentView,
            onSelected: (view) {
              userProvider.setViewPreference(view);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vue : ${view.label}'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            itemBuilder: (context) => [
              for (final view in ViewPreference.values)
                PopupMenuItem<ViewPreference>(
                  value: view,
                  child: _buildViewOption(view, view == currentView),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentView.emoji} Vue',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construire une option de vue avec icône, titre et description
  Widget _buildViewOption(ViewPreference view, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            view.emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                view.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                view.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green,
            ),
        ],
      ),
    );
  }
}
