import SwiftUI
import WidgetKit
import Charts

struct LargeWidgetView: View {
    let entry: TideEntry

    var body: some View {
        if let tideData = entry.tideData {
            VStack(alignment: .leading, spacing: 12) {
                // Current tide - make it prominent
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOW")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(String(format: "%.1f", tideData.currentTide.height))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(tideGradient(for: tideData))
                            Text("ft")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                            Text(tideData.currentTide.isRising ? "Rising" : "Falling")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Next tides on the right side of current tide
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("NEXT TIDES")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        ForEach(Array(tideData.nextTides.prefix(3).enumerated()), id: \.offset) { index, tide in
                            HStack(spacing: 4) {
                                Text(tide.type == .high ? "↑" : "↓")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(tide.type == .high ? .blue : .orange)
                                Text("\(tide.time.formatted(.dateTime.hour().minute()))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.9))
                                Text("·")
                                    .foregroundColor(.white.opacity(0.4))
                                Text("\(String(format: "%.1f", tide.height))ft")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(tide.height < 0 ? .purple : .cyan)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Tide Pool Conditions
                let tidePoolConditions = TidePoolConditions.evaluate(from: tideData)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tidePoolConditions.conditionRating.color)
                        Text("TIDE POOLS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text(tidePoolConditions.conditionRating.text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(tidePoolConditions.conditionRating.color)
                    
                    Text(tidePoolConditions.bestTimeWindow)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if tidePoolConditions.isOptimalTime {
                        Text("Great time to explore!")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Surf Spots
                VStack(alignment: .leading, spacing: 8) {
                    Text("SURF SPOTS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Get actual conditions from API if available
                    if let spotConditions = entry.spotConditions {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(AppConfig.surflineSpots.prefix(3), id: \.id) { spot in
                                if let conditions = spotConditions[spot.id] {
                                    Link(destination: URL(string: spot.surflineCamURL)!) {
                                        HStack {
                                            HStack(spacing: 3) {
                                                Text(spot.displayName)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.blue.opacity(0.8))
                                            }
                                            Spacer()
                                            Text(conditions.qualityEmoji)
                                                .font(.system(size: 12))
                                            Text("•")
                                                .foregroundColor(.white.opacity(0.4))
                                            Text(conditions.waveHeight)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.cyan)
                                            Text("•")
                                                .foregroundColor(.white.opacity(0.4))
                                            Text(conditions.rating.text)
                                                .font(.system(size: 10))
                                                .foregroundColor(ratingColor(conditions.rating.value))
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Fallback to placeholder data
                        VStack(alignment: .leading, spacing: 6) {
                            // Pleasure Point
                            if let ppSpot = AppConfig.surflineSpots.first(where: { $0.displayName == "Pleasure Point" }) {
                                Link(destination: URL(string: ppSpot.surflineCamURL)!) {
                                    HStack {
                                        HStack(spacing: 3) {
                                            Text("Pleasure Point")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(.blue.opacity(0.8))
                                        }
                                        Spacer()
                                        Text(tideData.pleasurePointCondition.quality.emoji)
                                            .font(.system(size: 12))
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.4))
                                        Text(tideData.pleasurePointCondition.reason)
                                            .font(.system(size: 10))
                                            .foregroundColor(qualityColor(tideData.pleasurePointCondition.quality))
                                    }
                                }
                            }
                            
                            // 26th Ave
                            if let spot26 = AppConfig.surflineSpots.first(where: { $0.displayName == "26th Ave" }) {
                                Link(destination: URL(string: spot26.surflineCamURL)!) {
                                    HStack {
                                        HStack(spacing: 3) {
                                            Text("26th Ave")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(.blue.opacity(0.8))
                                        }
                                        Spacer()
                                        Text(tideData.twentySixthCondition.quality.emoji)
                                            .font(.system(size: 12))
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.4))
                                        Text(tideData.twentySixthCondition.reason)
                                            .font(.system(size: 10))
                                            .foregroundColor(qualityColor(tideData.twentySixthCondition.quality))
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func tideGradient(for tideData: TideData) -> LinearGradient {
        if tideData.currentTide.height < 0 {
            return LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        } else if tideData.currentTide.height < 2 {
            return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
        }
    }
    
    func qualityColor(_ quality: SurfQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .cyan
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    func ratingColor(_ value: Double) -> Color {
        switch value {
        case 0..<1: return .red
        case 1..<2: return .orange
        case 2..<3: return .yellow
        case 3..<4: return .cyan
        case 4...: return .green
        default: return .gray
        }
    }
}