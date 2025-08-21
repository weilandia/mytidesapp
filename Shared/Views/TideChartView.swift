import SwiftUI
import Charts

struct TideChartView: View {
    let predictions: [TidePrediction]
    let currentTime = Date()
    
    var body: some View {
        Chart {
            ForEach(predictions) { prediction in
                LineMark(
                    x: .value("Time", prediction.time),
                    y: .value("Height", prediction.height)
                )
                .foregroundStyle(
                    prediction.height < 0 ? 
                    Color.purple.gradient : 
                    Color.blue.gradient
                )
                .interpolationMethod(.catmullRom)
            }
            
            // Current time indicator
            RuleMark(x: .value("Now", currentTime))
                .foregroundStyle(.white.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .annotation(position: .top) {
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.hour()))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let height = value.as(Double.self) {
                        Text("\(height, specifier: "%.1f")ft")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.1))
            }
        }
        .chartYScale(domain: -2...7)
        .frame(height: 100)
    }
}

// For smooth interpolation between tide points
struct InterpolatedTidePrediction {
    static func interpolate(predictions: [TidePrediction], pointsPerHour: Int = 4) -> [TidePrediction] {
        guard predictions.count > 1 else { return predictions }
        
        var interpolated: [TidePrediction] = []
        
        for i in 0..<(predictions.count - 1) {
            let current = predictions[i]
            let next = predictions[i + 1]
            
            interpolated.append(current)
            
            // Add interpolated points between highs and lows
            let timeDiff = next.time.timeIntervalSince(current.time)
            let steps = Int(timeDiff / 3600 * Double(pointsPerHour)) // points based on hours
            
            for step in 1..<steps {
                let fraction = Double(step) / Double(steps)
                let interpolatedTime = current.time.addingTimeInterval(timeDiff * fraction)
                
                // Use cosine interpolation for more natural tide curves
                let cosinePosition = (1 - cos(fraction * .pi)) / 2
                let interpolatedHeight = current.height + (next.height - current.height) * cosinePosition
                
                interpolated.append(TidePrediction(
                    time: interpolatedTime,
                    height: interpolatedHeight,
                    type: current.type,
                    isRising: interpolatedHeight > current.height
                ))
            }
        }
        
        interpolated.append(predictions.last!)
        return interpolated
    }
}