import Foundation

class SurflineService: ObservableObject {
    @Published var spotData: [String: WaveData] = [:]  // Store data for multiple spots
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Surfline API endpoints (v2)
    private let baseURL = "https://services.surfline.com/kbyg/spots/forecasts"
    
    func fetchAllSpotsData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Fetch data for all configured spots
        await withTaskGroup(of: (String, WaveData?).self) { group in
            for spot in AppConfig.surflineSpots {
                group.addTask {
                    let data = await self.fetchSpotData(spot: spot)
                    return (spot.id, data)
                }
            }
            
            // Collect results
            var results: [String: WaveData] = [:]
            for await (spotId, data) in group {
                if let data = data {
                    results[spotId] = data
                }
            }
            
            let finalResults = results
            await MainActor.run {
                self.spotData = finalResults
                self.isLoading = false
            }
        }
    }
    
    func fetchSpotData(spot: SurflineSpot) async -> WaveData? {
        let urlString = spot.surflineURL
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "Invalid URL for \(spot.name)"
            }
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    print("Surfline API authentication issue for \(spot.name)")
                    return nil
                }
            }
            
            let waveResponse = try JSONDecoder().decode(SurflineWaveResponse.self, from: data)
            return processWaveData(waveResponse, spotName: spot.name)
        } catch {
            print("Failed to fetch data for \(spot.name): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func processWaveData(_ response: SurflineWaveResponse, spotName: String) -> WaveData {
        guard let firstWave = response.data?.wave?.first else {
            return WaveData.placeholder(spotName: spotName)
        }
        
        let surf = firstWave.surf
        return WaveData(
            spotName: spotName,
            waveHeightMin: surf?.min ?? 0,
            waveHeightMax: surf?.max ?? 0,
            waveHeightOptimal: surf?.optimalScore ?? 0,
            period: firstWave.swells?.first?.period ?? 0,
            direction: firstWave.swells?.first?.direction ?? 0,
            directionCompass: compassDirection(from: firstWave.swells?.first?.direction ?? 0),
            humanRelation: surf?.humanRelation ?? "Waist to chest high",
            timestamp: Date()
        )
    }
    
    private func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - Wave Data Models

struct WaveData {
    let spotName: String
    let waveHeightMin: Double  // in feet
    let waveHeightMax: Double  // in feet
    let waveHeightOptimal: Double  // 0-10 score
    let period: Int  // in seconds
    let direction: Double  // in degrees
    let directionCompass: String  // e.g., "NW"
    let humanRelation: String  // e.g., "Waist to chest high"
    let timestamp: Date
    
    static func placeholder(spotName: String = "Unknown") -> WaveData {
        WaveData(
            spotName: spotName,
            waveHeightMin: 2,
            waveHeightMax: 4,
            waveHeightOptimal: 5,
            period: 11,
            direction: 290,
            directionCompass: "WNW",
            humanRelation: "Waist to chest high",
            timestamp: Date()
        )
    }
}

// MARK: - Surfline API Response Models

struct SurflineWaveResponse: Codable {
    let data: SurflineData?
}

struct SurflineData: Codable {
    let wave: [WaveDataPoint]?
}

struct WaveDataPoint: Codable {
    let timestamp: Int
    let surf: SurfData?
    let swells: [SwellData]?
}

struct SurfData: Codable {
    let min: Double?
    let max: Double?
    let optimalScore: Double?
    let humanRelation: String?
}

struct SwellData: Codable {
    let height: Double?
    let period: Int?
    let direction: Double?
    let directionMin: Double?
    let optimalScore: Double?
}