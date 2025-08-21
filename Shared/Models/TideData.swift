import Foundation

struct TideData {
    let currentTide: TidePrediction
    let nextTides: [TidePrediction]
    let hourlyPredictions: [TidePrediction]  // For tide chart
    let pleasurePointCondition: SurfCondition
    let twentySixthCondition: SurfCondition
    let waveData: WaveData?
    let lastUpdated: Date
    
    static var placeholder: TideData {
        let now = Date()
        let current = TidePrediction(
            time: now,
            height: 3.5,
            type: .high,
            isRising: true
        )
        
        let next = [
            TidePrediction(time: now.addingTimeInterval(3600 * 6), height: 0.5, type: .low, isRising: false),
            TidePrediction(time: now.addingTimeInterval(3600 * 12), height: 5.2, type: .high, isRising: true)
        ]
        
        return TideData(
            currentTide: current,
            nextTides: next,
            hourlyPredictions: [],
            pleasurePointCondition: SurfCondition(
                quality: .excellent,
                tideHeight: 3.5,
                time: now,
                reason: "Perfect conditions!",
                spot: .pleasurePoint
            ),
            twentySixthCondition: SurfCondition(
                quality: .good,
                tideHeight: 3.5,
                time: now,
                reason: "Good shape",
                spot: .twentySixthAve
            ),
            waveData: nil,
            lastUpdated: now
        )
    }
}

struct TidePrediction: Identifiable {
    let id = UUID()
    
    let time: Date
    let height: Double
    let type: TideType
    let isRising: Bool
    
    var isNegative: Bool {
        height < 0
    }
    
    var shouldShowTidePoolAlert: Bool {
        // Show alert for negative tides during reasonable hours
        guard isNegative else { return false }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        // Show during daylight hours (6am to 8pm)
        return hour >= 6 && hour <= 20
    }
    
    var tidePoolMessage: String? {
        guard shouldShowTidePoolAlert else { return nil }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        if hour >= 6 && hour <= 10 {
            return "Perfect morning tide pools! 🌅"
        } else if hour >= 16 && hour <= 20 {
            return "Great evening tide pools! 🌅"
        } else {
            return "Excellent tide pool conditions! ⭐"
        }
    }
    
    enum TideType {
        case high
        case low
        case rising
        case falling
    }
}