import Foundation

class TideDataService {
    private let stationId = AppConfig.noaaStationId
    private let baseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    private let surflineService = SurflineService()
    
    func fetchCurrentTideData() async -> TideData {
        do {
            // Fetch both hi/lo predictions and continuous data
            let hiLoPredictions = try await fetchHiLoPredictions()
            let continuousPredictions = try await fetchContinuousPredictions()
            let hourlyPredictions = try await fetchHourlyPredictions()
            
            var tideData = processTideData(
                hiLoPredictions: hiLoPredictions,
                continuousPredictions: continuousPredictions,
                hourlyPredictions: hourlyPredictions
            )
            
            // Fetch wave data from all configured Surfline spots
            await surflineService.fetchAllSpotsData()
            
            // Get first spot's wave data for backward compatibility
            let firstSpotData = AppConfig.surflineSpots.first.flatMap { surflineService.spotData[$0.id] }
            
            tideData = TideData(
                currentTide: tideData.currentTide,
                nextTides: tideData.nextTides,
                hourlyPredictions: tideData.hourlyPredictions,
                pleasurePointCondition: tideData.pleasurePointCondition,
                twentySixthCondition: tideData.twentySixthCondition,
                waveData: firstSpotData,
                lastUpdated: tideData.lastUpdated
            )
            
            return tideData
        } catch {
            print("Error fetching tide data: \(error)")
            return TideData.placeholder
        }
    }
    
