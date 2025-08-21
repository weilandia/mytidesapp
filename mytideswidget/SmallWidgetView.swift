import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: TideEntry
    
    var body: some View {
        if let tideData = entry.tideData {
            VStack(spacing: 8) {
                // Header with spot name
                HStack {
                    Image(systemName: "water.waves")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("mytides")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Current tide height
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", tideData.currentTide.height))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(tideGradient(for: tideData))
                        Text("ft")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption2)
                            .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                        Text(tideData.currentTide.isRising ? "Rising" : "Falling")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Next tide
                if let nextTide = tideData.nextTides.first {
                    HStack(spacing: 4) {
                        Text("Next \(nextTide.type == .high ? "High" : "Low"):")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        Text(nextTide.time.formatted(.dateTime.hour().minute()))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                // Tide pool indicator
                let tidePoolConditions = TidePoolConditions.evaluate(from: tideData)
                if tidePoolConditions.conditionRating == .excellent || tidePoolConditions.conditionRating == .good {
                    HStack(spacing: 2) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.caption2)
                            .foregroundColor(tidePoolConditions.conditionRating.color)
                        Text("Tide Pools!")
                            .font(.caption2)
                            .foregroundColor(tidePoolConditions.conditionRating.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(tidePoolConditions.conditionRating.color.opacity(0.2)))
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func tideGradient(for tideData: TideData) -> LinearGradient {
        if tideData.currentTide.isNegative {
            return LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        }
    }
    
    func qualityText(_ quality: SurfQuality) -> String {
        switch quality {
        case .excellent: return "Firing!"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    func qualityColor(_ quality: SurfQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}