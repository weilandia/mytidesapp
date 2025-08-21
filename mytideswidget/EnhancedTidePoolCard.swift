import SwiftUI

struct WeeklyTidePoolForecast {
    struct DayForecast: Identifiable {
        let id = UUID()
        let date: Date
        let bestLowTide: TidePrediction?
        let rating: TidePoolConditions.TidePoolRating
        let bestTime: String
        
        var dayName: String {
            let formatter = DateFormatter()
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInTomorrow(date) {
                return "Tomorrow"
            } else {
                formatter.dateFormat = "EEE"
                return formatter.string(from: date)
            }
        }
    }
    
    let forecasts: [DayForecast]
    let bestDays: [DayForecast]
    
    static func generate(from predictions: [NOAAPrediction]) -> WeeklyTidePoolForecast {
        let calendar = Calendar.current
        var dailyForecasts: [DayForecast] = []
        
        // Group predictions by day
        let groupedByDay = Dictionary(grouping: predictions.filter { $0.type == "L" }) { prediction in
            calendar.startOfDay(for: prediction.parsedTime)
        }
        
        // Evaluate each day
        for (date, dayPredictions) in groupedByDay.sorted(by: { $0.key < $1.key }) {
            guard let lowestTide = dayPredictions.min(by: { 
                (Double($0.v) ?? 999) < (Double($1.v) ?? 999) 
            }) else { continue }
            
            let tideHeight = Double(lowestTide.v) ?? 0
            
            let tidePrediction = TidePrediction(
                time: lowestTide.parsedTime,
                height: tideHeight,
                type: .low,
                isRising: false
            )
            
            // Determine rating based on lowest tide
            let rating: TidePoolConditions.TidePoolRating
            if tideHeight < -1.0 {
                rating = .excellent
            } else if tideHeight < 0.5 {
                rating = .good
            } else if tideHeight < 1.5 {
                rating = .fair
            } else {
                rating = .poor
            }
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeStr = formatter.string(from: lowestTide.parsedTime)
            let bestTime = "\(timeStr) (\(String(format: "%.1f", tideHeight)) ft)"
            
            dailyForecasts.append(DayForecast(
                date: date,
                bestLowTide: tidePrediction,
                rating: rating,
                bestTime: bestTime
            ))
        }
        
        // Find best days (excellent or good ratings)
        let bestDays = dailyForecasts.filter { $0.rating == .excellent || $0.rating == .good }
            .prefix(3)
            .map { $0 }
        
        return WeeklyTidePoolForecast(
            forecasts: Array(dailyForecasts.prefix(7)),
            bestDays: bestDays
        )
    }
}

struct EnhancedTidePoolCard: View {
    let conditions: TidePoolConditions
    @State private var weeklyForecast: WeeklyTidePoolForecast?
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var isLoadingForecast = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card (always visible)
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    if isExpanded && weeklyForecast == nil {
                        loadWeeklyForecast()
                    }
                }
            }) {
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
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
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
                                Text("Next Low")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Text(conditions.bestTimeWindow)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        Spacer()
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
                        Text("Tap to see 7-day forecast")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Weekly forecast (expandable section)
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 8) {
                    if isLoadingForecast {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading 7-day forecast...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let forecast = weeklyForecast {
                        // Best upcoming days highlight
                        if !forecast.bestDays.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🌊 Best Upcoming Days")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.teal)
                                
                                ForEach(forecast.bestDays) { day in
                                    HStack {
                                        Text(day.dayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        Text(day.rating.emoji)
                                            .font(.caption2)
                                        
                                        Text(day.bestTime)
                                            .font(.caption2)
                                            .foregroundColor(.cyan)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.teal.opacity(0.1))
                            )
                        }
                        
                        // 7-day overview
                        VStack(alignment: .leading, spacing: 3) {
                            Text("7-Day Forecast")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack(spacing: 8) {
                                ForEach(forecast.forecasts) { day in
                                    VStack(spacing: 2) {
                                        Text(String(day.dayName.prefix(3)))
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Text(day.rating.emoji)
                                            .font(.caption2)
                                        
                                        if let tide = day.bestLowTide {
                                            Text(String(format: "%.1f", tide.height))
                                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                                .foregroundColor(tide.height < 0 ? .purple : .white.opacity(0.8))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    } else {
                        Text("Unable to load forecast")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 8)
                    }
                }
                .padding(12)
                .padding(.top, -8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    var backgroundGradient: LinearGradient {
        if conditions.isOptimalTime {
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
    
    func loadWeeklyForecast() {
        isLoadingForecast = true
        
        Task {
            do {
                let service = TideDataService()
                let predictions = try await service.fetchWeeklyPredictions()
                let forecast = WeeklyTidePoolForecast.generate(from: predictions)
                
                await MainActor.run {
                    self.weeklyForecast = forecast
                    self.isLoadingForecast = false
                }
            } catch {
                print("Failed to load weekly forecast: \(error)")
                await MainActor.run {
                    self.isLoadingForecast = false
                }
            }
        }
    }
}