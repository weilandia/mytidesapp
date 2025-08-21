import Foundation

class EnhancedSurflineService: ObservableObject {
    @Published var spotConditions: [String: SpotConditions] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchAllSpotsData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Fetch data for all configured spots in parallel
        await withTaskGroup(of: (String, SpotConditions?).self) { group in
            for spot in AppConfig.surflineSpots {
                group.addTask {
                    let conditions = await self.fetchSpotConditions(spot: spot)
                    return (spot.id, conditions)
                }
            }
            
            // Collect results
            var results: [String: SpotConditions] = [:]
            for await (spotId, conditions) in group {
                if let conditions = conditions {
                    results[spotId] = conditions
                }
            }
            
            let finalResults = results
            await MainActor.run {
                self.spotConditions = finalResults
                self.isLoading = false
            }
        }
    }
    
    private func fetchSpotConditions(spot: SurflineSpot) async -> SpotConditions? {
        print("Fetching conditions for \(spot.name) (ID: \(spot.id))")
        
        async let waveData = fetchWaveData(spotId: spot.id)
        async let windData = fetchWindData(spotId: spot.id)
        async let ratingData = fetchRatingData(spotId: spot.id)
        async let tideData = fetchTideData(spotId: spot.id)
        
        let (wave, wind, rating, tide) = await (waveData, windData, ratingData, tideData)
        
        guard let waveInfo = wave else { 
            print("No wave data for \(spot.name)")
            return nil 
        }
        
        // Debug tide data
        if let tideData = tide {
            print("DEBUG Surfline Tides for \(spot.name):")
            for (index, upcoming) in tideData.upcoming.prefix(3).enumerated() {
                if let timestamp = upcoming.timestamp,
                   let height = upcoming.height,
                   let type = upcoming.type {
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, h:mm a zzz"
                    formatter.timeZone = TimeZone.current
                    print("  Tide[\(index)]: \(formatter.string(from: date)), Height=\(String(format: "%.1f", height))ft, Type=\(type)")
                }
            }
        }
        
        return SpotConditions(
            spot: spot,
            waveHeight: waveInfo.waveHeight,
            waveDescription: waveInfo.description,
            period: waveInfo.period,
            direction: waveInfo.direction,
            windSpeed: wind?.speed ?? 0,
            windDirection: wind?.direction ?? "N",
            windAngle: wind?.angle ?? 0,
            rating: rating ?? SurflineRating.placeholder,
            timestamp: Date(),
            tideData: tide
        )
    }
    
    private func fetchWaveData(spotId: String) async -> (waveHeight: String, description: String, period: Int, direction: String)? {
        let urlString = "https://services.surfline.com/kbyg/spots/forecasts/wave?spotId=\(spotId)&days=1&intervalHours=1"
        
        guard let url = URL(string: urlString),
              let data = try? await fetchData(from: url) else { return nil }
        
        do {
            let response = try JSONDecoder().decode(SurflineWaveResponse.self, from: data)
            guard let firstWave = response.data?.wave?.first else { return nil }
            
            let surf = firstWave.surf
            let min = Int(surf?.min ?? 0)
            let max = Int(surf?.max ?? 0)
            let waveHeight = min == max ? "\(max)ft" : "\(min)-\(max)ft"
            
            return (
                waveHeight: waveHeight,
                description: surf?.humanRelation ?? "Waist high",
                period: firstWave.swells?.first?.period ?? 10,
                direction: compassDirection(from: firstWave.swells?.first?.direction ?? 0)
            )
        } catch {
            print("Failed to parse wave data: \(error)")
            return nil
        }
    }
    
    private func fetchWindData(spotId: String) async -> (speed: Int, direction: String, angle: Double)? {
        let urlString = "https://services.surfline.com/kbyg/spots/forecasts/wind?spotId=\(spotId)&days=1&intervalHours=1"
        
        guard let url = URL(string: urlString),
              let data = try? await fetchData(from: url) else { return nil }
        
        do {
            let response = try JSONDecoder().decode(SurflineWindResponse.self, from: data)
            guard let firstWind = response.data?.wind?.first else { return nil }
            
            return (
                speed: Int(firstWind.speed ?? 0),
                direction: compassDirection(from: firstWind.direction ?? 0),
                angle: firstWind.direction ?? 0
            )
        } catch {
            print("Failed to parse wind data: \(error)")
            return nil
        }
    }
    
    private func fetchRatingData(spotId: String) async -> SurflineRating? {
        let urlString = "https://services.surfline.com/kbyg/spots/forecasts/rating?spotId=\(spotId)&days=1&intervalHours=1"
        
        guard let url = URL(string: urlString),
              let data = try? await fetchData(from: url) else { 
            print("Failed to fetch rating for spot \(spotId)")
            return nil 
        }
        
        do {
            let response = try JSONDecoder().decode(SurflineRatingResponse.self, from: data)
            guard let firstRating = response.data?.rating?.first else { 
                return nil 
            }
            
            let value = firstRating.rating?.value ?? 0
            let text = ratingText(from: value)
            
            return SurflineRating(
                value: value,
                text: text
            )
        } catch {
            return SurflineRating.placeholder
        }
    }
    
    private func fetchTideData(spotId: String) async -> SurflineTideData? {
        let urlString = "https://services.surfline.com/kbyg/spots/forecasts/tides?spotId=\(spotId)&days=3"
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let data = try await fetchData(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(SurflineTideResponse.self, from: data)
            
            guard let tides = response.data?.tides,
                  !tides.isEmpty else {
                print("No tide data in response")
                return nil
            }
            
            // Process tide data
            let currentTide = tides.first { tide in
                guard let timestamp = tide.timestamp else { return false }
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                return abs(date.timeIntervalSinceNow) < 1800 // Within 30 minutes
            }
            
            let nextTides = tides.filter { tide in
                guard let timestamp = tide.timestamp else { return false }
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                return date > Date() && (tide.type == "HIGH" || tide.type == "LOW")
            }.prefix(4)
            
            return SurflineTideData(
                current: currentTide,
                upcoming: Array(nextTides),
                all: tides
            )
        } catch {
            print("Failed to fetch/parse tide data for \(spotId): \(error)")
            return nil
        }
    }
    
    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    private func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    private func ratingText(from value: Double) -> String {
        switch value {
        case 0..<0.5: return "FLAT"
        case 0.5..<1: return "VERY POOR"
        case 1..<1.5: return "POOR"
        case 1.5..<2: return "POOR to FAIR"
        case 2..<3: return "FAIR"
        case 3..<4: return "FAIR to GOOD"
        case 4..<5: return "GOOD"
        case 5...: return "EPIC"
        default: return "UNKNOWN"
        }
    }
}

