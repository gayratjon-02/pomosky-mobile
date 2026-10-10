import '../../data/protocol/server_messages.dart';

/// What to tell the person when the server refuses something. The server's
/// own message is used for codes without a better wording, because it knows
/// the reason (for example why a label was rejected).
String friendlyError(ErrorMessage error) {
  switch (error.code) {
    case 'forbidden':
      return 'Only the host can do that';
    case 'rate_limited':
      return 'Slow down a little';
    case 'invalid_transition':
      return 'That is not possible right now';
    default:
      return error.message.isEmpty ? 'Something went wrong' : error.message;
  }
}
