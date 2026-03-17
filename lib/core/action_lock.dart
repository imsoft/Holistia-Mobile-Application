/// A lightweight mutex for async UI actions.
///
/// Prevents concurrent execution of the same async action (e.g. button
/// callbacks) by holding a boolean lock for the duration of the call.
///
/// Usage inside a [State]:
/// ```dart
/// final _submitLock = ActionLock();
///
/// Future<void> _onSubmit() => _submitLock.run(() async {
///   // only one execution at a time
/// });
/// ```
class ActionLock {
  bool _locked = false;

  bool get isLocked => _locked;

  /// Runs [action] if not already running. Returns `null` if skipped.
  Future<T?> run<T>(Future<T> Function() action) async {
    if (_locked) return null;
    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
    }
  }
}