// MARK: - Data Models

struct SpotConditions {
    let spot: SurflineSpot
    let waveHeight: String
    let waveDescription: String
    let period: Int
    let direction: String
    let windSpeed: Int
    let windDirection: String
    let windAngle: Double
    let rating: SurflineRating
    let timestamp: Date
    let tideData: SurflineTideData?
    
    var qualityEmoji: String {
        switch rating.value {
        case 0..<1: return "❌"
        case 1..<2: return "⚠️"
        case 2..<3: return "🤔"
        case 3..<4: return "👍"
        case 4..<5: return "🔥"
        case 5...: return "🤯"
        default: return "❓"
        }
    }
    
    var isOffshore: Bool {
        // Check if wind is offshore based on angle
        // This is simplified - you'd want to configure based on beach orientation
        let offshoreRange = 45.0...135.0  // East-facing beach example
        return offshoreRange.contains(windAngle)
    }
    
    var windIcon: String {
        if isOffshore {
            return "🌬️✅"  // Offshore
        } else if windSpeed < 5 {
            return "🍃"  // Light wind
        } else if windSpeed < 15 {
            return "💨"  // Moderate
        } else {
            return "🌪️"  // Strong onshore
        }
    }
}

struct SurflineRating {
    let value: Double  // 0-5 scale
    let text: String
    
    static let placeholder = SurflineRating(value: 2, text: "FAIR")
}

// MARK: - API Response Models

struct SurflineWindResponse: Codable {
    let data: WindData?
    
    struct WindData: Codable {
        let wind: [WindPoint]?
    }
    
    struct WindPoint: Codable {
        let timestamp: Int
        let speed: Double?
        let direction: Double?
        let gust: Double?
    }
}

struct SurflineRatingResponse: Codable {
    let data: RatingData?
    
    struct RatingData: Codable {
        let rating: [RatingPoint]?
    }
    
    struct RatingPoint: Codable {
        let timestamp: Int
        let rating: Rating?
    }
    
    struct Rating: Codable {
        let value: Double?
        let key: String?
    }
}

// MARK: - Surfline Tide Data

struct SurflineTideResponse: Codable {
    let data: SurflineTideContainer?
}

struct SurflineTideContainer: Codable {
    let tides: [SurflineTide]?
}

struct SurflineTide: Codable {
    let timestamp: Int?
    let type: String?  // "HIGH", "LOW", "NORMAL"
    let height: Double?
}

struct SurflineTideData {
    let current: SurflineTide?
    let upcoming: [SurflineTide]
    let all: [SurflineTide]
}