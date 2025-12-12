import 'package:flutter/material.dart';

import 'daily_outing_carousel.dart';
import '../models/outing.dart';

/// Backwards-compatible wrapper for the new `DailyOutingCarousel` widget.
/// Keeps references to `DailyOutingWidget` working elsewhere in the codebase.
class DailyOutingWidget extends StatelessWidget {
  final List<Outing> outings;
  final void Function(Outing)? onView;

  const DailyOutingWidget({super.key, required this.outings, this.onView});

  @override
  Widget build(BuildContext context) {
    return DailyOutingCarousel(outings: outings, onView: onView);
  }
}
