import Foundation
import GRDB

// MARK: - NutritionFacts Model

/// Detailed nutrition facts for a food product
struct NutritionFacts: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "nutritionFacts"
    
    var id: Int64?
    var servingSize: String
    var calories: Double
    var totalFat: Double // in grams
    var saturatedFat: Double // in grams
    var transFat: Double // in grams
    var cholesterol: Double // in mg
    var sodium: Double // in mg
    var totalCarbohydrates: Double // in grams
    var dietaryFiber: Double // in grams
    var sugars: Double // in grams
    var protein: Double // in grams
    
    // Vitamins and minerals (percentage of daily value)
    var vitaminD: Double // percentage
    var calcium: Double // percentage
    var iron: Double // percentage
    var potassium: Double // percentage
    
    // Optional additional nutrients that might be present in some products
    var addedSugars: Double? // in grams
    var vitaminA: Double? // percentage
    var vitaminC: Double? // percentage
    var magnesium: Double? // percentage
    
    init(
        id: Int64? = nil,
        servingSize: String,
        calories: Double,
        totalFat: Double,
        saturatedFat: Double,
        transFat: Double,
        cholesterol: Double,
        sodium: Double,
        totalCarbohydrates: Double,
        dietaryFiber: Double,
        sugars: Double,
        protein: Double,
        vitaminD: Double,
        calcium: Double,
        iron: Double,
        potassium: Double,
        addedSugars: Double? = nil,
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        magnesium: Double? = nil
    ) {
        self.id = id
        self.servingSize = servingSize
        self.calories = calories
        self.totalFat = totalFat
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.totalCarbohydrates = totalCarbohydrates
        self.dietaryFiber = dietaryFiber
        self.sugars = sugars
        self.protein = protein
        self.vitaminD = vitaminD
        self.calcium = calcium
        self.iron = iron
        self.potassium = potassium
        self.addedSugars = addedSugars
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.magnesium = magnesium
    }
}

// MARK: - FoodProduct Model