    // Fetch high/low tide times
    private func fetchHiLoPredictions() async throws -> [NOAAPrediction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone.current  // Use system timezone for request
        
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "begin_date", value: formatter.string(from: today)),
            URLQueryItem(name: "end_date", value: formatter.string(from: endDate)),
            URLQueryItem(name: "station", value: stationId),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "interval", value: "hilo"),  // High/low only
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "units", value: "english")
        ]
        
        guard let url = components.url else {
            throw TideError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NOAAResponse.self, from: data)
        
        // Debug: Print first few predictions
        for (_, pred) in response.predictions.prefix(5).enumerated() {
            let _ = parseTideDate(pred.t)
            let localFormatter = DateFormatter()
            localFormatter.dateFormat = "MMM d, h:mm a zzz"
            localFormatter.timeZone = TimeZone(identifier: AppConfig.timezone)
        }
        
        return response.predictions
    }
    
    // Fetch continuous tide data for current height
    private func fetchContinuousPredictions() async throws -> [NOAAPrediction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm"
        formatter.timeZone = TimeZone.current  // Use system timezone for request
        
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "begin_date", value: formatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: formatter.string(from: endDate)),
            URLQueryItem(name: "station", value: stationId),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "interval", value: "6"),  // 6-minute intervals for accuracy
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "units", value: "english")
        ]
        
        guard let url = components.url else {
            throw TideError.invalidURL
        }
        
        print("Fetching continuous tide from: \(url)")
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NOAAResponse.self, from: data)
        return response.predictions
    }
    
    // Fetch weekly tide predictions for tide pool forecasting
    func fetchWeeklyPredictions() async throws -> [NOAAPrediction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm"
        formatter.timeZone = TimeZone.current  // Use system timezone for request
        
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "begin_date", value: formatter.string(from: now)),
            URLQueryItem(name: "end_date", value: formatter.string(from: endDate)),
            URLQueryItem(name: "station", value: stationId),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "interval", value: "hilo"),  // Just high/low for efficiency
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "units", value: "english")
        ]
        
        guard let url = components.url else {
            throw TideError.invalidURL
        }
        
        print("Fetching weekly tide predictions from: \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NOAAResponse.self, from: data)
        return response.predictions
    }
    
    // Fetch hourly predictions for chart
    private func fetchHourlyPredictions() async throws -> [NOAAPrediction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm"
        formatter.timeZone = TimeZone.current  // Use system timezone for request
        
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: today) ?? today
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "begin_date", value: formatter.string(from: today)),
            URLQueryItem(name: "end_date", value: formatter.string(from: endDate)),
            URLQueryItem(name: "station", value: stationId),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "interval", value: "6"),  // 6-minute intervals
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "units", value: "english")
        ]
        
        guard let url = components.url else {
            throw TideError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NOAAResponse.self, from: data)
        
        // Sample every 10th point (roughly hourly)
        return response.predictions.enumerated().compactMap { index, prediction in
            index % 10 == 0 ? prediction : nil
        }
    }
    
    private func processTideData(
        hiLoPredictions: [NOAAPrediction],
        continuousPredictions: [NOAAPrediction],
        hourlyPredictions: [NOAAPrediction]
    ) -> TideData {
        let now = Date()
        
        // Find the exact current tide height from continuous data
        let currentContinuous = continuousPredictions.min(by: { pred1, pred2 in
            let date1 = parseTideDate(pred1.t) ?? Date.distantFuture
            let date2 = parseTideDate(pred2.t) ?? Date.distantFuture
            return abs(date1.timeIntervalSince(now)) < abs(date2.timeIntervalSince(now))
        })
        
        // Log for debugging
        if let current = currentContinuous {
            print("Current tide at \(current.t): \(current.height) ft")
        }
        
        // Determine if rising or falling by comparing to previous point
        let isRising: Bool = {
            guard let currentIndex = continuousPredictions.firstIndex(where: { $0.t == currentContinuous?.t }),
                  currentIndex > 0 else { return true }
            return continuousPredictions[currentIndex].height > continuousPredictions[currentIndex - 1].height
        }()
        
        // Determine tide type (high/low/rising/falling)
        let tideType: TidePrediction.TideType = {
            if let height = currentContinuous?.height {
                if height > 4.5 { return .high }
                if height < 1.5 { return .low }
                return isRising ? .rising : .falling
            }
            return .rising
        }()
        
        let currentTide = TidePrediction(
            time: parseTideDate(currentContinuous?.t ?? "") ?? now,
            height: currentContinuous?.height ?? 3.0,
            type: tideType,
            isRising: isRising
        )
        
        // Get next hi/lo tides
        let futurePredictions = hiLoPredictions.compactMap { pred -> TidePrediction? in
            guard let date = parseTideDate(pred.t), date > now else { return nil }
            
            return TidePrediction(
                time: date,
                height: pred.height,
                type: pred.type == "H" ? .high : .low,
                isRising: pred.type == "L"  // Low tide means it will rise next
            )
        }
        
        let nextTides = Array(futurePredictions.prefix(4))
        
        // Debug next tides
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "MMM d, h:mm a zzz"
        localFormatter.timeZone = TimeZone(identifier: AppConfig.timezone)
        for (_, _) in nextTides.enumerated() {
        }
        
        // Process hourly predictions for chart
        let hourlyTides = hourlyPredictions.compactMap { pred -> TidePrediction? in
            guard let date = parseTideDate(pred.t) else { return nil }
            return TidePrediction(
                time: date,
                height: pred.height,
                type: pred.height > 3.5 ? .high : pred.height < 1.5 ? .low : .rising,
                isRising: true  // Simplified for chart display
            )
        }
        
        // Calculate surf conditions based on current actual tide
        let pleasurePointCondition = SurfSpot.pleasurePoint.evaluateSurfConditions(
            tideHeight: currentTide.height,
            isRising: currentTide.isRising,
            tideType: nil
        )
        
        let twentySixthCondition = SurfSpot.twentySixthAve.evaluateSurfConditions(
            tideHeight: currentTide.height,
            isRising: currentTide.isRising,
            tideType: nil
        )
        
        return TideData(
            currentTide: currentTide,
            nextTides: nextTides,
            hourlyPredictions: hourlyTides,
            pleasurePointCondition: pleasurePointCondition,
            twentySixthCondition: twentySixthCondition,
            waveData: nil,
            lastUpdated: now
        )
    }
    
    private func parseTideDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        // NOAA returns times in lst_ldt which is already local time
        // We need to parse it without timezone conversion
        formatter.timeZone = TimeZone(identifier: AppConfig.timezone)
        return formatter.date(from: dateString)
    }
}

// NOAA API Response Models
struct NOAAResponse: Codable {
    let predictions: [NOAAPrediction]
}

struct NOAAPrediction: Codable {
    let t: String  // timestamp
    let v: String  // value (as string)
    let type: String?  // "H" for high, "L" for low (only in hi/lo predictions)
    
    var height: Double {
        Double(v) ?? 0
    }
    
    var parsedTime: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        // NOAA returns times in lst_ldt which is already local time
        // We need to parse it without timezone conversion
        formatter.timeZone = TimeZone(identifier: AppConfig.timezone)
        return formatter.date(from: t) ?? Date()
    }
}

enum TideError: Error {
    case invalidURL
    case noData
}