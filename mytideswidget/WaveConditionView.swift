import SwiftUI

struct WaveConditionView: View {
    let waveData: WaveData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Wave height
            HStack {
                Image(systemName: "water.waves")
                    .font(.caption)
                    .foregroundStyle(.cyan)
                
                Text("\(Int(waveData.waveHeightMin))-\(Int(waveData.waveHeightMax)) ft")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(waveData.humanRelation)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Swell details
            HStack(spacing: 12) {
                // Period
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(waveData.period)s")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Direction
                HStack(spacing: 2) {
                    Image(systemName: "location.north.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(waveData.direction))
                    Text(waveData.directionCompass)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Quality score
                if waveData.waveHeightOptimal > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(waveData.waveHeightOptimal / 2) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}