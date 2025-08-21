import Foundation

struct ConfigService {
    static var surflineApiKey: String? {
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["SURFLINE_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }
        
        // Check config file in user's home directory
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let configURL = homeURL.appendingPathComponent(".santacruz-tides/config.json")
        
        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                let config = try JSONDecoder().decode(Config.self, from: data)
                return config.surflineApiKey
            } catch {
                print("Failed to read config file: \(error)")
            }
        }
        
        // Check local config file
        if let configPath = Bundle.main.path(forResource: "config", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
                let config = try JSONDecoder().decode(Config.self, from: data)
                return config.surflineApiKey
            } catch {
                print("Failed to read local config: \(error)")
            }
        }
        
        return nil
    }
    
    private struct Config: Codable {
        let surflineApiKey: String?
        
        enum CodingKeys: String, CodingKey {
            case surflineApiKey = "surfline_api_key"
        }
    }
}