/// Represents a scanned food product with nutritional information
struct FoodProduct: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "foodProducts"
    
    var id: String
    var name: String
    var brand: String?
    var barcode: String?
    var imageURL: String?
    var dateScanned: Date
    var healthScore: Int?
    var userNotes: String?
    var isFavorite: Bool
    var category: String
    var nutritionFactsId: Int64?
    
    // Relationships handled separately
    private(set) var _ingredients: [String]?
    private(set) var _allergens: [String]?
    private(set) var _nutritionFacts: NutritionFacts?
    private(set) var _images: [Data]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode, imageURL, dateScanned, healthScore, userNotes, isFavorite, category, nutritionFactsId
    }
    
    // Enum for product categories
    enum Category: String, CaseIterable, Codable {
        case dairy = "Dairy"
        case produce = "Produce"
        case bakery = "Bakery"
        case meat = "Meat"
        case seafood = "Seafood"
        case snacks = "Snacks"
        case beverages = "Beverages"
        case frozen = "Frozen"
        case pantry = "Pantry"
        case other = "Other"
        
        static func fromString(_ string: String) -> Category {
            return Category.allCases.first { $0.rawValue.lowercased() == string.lowercased() } ?? .other
        }
    }
    
    /// Helper to get the category enum
    var categoryEnum: Category {
        return Category.fromString(category)
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        imageURL: String? = nil,
        dateScanned: Date = Date(),
        nutritionFacts: NutritionFacts? = nil,
        ingredients: [String] = [],
        allergens: [String] = [],
        healthScore: Int? = nil,
        userNotes: String? = nil,
        isFavorite: Bool = false,
        category: String = "Other",
        nutritionFactsId: Int64? = nil,
        images: [Data] = []
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.imageURL = imageURL
        self.dateScanned = dateScanned
        self._nutritionFacts = nutritionFacts
        self._ingredients = ingredients
        self._allergens = allergens
        self._images = images
        self.healthScore = healthScore
        self.userNotes = userNotes
        self.isFavorite = isFavorite
        self.category = category
        self.nutritionFactsId = nutritionFactsId
    }
    
    // Accessor for ingredients - ensures ingredients are never nil
    var ingredients: [String] {
        get { return _ingredients ?? [] }
        set { _ingredients = newValue }
    }
    
    // Accessor for allergens - ensures allergens are never nil
    var allergens: [String] {
        get { return _allergens ?? [] }
        set { _allergens = newValue }
    }
    
    // Accessor for nutritionFacts
    var nutritionFacts: NutritionFacts? {
        get { return _nutritionFacts }
        set { 
            _nutritionFacts = newValue
            nutritionFactsId = newValue?.id
        }
    }
    
    // Accessor for images - ensures images are never nil
    var images: [Data] {
        get { return _images ?? [] }
        set { _images = newValue }
    }
    
    // Static method to create sample products for UI development
    static func sampleProducts() -> [FoodProduct] {
        return [
            FoodProduct(
                id: "1",
                name: "Organic Whole Milk",
                brand: "Green Farms",
                barcode: "8901234567890",
                imageURL: nil,
                dateScanned: Date(),
                nutritionFacts: NutritionFacts(
                    id: 1,
                    servingSize: "240ml",
                    calories: 150,
                    totalFat: 8,
                    saturatedFat: 5,
                    transFat: 0,
                    cholesterol: 35,
                    sodium: 120,
                    totalCarbohydrates: 12,
                    dietaryFiber: 0,
                    sugars: 12,
                    protein: 8,
                    vitaminD: 25,
                    calcium: 30,
                    iron: 0,
                    potassium: 10
                ),
                ingredients: ["Organic Whole Milk", "Vitamin D3"],
                allergens: ["Milk"],
                healthScore: 75,
                userNotes: nil,
                isFavorite: true,
                category: "Dairy"
            ),
            
            FoodProduct(
                id: "2",
                name: "Whole Wheat Bread",
                brand: "Nature's Bakery",
                barcode: "7651234567890",
                imageURL: nil,
                dateScanned: Date().addingTimeInterval(-86400), // Yesterday
                nutritionFacts: NutritionFacts(
                    id: 2,
                    servingSize: "1 slice (40g)",
                    calories: 100,
                    totalFat: 1.5,
                    saturatedFat: 0,
                    transFat: 0,
                    cholesterol: 0,
                    sodium: 180,
                    totalCarbohydrates: 19,
                    dietaryFiber: 3,
                    sugars: 2,
                    protein: 4,
                    vitaminD: 0,
                    calcium: 2,
                    iron: 6,
                    potassium: 2
                ),
                ingredients: ["Whole Wheat Flour", "Water", "Yeast", "Salt", "Sugar"],
                allergens: ["Wheat"],
                healthScore: 85,
                userNotes: "Good for sandwiches",
                isFavorite: false,
                category: "Bakery"
            ),
            
            FoodProduct(
                id: "3",
                name: "Greek Yogurt",
                brand: "Mediterranean",
                barcode: "6901834567890",
                imageURL: nil,
                dateScanned: Date().addingTimeInterval(-172800), // 2 days ago
                nutritionFacts: NutritionFacts(
                    id: 3,
                    servingSize: "170g",
                    calories: 120,
                    totalFat: 0,
                    saturatedFat: 0,
                    transFat: 0,
                    cholesterol: 10,
                    sodium: 70,
                    totalCarbohydrates: 9,
                    dietaryFiber: 0,
                    sugars: 7,
                    protein: 22,
                    vitaminD: 0,
                    calcium: 20,
                    iron: 0,
                    potassium: 8
                ),
                ingredients: ["Cultured Pasteurized Nonfat Milk", "Live Active Yogurt Cultures"],
                allergens: ["Milk"],
                healthScore: 90,
                userNotes: nil,
                isFavorite: true,
                category: "Dairy"
            )
        ]
    }
}

