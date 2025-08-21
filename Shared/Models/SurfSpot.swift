import Foundation

enum SurfSpot: String, CaseIterable {
    case pleasurePoint = "Pleasure Point"
    case twentySixthAve = "26th Avenue"
    case steamerLane = "Steamer Lane"
    case capitola = "Capitola"
    
    var optimalTideRange: ClosedRange<Double> {
        switch self {
        case .pleasurePoint:
            // Pleasure Point works best on low to mid tide
            return 0.5...3.5
        case .twentySixthAve:
            // 26th Ave also best on low to mid tide
            return 0.5...3.5
        case .steamerLane:
            // Steamer Lane can handle lower tides
            return 1.5...4.5
        case .capitola:
            // Capitola needs medium tide
            return 2.0...4.5
        }
    }
    
    var icon: String {
        switch self {
        case .pleasurePoint: return "🏄"
        case .twentySixthAve: return "🌊"
        case .steamerLane: return "🏄‍♂️"
        case .capitola: return "🏖️"
        }
    }
    
    func evaluateSurfConditions(tideHeight: Double, isRising: Bool, tideType: String?) -> SurfCondition {
        let optimalRange = self.optimalTideRange
        
        var quality: SurfQuality
        var reason: String
        
        switch self {
        case .pleasurePoint:
            // Best on low to mid tide RISING (0.5 - 3.5 ft)
            if optimalRange.contains(tideHeight) && isRising {
                quality = .excellent
                reason = "Perfect low-mid rising tide!"
            } else if optimalRange.contains(tideHeight) && !isRising {
                quality = .good
                reason = "Good low-mid tide (better on rising)"
            } else if tideHeight < optimalRange.lowerBound {
                if tideHeight < 0 {
                    quality = .poor
                    reason = "Too shallow, exposed rocks"
                } else {
                    quality = .fair
                    reason = "Very low, getting shallow"
                }
            } else if tideHeight > 4.5 {
                quality = .poor
                reason = "Too high, closes out"
            } else {
                quality = .fair
                reason = "Higher tide, not ideal"
            }
            
        case .twentySixthAve:
            // Also best on low to mid tide rising
            if optimalRange.contains(tideHeight) && isRising {
                quality = .excellent
                reason = "Firing on low-mid rising!"
            } else if optimalRange.contains(tideHeight) && !isRising {
                quality = .good
                reason = "Good low-mid (better on rising)"
            } else if tideHeight < 0.5 {
                if tideHeight < 0 {
                    quality = .poor
                    reason = "Way too shallow, rocky"
                } else {
                    quality = .fair
                    reason = "Very low, watch the rocks"
                }
            } else if tideHeight > 4.5 {
                quality = .poor
                reason = "Too high, closes out"
            } else {
                quality = .fair
                reason = "Outside optimal range"
            }
            
        case .steamerLane:
            if optimalRange.contains(tideHeight) {
                quality = isRising ? .excellent : .good
                reason = isRising ? "Classic Steamer Lane conditions!" : "Good waves at the Lane"
            } else if tideHeight < 1.0 {
                quality = .poor
                reason = "Too low, kelp and rocks"
            } else {
                quality = .fair
                reason = tideHeight > 5.0 ? "High tide mushburgers" : "Workable but not ideal"
            }
            
        case .capitola:
            if optimalRange.contains(tideHeight) && !isRising {
                quality = .good
                reason = "Fun waves at Capitola"
            } else if optimalRange.contains(tideHeight) {
                quality = .fair
                reason = "Decent conditions"
            } else {
                quality = .poor
                reason = tideHeight < 2.0 ? "Too shallow" : "Closed out"
            }
        }
        
        return SurfCondition(
            quality: quality,
            tideHeight: tideHeight,
            time: Date(),
            reason: reason,
            spot: self
        )
    }
}

enum SurfQuality {
    case excellent
    case good  
    case fair
    case poor
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🔥"
        case .good: return "👍"
        case .fair: return "🤔"
        case .poor: return "❌"
        }
    }
}

struct SurfCondition {
    let quality: SurfQuality
    let tideHeight: Double
    let time: Date
    let reason: String
    let spot: SurfSpot
}