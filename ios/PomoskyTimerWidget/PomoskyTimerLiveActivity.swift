import ActivityKit
import SwiftUI
import WidgetKit

private let skyBlue = Color(red: 0.36, green: 0.62, blue: 0.95)
private let breakGreen = Color(red: 0.40, green: 0.80, blue: 0.60)
private let pausedAmber = Color(red: 0.96, green: 0.72, blue: 0.30)

extension PomoskyTimerAttributes.ContentState {
  var tint: Color {
    switch phase {
    case "break": return breakGreen
    case "paused": return pausedAmber
    default: return skyBlue
    }
  }

  var symbol: String {
    switch phase {
    case "break": return "cup.and.saucer.fill"
    case "paused": return "pause.fill"
    default: return "timer"
    }
  }
}

/// The countdown. Running phases use the system timer text, which keeps
/// counting without any update from the app; a paused one is frozen.
struct CountdownText: View {
  let state: PomoskyTimerAttributes.ContentState
  /// True once a running phase has passed its end (the app may be suspended).
  var isStale = false

  private func frozen(_ seconds: Double) -> String {
    let total = Int(max(seconds, 0).rounded(.up))
    return String(format: "%02d:%02d", total / 60, total % 60)
  }

  var body: some View {
    if state.isPaused {
      Text(frozen(state.remainingSeconds)).monospacedDigit()
    } else if isStale {
      Text("Done")
    } else {
      Text(timerInterval: Date()...max(state.endDate, Date().addingTimeInterval(1)),
           countsDown: true)
        .monospacedDigit()
    }
  }
}

struct LockScreenView: View {
  let state: PomoskyTimerAttributes.ContentState
  var isStale = false

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: state.symbol)
        .font(.title2)
        .foregroundStyle(state.tint)
      VStack(alignment: .leading, spacing: 2) {
        Text(state.title).font(.headline)
        if !state.label.isEmpty {
          Text(state.label).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
        }
      }
      Spacer()
      CountdownText(state: state, isStale: isStale)
        .font(.system(size: 36, weight: .semibold, design: .rounded))
        .foregroundStyle(state.tint)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.trailing)
        .frame(width: 150, alignment: .trailing)
    }
    .padding(16)
    .activityBackgroundTint(Color.black.opacity(0.55))
    .activitySystemActionForegroundColor(.white)
  }
}

struct PomoskyTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PomoskyTimerAttributes.self) { context in
      LockScreenView(state: context.state, isStale: context.isStale)
    } dynamicIsland: { context in
      let state = context.state
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(state.title, systemImage: state.symbol)
            .font(.headline)
            .foregroundStyle(state.tint)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CountdownText(state: state, isStale: context.isStale)
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundStyle(state.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.trailing)
            .frame(width: 120, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          if !state.label.isEmpty {
            Text(state.label).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
          }
        }
      } compactLeading: {
        Image(systemName: state.symbol).foregroundStyle(state.tint)
      } compactTrailing: {
        CountdownText(state: state, isStale: context.isStale)
          .frame(maxWidth: 52)
          .foregroundStyle(state.tint)
      } minimal: {
        Image(systemName: state.symbol).foregroundStyle(state.tint)
      }
      .keylineTint(state.tint)
    }
  }
}
