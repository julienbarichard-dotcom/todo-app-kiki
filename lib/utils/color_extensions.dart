import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Safe alternative to `withOpacity` that avoids the deprecated API.
  ///
  /// Converts a double opacity (0.0 - 1.0) to an integer alpha (0 - 255).
  Color withOpacitySafe(double opacity) => withAlpha((opacity * 255).round());
}
