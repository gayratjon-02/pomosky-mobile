import '../protocol/server_messages.dart';

enum SocketStatus { connecting, connected, reconnecting, closed }

/// What the room session needs from a connection. The real one is
/// `RoomSocket`; tests use a fake.
abstract interface class RoomTransport {
  Stream<ServerMessage> get messages;
  Stream<SocketStatus> get status;
  SocketStatus get currentStatus;

  void connect();

  /// Sends a frame; returns false when there is no open connection.
  bool send(String frame);

  Future<void> close();
}
