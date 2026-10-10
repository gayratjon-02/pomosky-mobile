import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/backoff.dart';
import '../protocol/server_messages.dart';

enum SocketStatus { connecting, connected, reconnecting, closed }

typedef SocketConnector =
    Future<WebSocket> Function(String url, Map<String, dynamic> headers);

Future<WebSocket> _defaultConnector(String url, Map<String, dynamic> headers) =>
    WebSocket.connect(url, headers: headers);

/// A WebSocket to one room that reconnects by itself.
///
/// The server only accepts upgrades whose `Origin` equals its own host, so the
/// app sends it explicitly. [handshake] returns the frames to send right after
/// every (re)connect, such as `join` and `host.auth`.
class RoomSocket {
  RoomSocket({
    required this.url,
    required this.origin,
    required this.handshake,
    SocketConnector connector = _defaultConnector,
    Random? random,
  }) : _connector = connector,
       _random = random ?? Random();

  final String url;
  final String origin;
  final List<String> Function() handshake;
  final SocketConnector _connector;
  final Random _random;

  final _messages = StreamController<ServerMessage>.broadcast();
  final _status = StreamController<SocketStatus>.broadcast();
  WebSocket? _socket;
  Timer? _retry;
  int _attempt = 0;
  bool _closed = false;
  SocketStatus _current = SocketStatus.connecting;

  Stream<ServerMessage> get messages => _messages.stream;
  Stream<SocketStatus> get status => _status.stream;
  SocketStatus get currentStatus => _current;

  void connect() {
    if (_closed) return;
    _setStatus(
      _attempt == 0 ? SocketStatus.connecting : SocketStatus.reconnecting,
    );
    _open();
  }

  Future<void> _open() async {
    try {
      final socket = await _connector(url, {'Origin': origin});
      if (_closed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _attempt = 0;
      _setStatus(SocketStatus.connected);
      socket.listen(
        _onData,
        onDone: () => _lost(socket),
        onError: (_) => _lost(socket),
        cancelOnError: true,
      );
      for (final frame in handshake()) {
        socket.add(frame);
      }
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _onData(dynamic data) {
    if (data is! String) return; // the protocol is text only
    try {
      _messages.add(
        ServerMessage.fromJson(jsonDecode(data) as Map<String, dynamic>),
      );
    } catch (_) {
      // A frame we cannot read is skipped; it must not drop the connection.
    }
  }

  void _lost(WebSocket socket) {
    if (_closed || !identical(_socket, socket)) return;
    _socket = null;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) return;
    _setStatus(SocketStatus.reconnecting);
    final delay = backoffDelay(_attempt, random: _random);
    _attempt++;
    _retry = Timer(delay, _open);
  }

  /// Sends a frame; returns false when there is no open connection.
  bool send(String frame) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return false;
    socket.add(frame);
    return true;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _retry?.cancel();
    _setStatus(SocketStatus.closed);
    await _socket?.close();
    _socket = null;
    await _messages.close();
    await _status.close();
  }

  void _setStatus(SocketStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }
}
