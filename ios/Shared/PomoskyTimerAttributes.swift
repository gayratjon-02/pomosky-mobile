import ActivityKit
import Foundation

/// Shared by the app (which starts the activity) and the widget extension
/// (which draws it). The two must compile the same definition.
@available(iOS 16.2, *)
struct PomoskyTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// "focus", "break" or "paused".
    var phase: String
    var label: String
    /// When the running phase ends.
    var endDate: Date
    /// Time left while paused, in seconds.
    var remainingSeconds: Double
    var durationSeconds: Double

    var isPaused: Bool { phase == "paused" }

    var title: String {
      switch phase {
      case "break": return "Break"
      case "paused": return "Paused"
      default: return "Focus"
      }
    }
  }
}
