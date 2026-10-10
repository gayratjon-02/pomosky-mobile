import '../protocol/server_messages.dart';

enum SocketStatus { connecting, connected, reconnecting, closed }

/// What the room session needs from a connection. The real one is
/// `RoomSocket`; tests use a fake.
abstract interface class RoomTransport {
  Stream<ServerMessage> get messages;
  Stream<SocketStatus> get status;
  SocketStatus get currentStatus;

  void connect();

  /// Drops the current connection, if any, and connects again at once. Used
  /// when the app returns from the background, where a connection may have
  /// died without anyone noticing.
  void reconnect();

  /// Sends a frame; returns false when there is no open connection.
  bool send(String frame);

  Future<void> close();
}
