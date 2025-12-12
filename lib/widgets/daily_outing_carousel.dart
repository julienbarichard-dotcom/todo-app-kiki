import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';
import '../models/outing.dart';
import 'package:intl/intl.dart';

class DailyOutingCarousel extends StatefulWidget {
  final List<Outing> outings;
  final void Function(Outing)? onView;
  const DailyOutingCarousel({super.key, required this.outings, this.onView});

  @override
  State<DailyOutingCarousel> createState() => _DailyOutingCarouselState();
}

class _DailyOutingCarouselState extends State<DailyOutingCarousel> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    try {
      final dateFormat = DateFormat('EEEE d MMMM', 'fr_FR');
      return dateFormat.format(date);
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    try {
      final timeFormat = DateFormat('HH:mm');
      return timeFormat.format(date);
    } catch (e) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final outings = widget.outings;

    // Si pas d'événements
    if (outings.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🎉 Sorties du jour',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1DB679),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pas d\'événements aujourd\'hui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Revenez demain pour découvrir\nde nouvelles sorties !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '🎉 Sorties du jour',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1DB679),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 420,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: outings.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, index) {
                    final outing = outings[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outing.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (outing.imageUrl != null &&
                                outing.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  outing.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.white38, size: 48),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Color(0xFF1DB679)),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(outing.date),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time,
                                    size: 16, color: Color(0xFF1DB679)),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(outing.date),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Color(0xFF1DB679)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    outing.location,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: outing.categories
                                  .map((cat) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1DB679)
                                              .withOpacitySafe(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFF1DB679)
                                                  .withOpacitySafe(0.5)),
                                        ),
                                        child: Text(cat,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF1DB679))),
                                      ))
                                  .toList(),
                            ),
                            if (outing.description != null &&
                                outing.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                outing.description!,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        widget.onView?.call(outing),
                                    icon:
                                        const Icon(Icons.open_in_new, size: 18),
                                    label: const Text('Voir l\'événement'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1DB679),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (outings.length > 1)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          size: 36, color: Colors.white70),
                      onPressed: () {
                        final prev = (_current - 1) < 0
                            ? outings.length - 1
                            : _current - 1;
                        _controller.animateToPage(prev,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      },
                    ),
                  ),
                if (outings.length > 1)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          size: 36, color: Colors.white70),
                      onPressed: () {
                        final next = (_current + 1) % outings.length;
                        _controller.animateToPage(next,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (outings.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(outings.length, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 28 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? const Color(0xFF1DB679)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
