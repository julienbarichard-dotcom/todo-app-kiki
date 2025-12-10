// Conditional export. Web implementation will be used when available.
export 'open_link_stub.dart' if (dart.library.html) 'open_link_web.dart';
