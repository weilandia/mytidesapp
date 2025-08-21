import Foundation

// MARK: - Main Configuration
// Fork this repo? Edit this file to customize for your location!

struct AppConfig {
    // MARK: - Location Settings
    static let locationName = "Santa Cruz, CA"
    static let timezone = "America/Los_Angeles"
    
    // MARK: - NOAA Tide Station
    // Find your station at: https://tidesandcurrents.noaa.gov/map/
    static let noaaStationId = "9413745" // Santa Cruz Wharf
    static let noaaStationName = "Monterey Bay"
    
    // MARK: - Surfline Spots
    // To add your spots:
    // 1. Go to Surfline.com and find your spot
    // 2. Copy the URL (e.g., https://www.surfline.com/surf-report/pleasure-point/5842041f4e65fad6a7708807)
    // 3. Extract the spot ID (the last part: 5842041f4e65fad6a7708807)
    // 4. Add it to the array below
    
    static let surflineSpots: [SurflineSpot] = [
        SurflineSpot(
            id: "5842041f4e65fad6a7708807",
            name: "Pleasure Point",
            displayName: "Pleasure Point",
            optimalTideRange: 0.0...3.5,
            optimalDirection: .rising,
            description: "Best on low to mid tide rising"
        ),
        SurflineSpot(
            id: "5842041f4e65fad6a770898a",  // Correct ID from Surfline URL
            name: "26th Avenue",
            displayName: "26th Ave",
            optimalTideRange: 0.0...3.5,
            optimalDirection: .rising,
            description: "Best on low to mid tide rising"
        ),
        // Add more spots here:
        // SurflineSpot(
        //     id: "YOUR_SPOT_ID",
        //     name: "Spot Name",
        //     displayName: "Display Name",
        //     optimalTideRange: 1.0...4.0,
        //     optimalDirection: .rising,
        //     description: "When it works best"
        // ),
    ]
    
    // MARK: - Tide Pool Settings
    static let tidePoolConfig = TidePoolConfig(
        enabled: true,
        negativeThreshold: 0.0, // Show tide pools when tide is below this
        dayTimeStart: 8, // Hour (24h format) when tide pooling starts being good
        dayTimeEnd: 18, // Hour when sunset typically occurs (adjust seasonally)
        moonPhaseEnabled: true // Consider moon phase for night tide pooling
    )
    
    // MARK: - Display Settings
    static let displayConfig = DisplayConfig(
        temperatureUnit: TemperatureUnit.fahrenheit,
        heightUnit: HeightUnit.feet,
        speedUnit: SpeedUnit.mph,
        hourFormat: HourFormat.twelveHour,
        updateIntervalMinutes: 60
    )
    
    // MARK: - Widget Appearance
    static let theme = ThemeConfig(
        primaryColor: "blue", // blue, green, purple, orange
        accentColor: "cyan",
        showWeatherData: true,
        showWindData: true,
        showSwellData: true,
        compactMode: false
    )
}

// MARK: - Supporting Types

struct SurflineSpot {
    let id: String
    let name: String
    let displayName: String
    let optimalTideRange: ClosedRange<Double>
    let optimalDirection: TideDirection
    let description: String
    
    enum TideDirection {
        case rising
        case falling
        case any
    }
    
    var surflineURL: String {
        "https://services.surfline.com/kbyg/spots/forecasts/wave?spotId=\(id)&days=2&intervalHours=1"
    }
    
    var surflineWebURL: String {
        "https://www.surfline.com/surf-report/\(name.lowercased().replacingOccurrences(of: " ", with: "-"))/\(id)"
    }
}

struct TidePoolConfig {
    let enabled: Bool
    let negativeThreshold: Double
    let dayTimeStart: Int
    let dayTimeEnd: Int
    let moonPhaseEnabled: Bool
}

struct DisplayConfig {
    let temperatureUnit: TemperatureUnit
    let heightUnit: HeightUnit
    let speedUnit: SpeedUnit
    let hourFormat: HourFormat
    let updateIntervalMinutes: Int
}

enum TemperatureUnit {
    case fahrenheit
    case celsius
}

enum HeightUnit {
    case feet
    case meters
}

enum SpeedUnit {
    case mph
    case kph
    case knots
}

enum HourFormat {
    case twelveHour
    case twentyFourHour
}

struct ThemeConfig {
    let primaryColor: String
    let accentColor: String
    let showWeatherData: Bool
    let showWindData: Bool
    let showSwellData: Bool
    let compactMode: Bool
}
