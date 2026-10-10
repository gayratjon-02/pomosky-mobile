/// Where the backend lives. Override at build time:
/// `flutter run --dart-define=BASE_URL=http://localhost:8080`.
const baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://pomosky-c157de.eastasia.cloudapp.azure.com',
);

/// The WebSocket address of a room, `ws(s)://host/ws/{id}`.
String roomSocketUrl(String roomId, {String base = baseUrl}) {
  final uri = Uri.parse(base);
  return uri
      .replace(
        scheme: uri.scheme == 'https' ? 'wss' : 'ws',
        path: '/ws/$roomId',
      )
      .toString();
}

/// The value of the `Origin` header: the server accepts upgrades only from its
/// own origin.
String originOf({String base = baseUrl}) {
  final uri = Uri.parse(base);
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}

/// The public link of a room, what people share and open in a browser.
String roomLink(String roomId, {String base = baseUrl}) =>
    Uri.parse(base).replace(path: '/r/$roomId').toString();
