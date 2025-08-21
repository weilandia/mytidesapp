//
//  mytidesappApp.swift
//  mytidesapp
//
//  Created by Nick Weiland on 8/21/25.
//

import SwiftUI

@main
struct mytidesappApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle widget tap - just opening the app is enough
                    print("App opened from widget: \(url)")
                }
        }
    }
}
