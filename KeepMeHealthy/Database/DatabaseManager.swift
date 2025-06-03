import Foundation
import GRDB

/// DatabaseManager handles the setup and access to the SQLite database using GRDB.
class DatabaseManager {
    /// Shared singleton instance
    static let shared = DatabaseManager()
    
    /// The database queue for accessing the database
    private(set) var dbQueue: DatabaseQueue!
    
    /// Error type for database operations
    enum DatabaseError: Error {
        case setupFailed
        case migrationFailed
    }
    
    private init() {
        print("🔵 DatabaseManager: Initializing singleton instance")
        setupDatabase()
    }
    
    /// Sets up the database with initial configuration
    private func setupDatabase() {
        print("🔵 DatabaseManager: Starting database setup")
        do {
            // Create a folder for storing the SQLite database
            let fileManager = FileManager.default
            let folderURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Database", isDirectory: true)
            
            print("🔵 DatabaseManager: Creating database directory at: \(folderURL.path)")
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // Database location
            let dbURL = folderURL.appendingPathComponent("keepmehealthy.sqlite")
            print("🔵 DatabaseManager: Database file path: \(dbURL.path)")
            
            // Check if database already exists
            let dbExists = fileManager.fileExists(atPath: dbURL.path)
            print("🔵 DatabaseManager: Database file already exists: \(dbExists)")
            
            // Database configuration
            var config = Configuration()
            
            // Enable foreign keys
            config.foreignKeysEnabled = true
            print("🔵 DatabaseManager: Configured foreign keys")
            
            // Configure handling of dates and times in the database
            config.prepareDatabase { db in
                print("🔵 DatabaseManager: Preparing database connection")
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }
            
            // Create database queue
            print("🔵 DatabaseManager: Creating database queue")
            dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
            
            // Run migrations
            print("🔵 DatabaseManager: Running migrations")
            try runMigrations()
            
            // Verify tables after migration
            print("🔵 DatabaseManager: Verifying database tables")
            verifyDatabase()
            
            print("✅ DatabaseManager: Database setup successful at: \(dbURL.path)")
        } catch {
            print("❌ DatabaseManager: Database setup failed: \(error)")
            fatalError("Could not setup database: \(error)")
        }
    }
    
    /// Run database migrations to create or update the database schema
    private func runMigrations() throws {
        print("🔵 DatabaseManager: Starting migrations")
        try migrator.migrate(dbQueue)
        print("✅ DatabaseManager: Migrations completed successfully")
    }
    
