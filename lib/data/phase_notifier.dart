import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifications for the end of a phase while the app is in the background,
/// where it cannot ring by itself.
abstract interface class PhaseNotifier {
  /// Asks the person for permission; true when notifications are allowed.
  Future<bool> requestPermission();

  /// Shows a notification at [at]; replaces the one scheduled before.
  Future<void> schedule({
    required DateTime at,
    required String title,
    required String body,
  });

  /// Removes the scheduled notification, if any.
  Future<void> cancel();
}

/// Does nothing; the default in tests.
class NoPhaseNotifier implements PhaseNotifier {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required DateTime at,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel() async {}
}

/// Local notifications through the system scheduler, so they fire even while
/// the app is suspended.
class LocalPhaseNotifier implements PhaseNotifier {
  LocalPhaseNotifier(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _id = 1; // one pending notification at a time

  /// Sets the plugin up. Permission is not asked here but at a good moment
  /// (see [requestPermission]).
  static Future<LocalPhaseNotifier> create() async {
    tzdata.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    return LocalPhaseNotifier(plugin);
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> schedule({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        // An absolute instant, so the zone does not matter.
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'phase_end',
            'Timer',
            channelDescription: 'Tells you when a focus or break phase ends',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        // TODO(verify): exact alarms need a permission on Android 12+; the
        // inexact mode may fire a little late there.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // A notification that cannot be scheduled must never break the timer.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