// MARK: - Junction Tables Record Types

/// Record type for the junction table between FoodProduct and ingredients
struct FoodProductIngredient: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "foodProductIngredients"
    
    let foodProductId: String
    let ingredient: String
    
    init(foodProductId: String, ingredient: String) {
        self.foodProductId = foodProductId
        self.ingredient = ingredient
    }
}

/// Record type for the junction table between FoodProduct and allergens
struct FoodProductAllergen: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "foodProductAllergens"
    
    let foodProductId: String
    let allergen: String
    
    init(foodProductId: String, allergen: String) {
        self.foodProductId = foodProductId
        self.allergen = allergen
    }
}

/// Record type for storing product images
struct FoodProductImage: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "foodProductImages"
    
    let foodProductId: String
    let imageData: Data
    let id: Int64?
    
    init(id: Int64? = nil, foodProductId: String, imageData: Data) {
        self.id = id
        self.foodProductId = foodProductId
        self.imageData = imageData
    }
}

// MARK: - FoodProduct Database Extensions

extension FoodProduct {
    /// Insert the food product with all relationships
    mutating func insert(in db: Database) throws -> FoodProduct {
        print("📝 FoodProduct.insert: Starting insert for product: \(name), ID: \(id)")
        
        // 1. Save the nutrition facts first to get an ID
        if var nutritionFacts = _nutritionFacts {
            print("📝 FoodProduct.insert: Inserting nutrition facts")
            try nutritionFacts.insert(db)
            self.nutritionFactsId = nutritionFacts.id
            print("📝 FoodProduct.insert: Nutrition facts inserted with ID: \(nutritionFacts.id ?? -1)")
        } else {
            print("⚠️ FoodProduct.insert: No nutrition facts to insert")
        }
        
        // 2. Save the main product
        print("📝 FoodProduct.insert: Inserting main product record")
        try insert(db)
        print("✅ FoodProduct.insert: Main product record inserted")
        
        // 3. Save the ingredients
        if let ingredients = _ingredients {
            print("📝 FoodProduct.insert: Inserting \(ingredients.count) ingredients")
            for ingredient in ingredients {
                let junction = FoodProductIngredient(foodProductId: id, ingredient: ingredient)
                try junction.insert(db)
            }
            print("✅ FoodProduct.insert: All ingredients inserted")
        } else {
            print("⚠️ FoodProduct.insert: No ingredients to insert")
        }
        
        // 4. Save the allergens
        if let allergens = _allergens {
            print("📝 FoodProduct.insert: Inserting \(allergens.count) allergens")
            for allergen in allergens {
                let junction = FoodProductAllergen(foodProductId: id, allergen: allergen)
                try junction.insert(db)
            }
            print("✅ FoodProduct.insert: All allergens inserted")
        } else {
            print("⚠️ FoodProduct.insert: No allergens to insert")
        }
        
        // 5. Save the images
        if let images = _images {
            print("📝 FoodProduct.insert: Inserting \(images.count) images")
            for imageData in images {
                let productImage = FoodProductImage(foodProductId: id, imageData: imageData)
                try productImage.insert(db)
            }
            print("✅ FoodProduct.insert: All images inserted")
        } else {
            print("⚠️ FoodProduct.insert: No images to insert")
        }
        
        print("✅ FoodProduct.insert: Successfully completed insert for product: \(name)")
        return self
    }
    