    /// Migrator that defines the database schema
    private var migrator: DatabaseMigrator {
        print("🔵 DatabaseManager: Creating migrator")
        var migrator = DatabaseMigrator()
        
        // Initial migration to create the tables
        migrator.registerMigration("v1.createInitialSchema") { db in
            print("🔵 DatabaseManager: Running initial schema migration")
            
            print("🔵 DatabaseManager: Creating nutritionFacts table")
            try db.create(table: "nutritionFacts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("servingSize", .text).notNull()
                t.column("calories", .double).notNull()
                t.column("totalFat", .double).notNull()
                t.column("saturatedFat", .double).notNull()
                t.column("transFat", .double).notNull()
                t.column("cholesterol", .double).notNull()
                t.column("sodium", .double).notNull()
                t.column("totalCarbohydrates", .double).notNull()
                t.column("dietaryFiber", .double).notNull()
                t.column("sugars", .double).notNull()
                t.column("protein", .double).notNull()
                t.column("vitaminD", .double).notNull()
                t.column("calcium", .double).notNull()
                t.column("iron", .double).notNull()
                t.column("potassium", .double).notNull()
                t.column("addedSugars", .double)
                t.column("vitaminA", .double)
                t.column("vitaminC", .double)
                t.column("magnesium", .double)
            }
            
            print("🔵 DatabaseManager: Creating foodProducts table")
            try db.create(table: "foodProducts") { t in
                t.column("id", .text).primaryKey().notNull()
                t.column("name", .text).notNull()
                t.column("brand", .text)
                t.column("barcode", .text)
                t.column("imageURL", .text)
                t.column("dateScanned", .datetime).notNull()
                t.column("healthScore", .integer)
                t.column("userNotes", .text)
                t.column("isFavorite", .boolean).notNull().defaults(to: false)
                t.column("category", .text).notNull().defaults(to: "Other")
                t.column("nutritionFactsId", .integer).references("nutritionFacts", onDelete: .cascade)
            }
            
            // Create junction tables for the array fields
            print("🔵 DatabaseManager: Creating foodProductIngredients table")
            try db.create(table: "foodProductIngredients") { t in
                t.column("foodProductId", .text).notNull()
                    .references("foodProducts", onDelete: .cascade)
                t.column("ingredient", .text).notNull()
                t.primaryKey(["foodProductId", "ingredient"])
            }
            
            print("🔵 DatabaseManager: Creating foodProductAllergens table")
            try db.create(table: "foodProductAllergens") { t in
                t.column("foodProductId", .text).notNull()
                    .references("foodProducts", onDelete: .cascade)
                t.column("allergen", .text).notNull()
                t.primaryKey(["foodProductId", "allergen"])
            }
            
            // Create indices for faster queries
            print("🔵 DatabaseManager: Creating indices")
            try db.create(index: "foodProducts_dateScanned", on: "foodProducts", columns: ["dateScanned"])
            try db.create(index: "foodProducts_isFavorite", on: "foodProducts", columns: ["isFavorite"])
            try db.create(index: "foodProducts_category", on: "foodProducts", columns: ["category"])
            
            print("✅ DatabaseManager: Initial schema migration completed")
        }
        
        // Migration to add the foodProductImages table for existing databases
        migrator.registerMigration("v2.addFoodProductImagesTable") { db in
            print("🔵 DatabaseManager: Checking if foodProductImages table needs to be created")
            
            // Check if the table already exists
            let tableExists = try db.tableExists("foodProductImages")
            
            if !tableExists {
                print("🔵 DatabaseManager: Creating foodProductImages table (was missing)")
                try db.create(table: "foodProductImages") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("foodProductId", .text).notNull()
                        .references("foodProducts", onDelete: .cascade)
                    t.column("imageData", .blob).notNull()
                }
                print("✅ DatabaseManager: foodProductImages table created successfully")
            } else {
                print("🔵 DatabaseManager: foodProductImages table already exists, skipping creation")
            }
        }
        
        return migrator
    }
    
    /// Verify that all tables exist in the database
    func verifyDatabase() {
        print("🔵 DatabaseManager: Starting database verification")
        do {
            try dbQueue.read { db in
                // Get all table names in the database
                let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table'")
                print("📊 DatabaseManager: Database tables: \(tables)")
                
                // Check if all required tables exist
                let requiredTables = ["nutritionFacts", "foodProducts", "foodProductIngredients", "foodProductAllergens", "foodProductImages"]
                for tableName in requiredTables {
                    if !tables.contains(tableName) {
                        print("⚠️ DatabaseManager: WARNING: Required table '\(tableName)' is missing!")
                    } else {
                        // Print table schema
                        let schema = try String.fetchAll(db, sql: "PRAGMA table_info(\(tableName))")
                        print("📊 DatabaseManager: Table '\(tableName)' schema: \(schema)")
                        
                        // Count records in the table
                        let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(tableName)")
                        print("📊 DatabaseManager: Table '\(tableName)' contains \(count ?? 0) records")
                    }
                }
                print("✅ DatabaseManager: Database verification complete")
            }
        } catch {
            print("❌ DatabaseManager: Error verifying database: \(error)")
        }
    }
    
    /// Resets the database by deleting all data
    func resetDatabase() throws {
        print("⚠️ DatabaseManager: Resetting database - deleting all data")
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM foodProducts")
            try db.execute(sql: "DELETE FROM nutritionFacts")
            try db.execute(sql: "DELETE FROM foodProductIngredients")
            try db.execute(sql: "DELETE FROM foodProductAllergens")
            try db.execute(sql: "DELETE FROM foodProductImages")
        }
        print("✅ DatabaseManager: Database reset complete")
    }
} 