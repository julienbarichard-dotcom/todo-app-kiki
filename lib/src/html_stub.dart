// Stub pour permettre un import conditionnel de `dart:html` sans casser
// les builds mobile/desktop. Fournit un objet `window` avec `localStorage`.

class LocalStorageStub {
  final Map<String, String> _store = {};
  String? operator [](String key) => _store[key];
  void operator []=(String key, String value) => _store[key] = value;
}

class WindowStub {
  final LocalStorageStub localStorage = LocalStorageStub();
}

final WindowStub window = WindowStub();