    /// Update the food product with all relationships
    mutating func update(in db: Database) throws {
        print("🔄 FoodProduct.update: Starting update for product: \(name), ID: \(id)")
        
        // 1. Handle nutrition facts
        if var nutritionFacts = _nutritionFacts {
            if nutritionFacts.id == nil {
                print("📝 FoodProduct.update: Inserting new nutrition facts")
                try nutritionFacts.insert(db)
                self.nutritionFactsId = nutritionFacts.id
                print("📝 FoodProduct.update: New nutrition facts inserted with ID: \(nutritionFacts.id ?? -1)")
            } else {
                print("🔄 FoodProduct.update: Updating existing nutrition facts with ID: \(nutritionFacts.id ?? -1)")
                try nutritionFacts.update(db)
                print("✅ FoodProduct.update: Nutrition facts updated")
            }
            self.nutritionFactsId = nutritionFacts.id
        } else {
            print("⚠️ FoodProduct.update: No nutrition facts to update")
        }
        
        // 2. Update the main product
        print("🔄 FoodProduct.update: Updating main product record")
        try update(db)
        print("✅ FoodProduct.update: Main product record updated")
        
        // 3. Update ingredients - delete and reinsert
        print("🔄 FoodProduct.update: Deleting existing ingredients for product ID: \(id)")
        try FoodProductIngredient
            .filter(Column("foodProductId") == id)
            .deleteAll(db)
        print("✅ FoodProduct.update: Existing ingredients deleted")
        
        if let ingredients = _ingredients {
            print("📝 FoodProduct.update: Inserting \(ingredients.count) ingredients")
            for ingredient in ingredients {
                let junction = FoodProductIngredient(foodProductId: id, ingredient: ingredient)
                try junction.insert(db)
            }
            print("✅ FoodProduct.update: All ingredients inserted")
        } else {
            print("⚠️ FoodProduct.update: No ingredients to insert")
        }
        
        // 4. Update allergens - delete and reinsert
        print("🔄 FoodProduct.update: Deleting existing allergens for product ID: \(id)")
        try FoodProductAllergen
            .filter(Column("foodProductId") == id)
            .deleteAll(db)
        print("✅ FoodProduct.update: Existing allergens deleted")
        
        if let allergens = _allergens {
            print("📝 FoodProduct.update: Inserting \(allergens.count) allergens")
            for allergen in allergens {
                let junction = FoodProductAllergen(foodProductId: id, allergen: allergen)
                try junction.insert(db)
            }
            print("✅ FoodProduct.update: All allergens inserted")
        } else {
            print("⚠️ FoodProduct.update: No allergens to insert")
        }
        
        // 5. Update images - delete and reinsert
        print("🔄 FoodProduct.update: Deleting existing images for product ID: \(id)")
        try FoodProductImage
            .filter(Column("foodProductId") == id)
            .deleteAll(db)
        print("✅ FoodProduct.update: Existing images deleted")
        
        if let images = _images {
            print("📝 FoodProduct.update: Inserting \(images.count) images")
            for imageData in images {
                let productImage = FoodProductImage(foodProductId: id, imageData: imageData)
                try productImage.insert(db)
            }
            print("✅ FoodProduct.update: All images inserted")
        } else {
            print("⚠️ FoodProduct.update: No images to insert")
        }
        
        print("✅ FoodProduct.update: Successfully completed update for product: \(name)")
    }
    
    /// Save the food product (insert if new, update if existing)
    mutating func save(in db: Database) throws -> FoodProduct {
        print("💾 FoodProduct.save: Starting save for product: \(name), ID: \(id)")
        
        let existingProduct = try FoodProduct.fetchOne(db, key: id)
        if existingProduct != nil {
            print("🔄 FoodProduct.save: Product exists, performing update")
            try update(in: db)
        } else {
            print("📝 FoodProduct.save: Product doesn't exist, performing insert")
            try insert(in: db)
        }
        
        print("✅ FoodProduct.save: Successfully saved product: \(name)")
        return self
    }
    
