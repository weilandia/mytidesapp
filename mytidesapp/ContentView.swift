//
//  ContentView.swift
//  mytidesapp
//
//  Created by Nick Weiland on 8/21/25.
//

import SwiftUI
import WidgetKit
import Foundation

struct ContentView: View {
    @StateObject private var surflineService = EnhancedSurflineService()
    @State private var tideData: TideData?
    @State private var isLoading = true
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Loading tide data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let data = tideData {
                // Header
                HStack {
                    Text("MyTides")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { Task { await refreshData() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding()
                
                // Current Tide
                CurrentTideCard(tideData: data)
                    .padding(.horizontal)
                
                // Tide Chart
                if !data.hourlyPredictions.isEmpty {
                    TideChartView(predictions: data.hourlyPredictions)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                
                // Surf Spots
                VStack(alignment: .leading, spacing: 10) {
                    Text("Surf Conditions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(AppConfig.surflineSpots.prefix(2), id: \.id) { spot in
                        if let conditions = surflineService.spotConditions[spot.id] {
                            SimpleSurfSpotCard(spot: spot, conditions: conditions)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            } else {
                Text("Failed to load tide data")
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .task {
            await refreshData()
        }
        .onReceive(timer) { _ in
            Task {
                await refreshData()
            }
        }
    }
    
    func refreshData() async {
        isLoading = true
        await surflineService.fetchAllSpotsData()
        tideData = await convertSurflineTideData()
        
        // Save to shared storage for widget
        if let tideData = tideData {
            SharedDataStorage.shared.saveTideData(tideData, spotConditions: surflineService.spotConditions)
        }
        
        isLoading = false
    }
    
    func convertSurflineTideData() async -> TideData? {
        guard let pleasurePointId = AppConfig.surflineSpots.first(where: { $0.displayName == "Pleasure Point" })?.id,
              let spotConditions = surflineService.spotConditions[pleasurePointId],
              let surflineTides = spotConditions.tideData else {
            return nil
        }
        
        let now = Date()
        let sortedTides = surflineTides.all.sorted { tide1, tide2 in
            let time1 = Date(timeIntervalSince1970: TimeInterval(tide1.timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(tide2.timestamp ?? 0))
            return time1 < time2
        }
        
        var currentHeight = 0.0
        var isRising = true
        
        for i in 0..<sortedTides.count - 1 {
            let time1 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i].timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i+1].timestamp ?? 0))
            
            if now >= time1 && now <= time2 {
                let height1 = sortedTides[i].height ?? 0
                let height2 = sortedTides[i+1].height ?? 0
                let progress = now.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                currentHeight = height1 + (height2 - height1) * progress
                isRising = height2 > height1
                break
            }
        }
        
        let upcomingTides = sortedTides.compactMap { tide -> TidePrediction? in
            guard let timestamp = tide.timestamp,
                  let height = tide.height,
                  let type = tide.type,
                  (type == "HIGH" || type == "LOW") else { return nil }
            
            let time = Date(timeIntervalSince1970: TimeInterval(timestamp))
            guard time > now else { return nil }
            
            return TidePrediction(
                time: time,
                height: height,
                type: type == "HIGH" ? .high : .low,
                isRising: type == "LOW"
            )
        }.prefix(4).map { $0 }
        
        var hourlyPredictions: [TidePrediction] = []
        for hourOffset in 0..<24 {
            let hourTime = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            var interpolatedHeight = currentHeight
            var interpolatedRising = isRising
            
            for i in 0..<sortedTides.count - 1 {
                let time1 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i].timestamp ?? 0))
                let time2 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i+1].timestamp ?? 0))
                
                if hourTime >= time1 && hourTime <= time2 {
                    let height1 = sortedTides[i].height ?? 0
                    let height2 = sortedTides[i+1].height ?? 0
                    let progress = hourTime.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                    interpolatedHeight = height1 + (height2 - height1) * progress
                    interpolatedRising = height2 > height1
                    break
                }
            }
            
            hourlyPredictions.append(TidePrediction(
                time: hourTime,
                height: interpolatedHeight,
                type: interpolatedRising ? .rising : .falling,
                isRising: interpolatedRising
            ))
        }
        
        return TideData(
            currentTide: TidePrediction(
                time: now,
                height: currentHeight,
                type: isRising ? .rising : .falling,
                isRising: isRising
            ),
            nextTides: upcomingTides,
            hourlyPredictions: hourlyPredictions,
            pleasurePointCondition: SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading",
                spot: .pleasurePoint
            ),
            twentySixthCondition: SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading",
                spot: .twentySixthAve
            ),
            waveData: nil,
            lastUpdated: now
        )
    }
}

struct CurrentTideCard: View {
    let tideData: TideData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text("\(tideData.currentTide.height, specifier: "%.1f") ft")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(tideData.currentTide.isRising ? "Rising" : "Falling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let nextTide = tideData.nextTides.first {
                    VStack(alignment: .trailing) {
                        Text("Next \(nextTide.type == .high ? "High" : "Low")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(nextTide.time.formatted(.dateTime.hour().minute()))
                            .font(.callout)
                            .fontWeight(.medium)
                        Text("\(nextTide.height, specifier: "%.1f") ft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SimpleSurfSpotCard: View {
    let spot: SurflineSpot
    let conditions: SpotConditions
    
    var ratingColor: Color {
        if conditions.rating.value >= 4 { return .green }
        if conditions.rating.value >= 3 { return .yellow }
        if conditions.rating.value >= 2 { return .orange }
        return .red
    }
    
    var body: some View {
        Button(action: {
            if let url = URL(string: spot.surflineCamURL) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(spot.displayName)
                            .font(.headline)
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text(conditions.rating.text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < Int(conditions.rating.value) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(ratingColor)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ContentView()
}
