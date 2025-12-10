import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  double? _temperature;
  int? _weatherCode;
  bool _loading = true;

  static const double lat = 43.2965; // Marseille
  static const double lon = 5.3698;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _loading = true;
    });

    try {
      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&temperature_unit=celsius');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final current = data['current_weather'] as Map<String, dynamic>?;
        if (current != null) {
          setState(() {
            _temperature = (current['temperature'] as num).toDouble();
            // Open-Meteo fournit un "weathercode" indiquant l'état (WMO codes)
            _weatherCode = (current['weathercode'] as num?)?.toInt();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // ignore errors, keep default
    }

    setState(() {
      _loading = false;
      _temperature = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final tempText = _temperature != null ? '${_temperature!.round()}°C' : '--';

    // Map weatherCode -> icon, color, label
    IconData icon = Icons.wb_sunny;
    Color iconColor = Colors.amber;
    String conditionLabel = 'Ensoleillé';

    if (_weatherCode != null) {
      final code = _weatherCode!;
      if (code == 0) {
        icon = Icons.wb_sunny;
        iconColor = Colors.amber;
        conditionLabel = 'Ensoleillé';
      } else if (code >= 1 && code <= 3) {
        icon = Icons.wb_sunny;
        iconColor = Colors.yellow.shade600;
        conditionLabel = 'Partiellement ensoleillé';
      } else if (code == 45 || code == 48) {
        icon = Icons.cloud;
        iconColor = Colors.grey;
        conditionLabel = 'Brouillard';
      } else if ((code >= 51 && code <= 55) ||
          (code >= 61 && code <= 65) ||
          (code >= 80 && code <= 82)) {
        icon = Icons.invert_colors; // pluie
        iconColor = Colors.lightBlueAccent;
        conditionLabel = 'Pluie';
      } else if (code == 66 || code == 67) {
        // Freezing drizzle / freezing rain — risque de verglas
        icon = Icons.ac_unit;
        iconColor = Colors.cyanAccent;
        conditionLabel = 'Verglas / pluie glacée';
      } else if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
        icon = Icons.ac_unit; // neige
        iconColor = Colors.white;
        conditionLabel = 'Neige';
      } else if (code >= 95 && code <= 99) {
        icon = Icons.flash_on;
        iconColor = Colors.orangeAccent;
        conditionLabel = 'Orage';
      } else if (code == 3) {
        icon = Icons.cloud;
        iconColor = Colors.grey;
        conditionLabel = 'Couvert';
      } else {
        icon = Icons.wb_sunny;
        iconColor = Colors.amber;
        conditionLabel = 'Soleil';
      }
      // Affiner: si code indique pluie/neige mais température <= 0 => verglas possible
      if ((conditionLabel == 'Pluie' || conditionLabel == 'Neige') &&
          _temperature != null &&
          _temperature! <= 0) {
        conditionLabel = 'Risque verglas (temp ≤ 0°C)';
        icon = Icons.ac_unit;
        iconColor = Colors.cyanAccent;
      }
    }

    // Short label for compact display
    String conditionShort = conditionLabel;
    if (conditionLabel.contains('Partiellement')) conditionShort = 'Nuageux';
    if (conditionLabel.contains('Ensoleil') || conditionLabel == 'Soleil') {
      conditionShort = 'Soleil';
    }
    if (conditionLabel.contains('Pluie')) conditionShort = 'Pluie';
    if (conditionLabel.contains('Neige')) conditionShort = 'Neige';
    if (conditionLabel.contains('Verglas')) conditionShort = 'Verglas';
    if (conditionLabel.contains('Orage')) conditionShort = 'Orage';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: InkWell(
        onTap: _fetchWeather,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            const Text('MRS ',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text(tempText,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            // small pill for condition
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(conditionShort,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.refresh, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
