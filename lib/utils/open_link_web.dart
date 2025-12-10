import 'dart:html' as html;

Future<void> openLink(String url) async {
  try {
    html.window.open(url, '_blank');
  } catch (e) {
    // ignore
  }
}
