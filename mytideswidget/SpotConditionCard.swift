import SwiftUI

struct SpotConditionCard: View {
    let conditions: SpotConditions
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openWebcam) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with spot name and rating
                HStack {
                    Text(conditions.spot.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(conditions.qualityEmoji)
                        .font(.title2)
                    
                    Text(conditions.rating.text)
                        .font(.caption)
                        .foregroundColor(ratingColor)
                }
                
                // Wave and wind info
                HStack(spacing: 16) {
                    // Wave info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "water.waves")
                                .foregroundColor(.cyan)
                                .font(.caption)
                            Text(conditions.waveHeight)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        Text("\(conditions.period)s @ \(conditions.direction)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Wind info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(conditions.windIcon)
                                .font(.caption)
                            Text("\(conditions.windSpeed) mph")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        Text(conditions.windDirection)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Camera icon
                    Image(systemName: "video.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.caption)
                }
                
                // Description
                Text(conditions.waveDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
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
    
    var ratingColor: Color {
        switch conditions.rating.value {
        case 0..<1: return .red
        case 1..<2: return .orange
        case 2..<3: return .yellow
        case 3..<4: return .green
        case 4...: return .cyan
        default: return .gray
        }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.15, blue: 0.25).opacity(0.9),
                Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var borderColor: Color {
        isHovered ? ratingColor.opacity(0.5) : Color.white.opacity(0.1)
    }
    
    func openWebcam() {
        let webcamURL = conditions.spot.surflineWebURL
        if let url = URL(string: webcamURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

// Compact version for widget
struct CompactSpotCard: View {
    let conditions: SpotConditions
    
    var body: some View {
        Link(destination: URL(string: conditions.spot.surflineWebURL)!) {
            HStack(spacing: 8) {
                Text(conditions.qualityEmoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conditions.spot.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(conditions.waveHeight)
                            .font(.caption2)
                            .foregroundColor(.cyan)
                        
                        Text("💨 \(conditions.windSpeed)mph")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "video.circle.fill")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.caption)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}