    /// Load a product with all its relationships
    static func loadComplete(id: String, db: Database) throws -> FoodProduct? {
        print("🔄 FoodProduct.loadComplete: Starting to load product ID: \(id)")
        
        guard var product = try FoodProduct.fetchOne(db, key: id) else {
            print("⚠️ FoodProduct.loadComplete: Product not found with ID: \(id)")
            return nil
        }
        
        print("✅ FoodProduct.loadComplete: Found product: \(product.name)")
        
        // Load nutrition facts
        if let nutritionFactsId = product.nutritionFactsId {
            print("🔄 FoodProduct.loadComplete: Loading nutrition facts with ID: \(nutritionFactsId)")
            product._nutritionFacts = try NutritionFacts.fetchOne(db, key: nutritionFactsId)
            print("✅ FoodProduct.loadComplete: Nutrition facts loaded: \(product._nutritionFacts != nil)")
        } else {
            print("⚠️ FoodProduct.loadComplete: No nutrition facts ID for product")
        }
        
        // Load ingredients
        print("🔄 FoodProduct.loadComplete: Loading ingredients for product ID: \(id)")
        let ingredients = try FoodProductIngredient
            .filter(Column("foodProductId") == id)
            .fetchAll(db)
            .map { $0.ingredient }
        product._ingredients = ingredients
        print("✅ FoodProduct.loadComplete: Loaded \(ingredients.count) ingredients")
        
        // Load allergens
        print("🔄 FoodProduct.loadComplete: Loading allergens for product ID: \(id)")
        let allergens = try FoodProductAllergen
            .filter(Column("foodProductId") == id)
            .fetchAll(db)
            .map { $0.allergen }
        product._allergens = allergens
        print("✅ FoodProduct.loadComplete: Loaded \(allergens.count) allergens")
        
        // Load images - safely check if the table exists first
        print("🔄 FoodProduct.loadComplete: Loading images for product ID: \(id)")
        do {
            // Check if the table exists before attempting to query it
            let tableExists = try db.tableExists("foodProductImages")
            if tableExists {
                let images = try FoodProductImage
                    .filter(Column("foodProductId") == id)
                    .fetchAll(db)
                    .map { $0.imageData }
                product._images = images
                print("✅ FoodProduct.loadComplete: Loaded \(images.count) images")
            } else {
                print("⚠️ FoodProduct.loadComplete: foodProductImages table doesn't exist, skipping image loading")
                product._images = []
            }
        } catch {
            // Handle the error gracefully
            print("⚠️ FoodProduct.loadComplete: Error loading images: \(error.localizedDescription)")
            product._images = []
        }
        
        print("✅ FoodProduct.loadComplete: Successfully loaded complete product: \(product.name)")
        return product
    }
}

// MARK: - Additional Requests

extension FoodProduct {
    /// Get recent products
    static func recentProducts(limit: Int = 10) -> QueryInterfaceRequest<FoodProduct> {
        return FoodProduct
            .order(Column("dateScanned").desc)
            .limit(limit)
    }
    
    /// Get favorite products
    static func favoriteProducts() -> QueryInterfaceRequest<FoodProduct> {
        return FoodProduct
            .filter(Column("isFavorite") == true)
            .order(Column("dateScanned").desc)
    }
    
    /// Get products by category
    static func productsByCategory(_ category: Category) -> QueryInterfaceRequest<FoodProduct> {
        return FoodProduct
            .filter(Column("category") == category.rawValue)
            .order(Column("dateScanned").desc)
    }
}

// User preferences for the app
struct UserPreferences: Codable {
    var prioritizeSpeed: Bool = false
    var offlineMode: Bool = false
    var notificationsEnabled: Bool = true
    var language: String = "English"
    var apiKey: String? = nil
    
    // Dietary preferences/restrictions
    var isVegetarian: Bool = false
    var isVegan: Bool = false
    var isGlutenFree: Bool = false
    var isLactoseIntolerant: Bool = false
    var isKeto: Bool = false
    var isLowCarb: Bool = false
    
    // User-specific allergen alerts
    var allergenAlerts: [String] = []
}

/*
// Scan result from the API
struct ScanResult: Codable {
    var success: Bool
    var product: FoodProduct?
    var error: String?
    var confidenceScore: Double? // How confident the API is in the scan result
    var alternativeProducts: [FoodProduct]? // Possible alternatives if match not certain
}
*/ 