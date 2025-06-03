//
//  KeepMeHealthyApp.swift
//  KeepMeHealthy
//
//  Created by Longde Lao on 01.06.25.
//

import SwiftUI
import GRDB

@main
struct KeepMeHealthyApp: App {
    // Create a shared instance of the view model
    @StateObject private var productViewModel = ProductViewModel()
    
    // Development mode flag - set to false for production
    private let isDevMode = false
    
    // Initialize the database
    init() {
        print("🔵 App initializing...")
        
        // Only reset database in development mode or if explicitly requested
        if isDevMode || CommandLine.arguments.contains("-reset-database") || UserDefaults.standard.bool(forKey: "reset_database_on_launch") {
            print("🔄 Development mode: Resetting database...")
            resetDatabase()
            UserDefaults.standard.set(false, forKey: "reset_database_on_launch")
        } else {
            print("💾 Production mode: Using persistent database")
        }
        
        // Initialize the database manager
        do {
            // Ensure the DatabaseManager is initialized at app startup
            _ = DatabaseManager.shared
        } catch {
            print("❌ Database initialization error: \(error.localizedDescription)")
            
            // If there's an error, set flag to reset database on next launch
            UserDefaults.standard.set(true, forKey: "reset_database_on_launch")
        }
    }
    
    private func resetDatabase() {
        print("🗑️ Resetting database...")
        
        do {
            // Get the database file URL
            let fileManager = FileManager.default
            let folderURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("Database", isDirectory: true)
            
            let dbURL = folderURL.appendingPathComponent("keepmehealthy.sqlite")
            
            // Check if database file exists and delete it
            if fileManager.fileExists(atPath: dbURL.path) {
                try fileManager.removeItem(at: dbURL)
                print("✅ Database deleted successfully")
            } else {
                print("ℹ️ No database file found to delete")
            }
        } catch {
            print("❌ Error resetting database: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ScanItemView()
                .environmentObject(productViewModel) // Make the view model available to all views
        }
    }
}
