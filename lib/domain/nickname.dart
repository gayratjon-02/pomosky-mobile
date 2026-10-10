/// Checks a nickname the way the server does (`moderation.ValidateNickname`):
/// 2 to 24 characters after trimming, and no control characters. Returns the
/// reason when it is not acceptable, null when it is.
String? nicknameProblem(String input) {
  final s = input.trim();
  final length = s.runes.length;
  if (length < 2 || length > 24) return 'Use 2 to 24 characters';
  if (s.runes.any((r) => r < 0x20 || (r >= 0x7F && r <= 0x9F))) {
    return 'Remove the special characters';
  }
  return null;
}

/// The nickname to send, trimmed, or null when it must not be sent.
String? nicknameToSend(String input) =>
    nicknameProblem(input) == null ? input.trim() : null;
