import Foundation
import WidgetKit

class SharedDataStorage {
    static let shared = SharedDataStorage()
    
    private let appGroupIdentifier = "group.com.weilandia.mytidesapp"
    private let tideDataKey = "cached_tide_data"
    private let spotConditionsKey = "cached_spot_conditions"
    private let lastUpdatedKey = "last_updated"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // Save tide data to shared storage
    func saveTideData(_ tideData: TideData, spotConditions: [String: SpotConditions]? = nil) {
        guard let sharedDefaults = sharedDefaults else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        do {
            // Encode tide data
            let encoder = JSONEncoder()
            let tideDataEncoded = try encoder.encode(tideData)
            sharedDefaults.set(tideDataEncoded, forKey: tideDataKey)
            
            // Encode spot conditions if available
            if let spotConditions = spotConditions {
                let spotConditionsEncoded = try encoder.encode(spotConditions)
                sharedDefaults.set(spotConditionsEncoded, forKey: spotConditionsKey)
            }
            
            // Save timestamp
            sharedDefaults.set(Date(), forKey: lastUpdatedKey)
            
            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
            
            print("SharedDataStorage: Saved tide data and triggered widget refresh")
        } catch {
            print("SharedDataStorage: Failed to encode data: \(error)")
        }
    }
    
    // Load tide data from shared storage
    func loadTideData() -> (tideData: TideData?, spotConditions: [String: SpotConditions]?, lastUpdated: Date?) {
        guard let sharedDefaults = sharedDefaults else {
            print("Failed to access shared UserDefaults")
            return (nil, nil, nil)
        }
        
        let decoder = JSONDecoder()
        
        // Decode tide data
        var tideData: TideData?
        if let tideDataEncoded = sharedDefaults.data(forKey: tideDataKey) {
            do {
                tideData = try decoder.decode(TideData.self, from: tideDataEncoded)
            } catch {
                print("SharedDataStorage: Failed to decode tide data: \(error)")
            }
        }
        
        // Decode spot conditions
        var spotConditions: [String: SpotConditions]?
        if let spotConditionsEncoded = sharedDefaults.data(forKey: spotConditionsKey) {
            do {
                spotConditions = try decoder.decode([String: SpotConditions].self, from: spotConditionsEncoded)
            } catch {
                print("SharedDataStorage: Failed to decode spot conditions: \(error)")
            }
        }
        
        // Get last updated time
        let lastUpdated = sharedDefaults.object(forKey: lastUpdatedKey) as? Date
        
        return (tideData, spotConditions, lastUpdated)
    }
    
    // Check if cached data is still fresh (less than 5 minutes old)
    func isCachedDataFresh() -> Bool {
        guard let sharedDefaults = sharedDefaults,
              let lastUpdated = sharedDefaults.object(forKey: lastUpdatedKey) as? Date else {
            return false
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdated)
        return timeSinceUpdate < 300 // 5 minutes
    }
    
    // Clear cached data
    func clearCache() {
        guard let sharedDefaults = sharedDefaults else { return }
        
        sharedDefaults.removeObject(forKey: tideDataKey)
        sharedDefaults.removeObject(forKey: spotConditionsKey)
        sharedDefaults.removeObject(forKey: lastUpdatedKey)
    }
}