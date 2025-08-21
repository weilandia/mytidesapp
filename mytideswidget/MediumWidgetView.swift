import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: TideEntry
    
    var body: some View {
        if let tideData = entry.tideData {
            HStack(spacing: 0) {
                // Left side - Current conditions
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack(spacing: 4) {
                        Image(systemName: "water.waves")
                            .foregroundColor(.cyan)
                            .font(.system(size: 14, weight: .medium))
                        Text("MyTides")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Current tide
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(String(format: "%.1f", tideData.currentTide.height))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(tideColor(for: tideData.currentTide.height))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ft")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Image(systemName: tideData.currentTide.isRising ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                            }
                        }
                    }
                    
                    // Tide pool indicator
                    let tidePoolConditions = TidePoolConditions.evaluate(from: tideData)
                    if tidePoolConditions.conditionRating == .excellent || tidePoolConditions.conditionRating == .good {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.teal)
                            Text("Tide Pools: \(tidePoolConditions.conditionRating.text)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.teal.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.teal.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 16)
                
                // Right side - Upcoming tides
                VStack(alignment: .leading, spacing: 10) {
                    Text("NEXT TIDES")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(tideData.nextTides.prefix(3).enumerated()), id: \.offset) { index, tide in
                            HStack(spacing: 4) {
                                Image(systemName: tide.type == .high ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(tide.type == .high ? .blue : .orange)
                                
                                Text("\(tide.type == .high ? "High" : "Low") \(tide.time.formatted(.dateTime.hour().minute())) • \(tide.height, specifier: "%.1f")ft")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Surf spot indicators
                    if let spotConditions = entry.spotConditions {
                        HStack(spacing: 16) {
                            ForEach(AppConfig.surflineSpots.prefix(2), id: \.id) { spot in
                                if let conditions = spotConditions[spot.id] {
                                    Link(destination: URL(string: spot.surflineCamURL)!) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 2) {
                                                Text(spot.displayName)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .lineLimit(1)
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.blue.opacity(0.7))
                                            }
                                            HStack(spacing: 1) {
                                                ForEach(0..<5) { i in
                                                    Image(systemName: i < Int(conditions.rating.value) ? "star.fill" : "star")
                                                        .font(.system(size: 8))
                                                        .foregroundColor(
                                                            i < Int(conditions.rating.value) ? .yellow : Color.gray.opacity(0.3)
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.trailing, 16)
                .padding(.vertical, 16)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity)
            }
            // Remove background to show gradient from container
        } else {
            VStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                    .scaleEffect(0.8)
                Text("Loading tides...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Remove background to show gradient
        }
    }
    
    func tideColor(for height: Double) -> Color {
        if height < 0 {
            return .purple
        } else if height < 2 {
            return .cyan
        } else if height < 4 {
            return .blue
        } else {
            return .indigo
        }
    }
}