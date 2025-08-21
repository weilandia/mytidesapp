import SwiftUI

struct TidePoolConditions {
    let currentTideHeight: Double
    let lowestTide: TidePrediction?
    let nextLowTide: TidePrediction?
    let isOptimalTime: Bool
    let conditionRating: TidePoolRating
    let bestTimeWindow: String
    let safetyWarning: String?
    
    // Computed property for convenience
    var condition: TidePoolRating {
        return conditionRating
    }
    
    enum TidePoolRating: String {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case dangerous = "dangerous"
        
        var text: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .dangerous: return "Dangerous"
            }
        }
        
        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "✨"
            case .fair: return "⭐"
            case .poor: return "☁️"
            case .dangerous: return "⚠️"
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .cyan
            case .fair: return .yellow
            case .poor: return .orange
            case .dangerous: return .red
            }
        }
    }
    
    static func evaluate(from tideData: TideData) -> TidePoolConditions {
        let currentHeight = tideData.currentTide.height
        
        // Find the next low tide from nextTides
        let nextLow = tideData.nextTides
            .filter { $0.type == .low && $0.time > Date() }
            .first
        
        // Find today's lowest tide from hourly predictions
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Use hourlyPredictions to find low points
        let todaysLows = tideData.hourlyPredictions
            .filter { $0.time >= startOfDay && $0.time < endOfDay }
            .sorted { $0.height < $1.height }
        
        let lowestToday = todaysLows.first
        
        // Determine rating based on current and upcoming conditions
        let rating: TidePoolRating
        let isOptimal: Bool
        var safetyWarning: String? = nil
        
        if currentHeight < -1.0 {
            rating = .excellent
            isOptimal = true
        } else if currentHeight < 0.5 {
            rating = .good
            isOptimal = true
        } else if currentHeight < 1.5 {
            rating = .fair
            isOptimal = false
        } else if currentHeight < 3.0 {
            rating = .poor
            isOptimal = false
        } else {
            rating = .poor
            isOptimal = false
            safetyWarning = "High tide - pools submerged"
        }
        
        // Add safety warnings for extreme conditions
        if currentHeight < -1.5 {
            safetyWarning = "Very low tide - watch for slippery rocks"
        }
        
        // Calculate best time window
        let bestWindow: String
        if let nextLow = nextLow {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeStr = formatter.string(from: nextLow.time)
            
            if nextLow.height < 0 {
                bestWindow = "Next window: \(timeStr) (\(String(format: "%.1f", nextLow.height)) ft)"
            } else if nextLow.height < 1.0 {
                bestWindow = "Fair conditions at \(timeStr)"
            } else {
                bestWindow = "Poor conditions at next low (\(timeStr))"
            }
        } else {
            bestWindow = "No low tide upcoming today"
        }
        
        return TidePoolConditions(
            currentTideHeight: currentHeight,
            lowestTide: lowestToday,
            nextLowTide: nextLow,
            isOptimalTime: isOptimal,
            conditionRating: rating,
            bestTimeWindow: bestWindow,
            safetyWarning: safetyWarning
        )
    }
}

struct TidePoolConditionCard: View {
    let conditions: TidePoolConditions
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openTidePoolsInfo) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with title and rating
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(.teal)
                            .font(.title3)
                        Text("Tide Pools")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(conditions.conditionRating.emoji)
                        .font(.title2)
                    
                    Text(conditions.conditionRating.text)
                        .font(.caption)
                        .foregroundColor(conditions.conditionRating.color)
                }
                
                // Current conditions and timing
                HStack(spacing: 16) {
                    // Current tide info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "water.waves")
                                .foregroundColor(conditions.currentTideHeight < 0 ? .purple : .cyan)
                                .font(.caption)
                            Text(String(format: "%.1f ft", conditions.currentTideHeight))
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(conditions.currentTideHeight < 0 ? .purple : .white)
                        }
                        Text(conditions.currentTideHeight < 0 ? "Negative tide!" : "Current level")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Best time window
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Timing")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Text(conditions.bestTimeWindow)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Info icon
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.caption)
                }
                
                // Status message or warning
                if conditions.isOptimalTime {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Great time to explore tide pools!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if let warning = conditions.safetyWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("Conditions improving at low tide")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    var backgroundGradient: LinearGradient {
        if conditions.isOptimalTime {
            // Special gradient for optimal conditions
            return LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.3, blue: 0.3).opacity(0.9),
                    Color(red: 0.0, green: 0.2, blue: 0.25).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.25).opacity(0.9),
                    Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var borderColor: Color {
        if isHovered {
            return conditions.conditionRating.color.opacity(0.5)
        } else if conditions.isOptimalTime {
            return Color.teal.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    func openTidePoolsInfo() {
        // Open a tide pools information page or local guide
        // You can customize this URL to point to a local tide pools guide
        if let url = URL(string: "https://www.californiabeaches.com/santa-cruz-tide-pools/") {
            NSWorkspace.shared.open(url)
        }
    }
}