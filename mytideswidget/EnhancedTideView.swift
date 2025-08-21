import SwiftUI
import Charts

// Enhanced tide header with glass morphism and negative tide indicator
struct EnhancedTideHeader: View {
    let tideData: TideData
    @State private var animateWater = false
    
    var body: some View {
        ZStack {
            // Glass morphism background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                // Top row with tide info - more compact
                HStack {
                    // Smaller animated tide indicator
                    Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            tideData.currentTide.isRising ? 
                            LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(animateWater ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateWater)
                    
                    Text("\(tideData.currentTide.isRising ? "Rising" : "Falling") Tide")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Tide height with negative indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            if tideData.currentTide.isNegative {
                                NegativeTideIndicator()
                            }
                            
                            Text(String(format: "%.1f", tideData.currentTide.height))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(tideHeightGradient)
                            
                            Text("ft")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .offset(y: -6)
                        }
                        
                        if tideData.currentTide.isNegative {
                            Text("NEGATIVE TIDE")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.purple.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(.purple.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                
                // Tide pool alert with glass effect
                if tideData.currentTide.shouldShowTidePoolAlert {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                            .scaleEffect(animateWater ? 1.2 : 1.0)
                        
                        Text(tideData.currentTide.tidePoolMessage ?? "Tide pools accessible!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.purple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.purple.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Next tide info
                if let nextTide = tideData.nextTides.first {
                    HStack {
                        Image(systemName: nextTide.type == .high ? "arrow.up.to.line" : "arrow.down.to.line")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption2)
                        
                        Text("Next \(nextTide.type == .high ? "High" : "Low"):")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(nextTide.time.formatted(.dateTime.hour().minute()))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("(\(nextTide.height, specifier: "%.1f") ft)")
                            .font(.caption)
                            .foregroundColor(nextTide.isNegative ? .purple : .white.opacity(0.6))
                        
                        if nextTide.isNegative {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.purple)
                                .font(.caption2)
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.2))
                    )
                }
            }
            .padding(12)
        }
        .onAppear {
            animateWater = true
        }
    }
    
    var tideHeightGradient: LinearGradient {
        if tideData.currentTide.isNegative {
            return LinearGradient(
                colors: [.purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if tideData.currentTide.height > 5 {
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.cyan, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// Animated negative tide indicator
struct NegativeTideIndicator: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.purple.opacity(0.3))
                .frame(width: 30, height: 30)
                .scaleEffect(animate ? 1.3 : 1.0)
                .opacity(animate ? 0 : 1)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animate)
            
            Circle()
                .fill(.purple)
                .frame(width: 20, height: 20)
                .overlay(
                    Text("-")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .onAppear {
            animate = true
        }
    }
}

// Enhanced tide chart with negative tide highlighting and hover
struct EnhancedTideChart: View {
    let predictions: [TidePrediction]
    @State private var selectedX: Date?
    let currentTime = Date()
    
    // Find the tide height at a given time
    private func tideHeight(at time: Date) -> (height: Double, isNegative: Bool)? {
        guard let closest = predictions.min(by: { 
            abs($0.time.timeIntervalSince(time)) < abs($1.time.timeIntervalSince(time))
        }) else { return nil }
        
        // Only show if within 30 minutes of a data point
        if abs(closest.time.timeIntervalSince(time)) < 1800 {
            return (closest.height, closest.height < 0)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Chart {
                    // Negative tide area
                    RectangleMark(
                        xStart: .value("Start", predictions.first?.time ?? currentTime),
                        xEnd: .value("End", predictions.last?.time ?? currentTime),
                        yStart: .value("Bottom", -2),
                        yEnd: .value("Top", 0)
                    )
                    .foregroundStyle(.purple.opacity(0.2))
                    
                    // Tide curve
                    ForEach(predictions) { prediction in
                        LineMark(
                            x: .value("Time", prediction.time),
                            y: .value("Height", prediction.height)
                        )
                        .foregroundStyle(
                            prediction.height < 0 ? 
                            LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        
                        // Area under curve
                        AreaMark(
                            x: .value("Time", prediction.time),
                            y: .value("Height", prediction.height)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    prediction.height < 0 ? .purple.opacity(0.3) : .cyan.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Current time indicator - subtle without text
                    RuleMark(x: .value("Current", currentTime))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    
                    // Zero line
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(.purple.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    
                    // Selection indicator
                    if let selectedX = selectedX {
                        RuleMark(x: .value("Selected", selectedX))
                            .foregroundStyle(.white.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 0.5))
                        
                        // Add a point at the selected position
                        if let tideData = tideHeight(at: selectedX) {
                            PointMark(
                                x: .value("Selected", selectedX),
                                y: .value("Height", tideData.height)
                            )
                            .foregroundStyle(tideData.isNegative ? Color.purple : Color.cyan)
                            .symbolSize(60)
                        }
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
                                Text("\(height, specifier: "%.0f")ft")
                                    .font(.caption2)
                                    .foregroundColor(height < 0 ? .purple : .white.opacity(0.6))
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                    }
                }
                .chartYScale(domain: -2...7)
                .chartXSelection(value: $selectedX)
                .frame(height: 120)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .overlay(alignment: .topLeading) {
                    // Tooltip
                    if let selectedX = selectedX,
                       let tideData = tideHeight(at: selectedX) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedX.formatted(.dateTime.hour().minute()))
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Text("\(String(format: "%.1f", tideData.height)) ft")
                                .font(.caption)
                                .foregroundColor(tideData.isNegative ? .purple : .cyan)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .padding(8)
                    }
                }
            }
        }
    }
}