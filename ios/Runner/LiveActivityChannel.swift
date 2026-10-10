import ActivityKit
import Flutter
import Foundation

/// Flutter method channel that starts, updates and ends the timer's Live
/// Activity. Every failure is reported as a Flutter error, which the Dart side
/// ignores: Live Activities may be disabled or unsupported.
final class LiveActivityChannel {
  static let name = "app.pomosky/live_activity"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    let handler = LiveActivityChannel()
    channel.setMethodCallHandler { call, result in
      handler.handle(call, result: result)
    }
  }

  // Typed as Any so the class loads on iOS versions without ActivityKit.
  private var current: Any?

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterError(code: "unsupported", message: nil, details: nil))
      return
    }
    switch call.method {
    case "start":
      guard let state = Self.state(from: call.arguments) else { return badArgs(result) }
      start(state, result)
    case "update":
      guard let state = Self.state(from: call.arguments) else { return badArgs(result) }
      update(state, result)
    case "end":
      end(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func badArgs(_ result: FlutterResult) {
    result(FlutterError(code: "bad_args", message: nil, details: nil))
  }

  @available(iOS 16.2, *)
  private static func state(from arguments: Any?) -> PomoskyTimerAttributes.ContentState? {
    guard let a = arguments as? [String: Any],
      let phase = a["phase"] as? String,
      let endsAt = (a["endsAtMs"] as? NSNumber)?.doubleValue,
      let remaining = (a["remainingMs"] as? NSNumber)?.doubleValue,
      let duration = (a["durationMs"] as? NSNumber)?.doubleValue
    else { return nil }
    return PomoskyTimerAttributes.ContentState(
      phase: phase,
      label: a["label"] as? String ?? "",
      endDate: Date(timeIntervalSince1970: endsAt / 1000),
      remainingSeconds: remaining / 1000,
      durationSeconds: duration / 1000)
  }

  @available(iOS 16.2, *)
  private func start(_ state: PomoskyTimerAttributes.ContentState, _ result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(FlutterError(code: "disabled", message: nil, details: nil))
      return
    }
    Task { @MainActor in
      // Drop activities left behind by an earlier launch.
      for old in Activity<PomoskyTimerAttributes>.activities {
        await old.end(nil, dismissalPolicy: .immediate)
      }
      do {
        current = try Activity.request(
          attributes: PomoskyTimerAttributes(),
          content: .init(state: state, staleDate: nil),
          pushType: nil)
        result(nil)
      } catch {
        result(FlutterError(code: "request_failed", message: nil, details: nil))
      }
    }
  }

  @available(iOS 16.2, *)
  private func update(_ state: PomoskyTimerAttributes.ContentState, _ result: @escaping FlutterResult) {
    guard let activity = current as? Activity<PomoskyTimerAttributes> else {
      start(state, result)
      return
    }
    Task { @MainActor in
      await activity.update(.init(state: state, staleDate: nil))
      result(nil)
    }
  }

  @available(iOS 16.2, *)
  private func end(_ result: @escaping FlutterResult) {
    let activity = current as? Activity<PomoskyTimerAttributes>
    current = nil
    Task { @MainActor in
      if let activity = activity {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      for leftover in Activity<PomoskyTimerAttributes>.activities {
        await leftover.end(nil, dismissalPolicy: .immediate)
      }
      result(nil)
    }
  }
}
