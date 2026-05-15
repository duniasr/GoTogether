class LoginGreetingService {
  LoginGreetingService._();

  static final Set<String> _pendingGreetingUserIds = <String>{};

  static void markPending(String uid) {
    _pendingGreetingUserIds.add(uid);
  }

  static bool consume(String uid) {
    return _pendingGreetingUserIds.remove(uid);
  }
}
