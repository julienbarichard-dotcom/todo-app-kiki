// Fallback implementation for non-web platforms using url_launcher.
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(String url) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    // ignore errors silently — caller can fallback if needed
  }
}
