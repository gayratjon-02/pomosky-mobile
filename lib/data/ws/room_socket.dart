import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/backoff.dart';
import '../protocol/server_messages.dart';
import 'room_transport.dart';

typedef SocketConnector =
    Future<WebSocket> Function(String url, Map<String, dynamic> headers);

Future<WebSocket> _defaultConnector(String url, Map<String, dynamic> headers) =>
    WebSocket.connect(url, headers: headers);

/// A WebSocket to one room that reconnects by itself.
///
/// The server only accepts upgrades whose `Origin` equals its own host, so the
/// app sends it explicitly. [handshake] returns the frames to send right after
/// every (re)connect, such as `join` and `host.auth`.
class RoomSocket implements RoomTransport {
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
  int _generation = 0;
  bool _closed = false;
  SocketStatus _current = SocketStatus.connecting;

  @override
  Stream<ServerMessage> get messages => _messages.stream;
  @override
  Stream<SocketStatus> get status => _status.stream;
  @override
  SocketStatus get currentStatus => _current;

  @override
  void connect() {
    if (_closed) return;
    _setStatus(
      _attempt == 0 ? SocketStatus.connecting : SocketStatus.reconnecting,
    );
    _open();
  }

  Future<void> _open() async {
    // Every attempt gets a number. If connect() or reconnect() starts a newer
    // one while this one is still waiting, the older one is stale and must not
    // adopt its socket, or two connections would stay open.
    final generation = ++_generation;
    WebSocket? socket;
    try {
      socket = await _connector(url, {'Origin': origin});
      if (_closed || generation != _generation) {
        await socket.close();
        return;
      }
      socket.pingInterval = const Duration(seconds: 20); // notice dead links
      _socket = socket;
      _attempt = 0;
      _setStatus(SocketStatus.connected);
      final adopted = socket;
      socket.listen(
        _onData,
        onDone: () => _lost(adopted),
        onError: (_) => _lost(adopted),
        cancelOnError: true,
      );
      for (final frame in handshake()) {
        socket.add(frame);
      }
    } catch (_) {
      if (generation != _generation) {
        socket?.close().catchError((_) {});
        return;
      }
      // A failure after the socket was adopted (the handshake could not be
      // sent): drop it so the retry starts from a clean state.
      if (identical(_socket, socket)) _socket = null;
      socket?.close().catchError((_) {});
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

  @override
  void reconnect() {
    if (_closed) return;
    _retry?.cancel();
    _generation++; // an attempt still in flight is now stale
    final old = _socket;
    _socket = null; // its onDone is then ignored by _lost
    old?.close().catchError((_) {});
    _attempt = 0;
    connect();
  }

  @override
  bool send(String frame) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return false;
    socket.add(frame);
    return true;
  }

  @override
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
