import Foundation
import SwiftUI
import GRDB

class ProductViewModel: ObservableObject {
    @Published var userPreferences = UserPreferences()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // DeepSeek API configuration
    private let deepseekApiKey = "sk-0001ab02a21b4fe183f095109b5d922c"
    private let deepseekApiUrl = "https://api.deepseek.com/v1/chat/completions"
    
    // GRDB database access
    private let dbQueue: DatabaseQueue
    
    init() {

        
        // Initialize database connection
        self.dbQueue = DatabaseManager.shared.dbQueue
        debugLog("🔵 Database queue obtained from DatabaseManager")
        
        // Populate sample data if needed
        checkAndPopulateSampleData()
        debugLog("🔵 ProductViewModel initialization complete")
    }
    
    private func checkAndPopulateSampleData() {
        debugLog("🔍 Checking if sample data needs to be populated")
        do {
            let count = try dbQueue.read { db in
                debugLog("🔍 Counting existing products in database")
                let count = try FoodProduct.fetchCount(db)
                debugLog("🔍 Found \(count) existing products in database")
                return count
            }
            
            if count == 0 {
                debugLog("⚠️ No products found in database, adding sample data")
                populateSampleData()
            } else {
                debugLog("✅ Database already contains \(count) products, no need to add samples")
            }
        } catch {
            debugLog("❌ Error checking for sample data: \(error)")
            print("Error checking for sample data: \(error)")
        }
    }
    
    private func populateSampleData() {
        debugLog("📝 Populating sample data...")
        do {
            try dbQueue.write { db in
                debugLog("📝 Beginning database transaction for sample data")
                for var product in FoodProduct.sampleProducts() {
                    debugLog("📝 Adding sample product: \(product.name)")
                    try product.insert(in: db)
                }
                debugLog("📝 Sample data transaction complete")
            }
            debugLog("✅ Sample data populated successfully")
            print("Sample data populated successfully")
        } catch {
            debugLog("❌ Error populating sample data: \(error)")
            print("Error populating sample data: \(error)")
        }
    }
    
    // MARK: - Data Access Methods
    
    // Get recent products for display on home screen
    func getRecentProducts(limit: Int = 10) -> [FoodProduct] {
        debugLog("🔍 Getting recent \(limit) products")
        do {
            return try dbQueue.read { db in
                var products = try FoodProduct.recentProducts(limit: limit).fetchAll(db)
                debugLog("🔍 Fetched \(products.count) recent products from database")
                
                // Load the relationships for each product
                for i in 0..<products.count {
                    do {
                        debugLog("🔍 Loading complete data for product \(i+1) of \(products.count): \(products[i].name)")
                        if let completeProduct = try FoodProduct.loadComplete(id: products[i].id, db: db) {
                            products[i] = completeProduct
                            debugLog("✅ Successfully loaded complete data for product: \(completeProduct.name)")
                        } else {
                            debugLog("⚠️ Failed to load complete product data for ID: \(products[i].id)")
                        }
                    } catch {
                        // Handle errors for individual products gracefully
                        debugLog("❌ Error loading complete product data: \(error.localizedDescription)")
                        // Continue with the next product rather than failing entirely
                    }
                }
                
                debugLog("✅ Returning \(products.count) products")
                return products
            }
        } catch {
            debugLog("❌ Error fetching recent products: \(error.localizedDescription)")
            return []
        }
    }
    
    // Get favorite products
    func getFavoriteProducts() -> [FoodProduct] {
        do {
            return try dbQueue.read { db in
                var products = try FoodProduct.favoriteProducts().fetchAll(db)
                
                // Load the relationships for each product
                for i in 0..<products.count {
                    if let completeProduct = try FoodProduct.loadComplete(id: products[i].id, db: db) {
                        products[i] = completeProduct
                    }
                }
                
                return products
            }
        } catch {
            print("Error fetching favorite products: \(error)")
            return []
        }
    }
    
    // Get products by category
    func getProductsByCategory(_ category: FoodProduct.Category) -> [FoodProduct] {
        do {
            return try dbQueue.read { db in
                var products = try FoodProduct.productsByCategory(category).fetchAll(db)
                
                // Load the relationships for each product
                for i in 0..<products.count {
                    if let completeProduct = try FoodProduct.loadComplete(id: products[i].id, db: db) {
                        products[i] = completeProduct
                    }
                }
                
                return products
            }
        } catch {
            print("Error fetching products by category: \(error)")
            return []
        }
    }
    
    // Search products by name, brand, or ingredients
    func searchProducts(query: String) -> [FoodProduct] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        do {
            return try dbQueue.read { db in
                // Search in main product properties
                let nameLikePattern = "%\(lowercasedQuery)%"
                var productsByProperties = try FoodProduct
                    .filter(Column("name").like(nameLikePattern) || Column("brand").like(nameLikePattern))
                    .order(Column("dateScanned").desc)
                    .fetchAll(db)
                
                // Load the relationships for these products
                for i in 0..<productsByProperties.count {
                    if let completeProduct = try FoodProduct.loadComplete(id: productsByProperties[i].id, db: db) {
                        productsByProperties[i] = completeProduct
                    }
                }
                
                // Search in ingredients
                let productIdsByIngredients = try FoodProductIngredient
                    .filter(Column("ingredient").like(nameLikePattern))
                    .select(Column("foodProductId"))
                    .fetchAll(db)
                    .map { $0["foodProductId"] as? String ?? "" }
                
                if !productIdsByIngredients.isEmpty {
                    var productsByIngredients = try FoodProduct
                        .filter(productIdsByIngredients.contains(Column("id")))
                        .fetchAll(db)
                    
                    // Load the relationships for these products
                    for i in 0..<productsByIngredients.count {
                        if let completeProduct = try FoodProduct.loadComplete(id: productsByIngredients[i].id, db: db) {
                            productsByIngredients[i] = completeProduct
                        }
                    }
                    
                    // Combine the results, avoiding duplicates
                    let existingIds = Set(productsByProperties.map { $0.id })
                    productsByProperties.append(contentsOf: productsByIngredients.filter { !existingIds.contains($0.id) })
                }
                
                return productsByProperties
            }
        } catch {
            print("Error searching products: \(error)")
            return []
        }
    }
    
    // MARK: - Product Management
    
    // Toggle favorite status for a product
    func toggleFavorite(for productId: String) {
        do {
            try dbQueue.write { db in
                if var product = try FoodProduct.fetchOne(db, key: productId) {
                    product.isFavorite.toggle()
                    try product.update(db)
                    
                    // Notify observers of the change
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                }
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    // Add a note to a product
    func addNote(to productId: String, note: String) {
        do {
            try dbQueue.write { db in
                if var product = try FoodProduct.fetchOne(db, key: productId) {
                    product.userNotes = note
                    try product.update(db)
                    
                    // Notify observers of the change
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                }
            }
        } catch {
            print("Error adding note: \(error)")
        }
    }
    
    // MARK: - Scanning and API Functionality
    
    // Process a scan result using DeepSeek API
    func processScanResult(extractedText: String) {
        isLoading = true
        errorMessage = nil
        
        // If user prefers to work offline or there's no API key, use mock data
        if userPreferences.offlineMode {
            let mockProduct = createMockProductFromScan(extractedText: extractedText)
            saveProduct(mockProduct)
            return
        }
        
        // Call DeepSeek API to analyze the food label
        callDeepSeekAPI(with: extractedText) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let product):
                    self.saveProduct(product)
                case .failure(let error):
                    self.errorMessage = "Error processing scan: \(error.localizedDescription)"
                    print("DeepSeek API error: \(error)")
                    
                    // Fallback to mock data on error
                    let mockProduct = self.createMockProductFromScan(extractedText: extractedText)
                    self.saveProduct(mockProduct)
                }
            }
        }
    }
    
    private func saveProduct(_ product: FoodProduct) {
        var productToSave = product
        
        // Ensure all properties are properly initialized
        if product.nutritionFacts == nil {
            let nutritionFacts = NutritionFacts(
                servingSize: "N/A",
                calories: 0,
                totalFat: 0,
                saturatedFat: 0,
                transFat: 0,
                cholesterol: 0,
                sodium: 0,
                totalCarbohydrates: 0,
                dietaryFiber: 0,
                sugars: 0,
                protein: 0,
                vitaminD: 0,
                calcium: 0,
                iron: 0,
                potassium: 0
            )
            productToSave.nutritionFacts = nutritionFacts
        }
        
        // Ensure health score is set
        if productToSave.healthScore == nil {
            productToSave.healthScore = 50 // Default score
        }
        
        do {
            try dbQueue.write { db in
                try productToSave.insert(in: db)
            }
            print("Product saved successfully: \(productToSave.name)")
        } catch {
            print("Error saving product: \(error)")
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.objectWillChange.send()
        }
    }
    
    // Call DeepSeek API with the extracted text
    private func callDeepSeekAPI(with extractedText: String, completion: @escaping (Result<FoodProduct, Error>) -> Void) {
        // Prepare URL and request
        guard let url = URL(string: deepseekApiUrl) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(deepseekApiKey)", forHTTPHeaderField: "Authorization")
        
        // Try to detect language from the extracted text
        let detectedLanguage = detectLanguage(from: extractedText)
        
        // Create the system prompt and user message
        let systemPrompt = getSystemPrompt()
        let userMessage = "Here is the text extracted from a food product label: \n\n\"\(extractedText)\"\n\nDetected language: \(detectedLanguage). Please analyze this THOROUGHLY and provide the COMPLETE structured information about the ingredients in English. Focus on identifying all ingredients and explaining what they are in simple terms."
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.1, // Lower temperature for more deterministic responses
            "max_tokens": 3000
        ]
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Configure the request for speed
        request.timeoutInterval = 800 // Reduce timeout to 30 seconds
        
        // Make the API call with higher priorityr
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            do {
                // Parse the API response
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Try to parse the structured response
                    do {
                        print("DeepSeek response: \(content)")
                        
                        // Store the raw JSON response in the userNotes field
                        var rawResponseContent = "DeepSeek response: ```json\n"
                        if content.contains("{") && content.contains("}") {
                            // Extract just the JSON part if wrapped in markdown or other text
                            if let startIndex = content.range(of: "{")?.lowerBound,
                               let endIndex = content.range(of: "}", options: .backwards)?.upperBound {
                                rawResponseContent += content[startIndex..<endIndex]
                            } else {
                                rawResponseContent += content
                            }
                        } else {
                            rawResponseContent += content
                        }
                        rawResponseContent += "\n```"
                        
                        let product = try self.parseDeepSeekResponse(content, rawResponse: rawResponseContent)
                        completion(.success(product))
                    } catch {
                        print("Failed to parse DeepSeek response: \(error)")
                        print("Response content: \(content)")
                        
                        // Fallback to creating a mock product using the extracted text
                        let product = self.createMockProductFromScan(extractedText: extractedText)
                        completion(.success(product))
                    }
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        // Set task priority to high
        task.priority = URLSessionTask.highPriority
        task.resume()
    }
    
    // Detect language from the extracted text
    private func detectLanguage(from text: String) -> String {
        // Simple language detection based on common characters or words
        let text = text.lowercased()
        
        if text.contains("ü") || text.contains("ö") || text.contains("ä") || text.contains("ß") || 
           text.contains(" der ") || text.contains(" das ") || text.contains(" ein ") || text.contains("zutaten") {
            return "German"
        } else if text.contains("é") || text.contains("è") || text.contains("ê") || text.contains("à") || 
                text.contains(" le ") || text.contains(" la ") || text.contains(" les ") || text.contains("ingrédients") {
            return "French"
        } else if text.contains("ñ") || text.contains("¿") || text.contains("¡") || 
                 text.contains(" el ") || text.contains(" los ") || text.contains(" las ") || text.contains("ingredientes") {
            return "Spanish"
        } else if text.contains("维生素") || text.contains("蛋白质") || text.contains("脂肪") || text.contains("碳水化合物") {
            return "Chinese"
        } else {
            return "English"
        }
    }
    
    // System prompt for DeepSeek
    private func getSystemPrompt() -> String {
        return """
        You are an ingredient analysis assistant for the "Keep Me Healthy" app. Your primary task is to analyze food product labels that users scan with their phone and identify WHAT'S IN THERE - focusing on ingredients and what they actually are.

        INSTRUCTIONS FOR ANALYZING FOOD LABELS:
        
        1. EXTRACT ALL INGREDIENTS - Your main focus is to identify every single ingredient listed on the food label.
        
        2. MULTILINGUAL SUPPORT - You must be able to analyze food labels in different languages, especially English and Chinese. When presented with a food label in any language:
           - Identify and extract all information correctly
           - ALWAYS translate all content to English in your response
           - Preserve any original terms in parentheses when helpful
        
        3. PRODUCT NAME CORRECTION - If the extracted product name appears garbled, unclear, or nonsensical:
           - Use contextual clues from ingredients and other label information
           - Infer a reasonable product name based on what the product actually is
           - Include the original text in parentheses if uncertain
        
        4. When given text extracted from a food label image, analyze it and extract the following information:
           - Product name - Determine the full, specific product name or infer a logical name if unclear
           - Brand name (if available)
           - Category (must be one of: Dairy, Produce, Bakery, Meat, Seafood, Snacks, Beverages, Frozen, Pantry, Supplements, Other)
           - Ingredients list - MOST IMPORTANT: For each ingredient, provide a simple explanation of what it is, focusing on:
              * What the ingredient actually is (plant/animal/synthetic)
              * Its purpose in the food (flavor, preservative, texture, etc.)
              * Any health implications (positive or negative)
              * Whether it's highly processed or natural
           - Allergens (common allergens like milk, eggs, nuts, wheat, soy, fish, shellfish, etc.)
           - Concerning additives - Identify any concerning food additives like:
              * Artificial colors
              * Artificial sweeteners
              * Flavor enhancers (MSG, etc.)
              * Preservatives
              * Highly processed oils
              * Other controversial additives
        
        5. EXPLAIN FOR NON-EXPERTS - The average person doesn't know what "Disodium Guanylate" or other technical terms are:
           - For additives/chemicals: Explain in simple terms what they are and why they're in food
           - Avoid scientific jargon - use plain language a non-expert would understand
           - Help people understand if an ingredient is problematic or fine to consume
        
        6. RETURN COMPLETE JSON with ALL ingredients found in the text.
        
        JSON FORMAT:
        {
            "productName": "string or null",
            "brandName": "string or null",
            "category": "must be one of the predefined categories",
            "ingredients": [
                {
                    "name": "ingredient name",
                    "explanation": "simple explanation of what this ingredient is and its purpose",
                    "concernLevel": "none/low/medium/high",
                    "concernReason": "explanation of concern if any"
                }
            ],
            "allergens": ["array", "of", "allergens"],
            "concerningAdditives": [
                {
                    "name": "additive name",
                    "explanation": "what this additive is and why it might be concerning",
                    "concernLevel": "low/medium/high"
                }
            ],
            "processingLevel": "minimally/moderately/highly",
            "naturalContentPercentage": number, // estimate of how much of the product consists of natural vs processed ingredients (0-100)
            "simpleSummary": "A 1-2 sentence summary explaining what this product primarily consists of in simple terms",
            "recommendationsForHealthierOptions": "1-2 suggestions for healthier alternatives if applicable",
            "language": "Original language of the food label (e.g., 'English', 'Chinese', etc.)"
        }
        
        IMPORTANT NOTES:
        1. Focus primarily on ingredient identification and explanation - this is the most important part.
        2. Don't include any explanations, clarifications, or additional text outside the JSON.
        3. ALWAYS return response in English, regardless of the input language.
        4. If the text is not from a food label, respond with a JSON with an "error" field explaining the issue.
        """
    }
    
    // Parse the DeepSeek API response
    private func parseDeepSeekResponse(_ response: String, rawResponse: String? = nil) throws -> FoodProduct {
        // Extract the JSON from the response
        var jsonContent = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the response is wrapped in markdown code blocks
        if jsonContent.hasPrefix("```json") && jsonContent.hasSuffix("```") {
            let startIndex = jsonContent.index(jsonContent.startIndex, offsetBy: 7)
            let endIndex = jsonContent.index(jsonContent.endIndex, offsetBy: -3)
            jsonContent = String(jsonContent[startIndex..<endIndex])
        } else if jsonContent.hasPrefix("```") && jsonContent.hasSuffix("```") {
            let startIndex = jsonContent.index(jsonContent.startIndex, offsetBy: 3)
            let endIndex = jsonContent.index(jsonContent.endIndex, offsetBy: -3)
            jsonContent = String(jsonContent[startIndex..<endIndex])
        }
        
        // Parse the JSON
        guard let jsonData = jsonContent.data(using: .utf8) else {
            throw NSError(domain: "InvalidJSONData", code: 0, userInfo: nil)
        }
        
        let decoder = JSONDecoder()
        
        // Check if there's an error message
        if let errorResponse = try? decoder.decode([String: String].self, from: jsonData),
           let errorMessage = errorResponse["error"] {
            throw NSError(domain: "APIResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Try to decode as DeepSeekResponse
        let apiResponse = try decoder.decode(DeepSeekResponse.self, from: jsonData)
        
        // Extract ingredient names and explanations
        let ingredientNames = apiResponse.ingredients.map { $0.name }
        
        // Use the raw response if provided (for direct JSON parsing in the UI)
        let userNotes = rawResponse ?? buildUserNotes(from: apiResponse)
        
        // Default values for null fields
        let productName = apiResponse.productName ?? "Unknown Product"
        let categoryString = apiResponse.category ?? "Other"
        
        // Calculate health score based on processing level and natural content
        var healthScore = 50
        if let processingLevel = apiResponse.processingLevel {
            switch processingLevel.lowercased() {
            case "minimally": healthScore = 85
            case "moderately": healthScore = 60
            case "highly": healthScore = 30
            default: healthScore = 50
            }
        }
        
        if let naturalPercentage = apiResponse.naturalContentPercentage {
            // Adjust score based on natural content percentage
            healthScore = (healthScore + Int(naturalPercentage)) / 2
        }
        
        // Check if there are high-concern ingredients
        let hasHighConcernIngredients = apiResponse.ingredients.contains { $0.concernLevel == "high" }
        if hasHighConcernIngredients {
            healthScore = max(healthScore - 20, 10)
        }
        
        // Create nutrition facts if needed
        let nutritionFacts = NutritionFacts(
            servingSize: "N/A",
            calories: 0,
            totalFat: 0,
            saturatedFat: 0,
            transFat: 0,
            cholesterol: 0,
            sodium: 0,
            totalCarbohydrates: 0,
            dietaryFiber: 0,
            sugars: 0,
            protein: 0,
            vitaminD: 0,
            calcium: 0,
            iron: 0,
            potassium: 0
        )
        
        // Convert to FoodProduct
        return FoodProduct(
            id: UUID().uuidString,
            name: productName,
            brand: apiResponse.brandName,
            barcode: nil,
            imageURL: nil,
            dateScanned: Date(),
            nutritionFacts: nutritionFacts,
            ingredients: ingredientNames,
            allergens: apiResponse.allergens ?? [],
            healthScore: healthScore,
            userNotes: userNotes,
            isFavorite: false,
            category: categoryString
        )
    }
    
    // Build structured user notes from API response
    private func buildUserNotes(from apiResponse: DeepSeekResponse) -> String {
        var notesComponents = [String]()
        
        // Add simple summary
        if let simpleSummary = apiResponse.simpleSummary {
            notesComponents.append("SUMMARY:\n\(simpleSummary)")
        }
        
        // Add processing level
        if let processingLevel = apiResponse.processingLevel {
            notesComponents.append("PROCESSING LEVEL:\n\(processingLevel.capitalized)")
        }
        
        // Add natural content percentage
        if let naturalPercentage = apiResponse.naturalContentPercentage {
            notesComponents.append("NATURAL CONTENT:\nApproximately \(naturalPercentage)% natural ingredients")
        }
        
        // Add ingredient explanations
        if !apiResponse.ingredients.isEmpty {
            let explanationsText = apiResponse.ingredients.map { 
                let concernText = $0.concernLevel != "none" ? " - CONCERN: \($0.concernLevel.uppercased())" : ""
                let reasonText = !($0.concernReason ?? "").isEmpty ? "\nReason: \($0.concernReason!)" : ""
                return "\($0.name)\(concernText): \($0.explanation)\(reasonText)" 
            }.joined(separator: "\n\n")
            notesComponents.append("INGREDIENT EXPLANATIONS:\n\(explanationsText)")
        }
        
        // Add concerning additives
        if let additives = apiResponse.concerningAdditives, !additives.isEmpty {
            let additivesText = additives.map { 
                "\($0.name) (CONCERN: \($0.concernLevel.uppercased())): \($0.explanation)" 
            }.joined(separator: "\n\n")
            notesComponents.append("CONCERNING ADDITIVES:\n\(additivesText)")
        }
        
        // Add healthier options recommendations
        if let recommendations = apiResponse.recommendationsForHealthierOptions, !recommendations.isEmpty {
            notesComponents.append("HEALTHIER ALTERNATIVES:\n\(recommendations)")
        }
        
        // Add original language if available
        if let language = apiResponse.language {
            notesComponents.append("ORIGINAL LANGUAGE:\n\(language)")
        }
        
        // Join all notes components
        return notesComponents.joined(separator: "\n\n")
    }
    
    // Helper to convert category string to enum
    private func getCategoryFromString(_ categoryString: String) -> FoodProduct.Category {
        return FoodProduct.Category.fromString(categoryString)
    }
    
    // Structure for DeepSeek API response
    struct DeepSeekResponse: Decodable {
        struct Ingredient: Decodable {
            let name: String
            let explanation: String
            let concernLevel: String
            let concernReason: String?
        }
        
        struct ConcerningAdditive: Decodable {
            let name: String
            let explanation: String
            let concernLevel: String
        }
        
        let productName: String?
        let brandName: String?
        let category: String?
        let ingredients: [Ingredient]
        let allergens: [String]?
        let concerningAdditives: [ConcerningAdditive]?
        let processingLevel: String?
        let naturalContentPercentage: Double?
        let simpleSummary: String?
        let recommendationsForHealthierOptions: String?
        let language: String?
    }
    
    // Mock product creation (for development purposes and fallback)
    private func createMockProductFromScan(extractedText: String) -> FoodProduct {
        // For demo purposes, creating a mock product based on the scan text
        let productCategories = FoodProduct.Category.allCases
        let randomCategory = productCategories.randomElement() ?? .other
        
        let extractedWords = extractedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Try to extract product name from the first few words
        var productName = "Unknown Product"
        if extractedWords.count >= 2 {
            productName = extractedWords.prefix(min(3, extractedWords.count)).joined(separator: " ")
        }
        
        let mockIngredients = createRandomIngredients()
        let mockIngredientsExplanations = mockIngredients.map { ingredient in
            return "\(ingredient): A common ingredient used in food processing."
        }.joined(separator: "\n\n")
        
        let userNotes = """
        SUMMARY:
        This appears to be a processed food product with several ingredients.

        PROCESSING LEVEL:
        Moderately

        NATURAL CONTENT:
        Approximately 60% natural ingredients

        INGREDIENT EXPLANATIONS:
        \(mockIngredientsExplanations)

        HEALTHIER ALTERNATIVES:
        Consider looking for products with fewer processed ingredients.
        """
        
        let nutritionFacts = NutritionFacts(
            servingSize: "N/A",
            calories: 0,
            totalFat: 0,
            saturatedFat: 0,
            transFat: 0,
            cholesterol: 0,
            sodium: 0,
            totalCarbohydrates: 0,
            dietaryFiber: 0,
            sugars: 0,
            protein: 0,
            vitaminD: 0,
            calcium: 0,
            iron: 0,
            potassium: 0
        )
        
        let product = FoodProduct(
            id: UUID().uuidString,
            name: productName,
            brand: extractedWords.count > 3 ? extractedWords[3] : "Unknown Brand",
            barcode: String(Int.random(in: 1000000000000...9999999999999)),
            imageURL: nil,
            dateScanned: Date(),
            nutritionFacts: nutritionFacts,
            ingredients: mockIngredients,
            allergens: ["Milk", "Wheat"].shuffled().prefix(Int.random(in: 0...2)).map { $0 },
            healthScore: Int.random(in: 40...75),
            userNotes: userNotes,
            isFavorite: false,
            category: randomCategory.rawValue
        )
        
        return product
    }
    
    // Create random ingredients list for mock products
    private func createRandomIngredients() -> [String] {
        let allIngredients = [
            "Water", "Sugar", "Salt", "Wheat Flour", "Milk", "Cream", "Vegetable Oil",
            "Modified Corn Starch", "Natural Flavors", "Artificial Flavors", "Citric Acid",
            "Lactic Acid", "Yeast", "Baking Powder", "Eggs", "Soy Lecithin", "Vanilla Extract",
            "Monosodium Glutamate", "Red 40", "Yellow 5", "High Fructose Corn Syrup",
            "Sodium Nitrite", "BHT", "Carrageenan", "Potassium Sorbate"
        ]
        
        let count = Int.random(in: 5...12)
        return Array(allIngredients.shuffled().prefix(count))
    }
    
    // MARK: - User Preferences
    
    // Update user preferences
    func updatePreferences(preferences: UserPreferences) {
        userPreferences = preferences
    }
    
    // Clear scan history
    func clearHistory() {
        do {
            try dbQueue.write { db in
                try FoodProduct.deleteAll(db)
                try NutritionFacts.deleteAll(db)
                try FoodProductIngredient.deleteAll(db)
                try FoodProductAllergen.deleteAll(db)
            }
            objectWillChange.send()
        } catch {
            print("Error clearing history: \(error)")
        }
    }
    
    // Check if a product contains allergens the user has set alerts for
    func containsUserAllergens(_ product: FoodProduct) -> Bool {
        let userAllergens = userPreferences.allergenAlerts
        guard !userAllergens.isEmpty else { return false }
        
        return !Set(product.allergens).intersection(Set(userAllergens)).isEmpty
    }
    
    // Calculate the health compatibility of a product with user's dietary preferences
    func calculateHealthCompatibility(_ product: FoodProduct) -> Double {
        // Basic scoring logic (can be expanded with more sophisticated algorithms)
        var score = 100.0
        let preferences = userPreferences
        
        // Check dietary restrictions
        if preferences.isVegan && product.ingredients.contains(where: { 
            $0.contains("Milk") || $0.contains("Egg") || $0.contains("Meat") || $0.contains("Fish") 
        }) {
            score -= 50
        }
        
        if preferences.isVegetarian && product.ingredients.contains(where: { 
            $0.contains("Meat") || $0.contains("Fish") || $0.contains("Chicken") 
        }) {
            score -= 50
        }
        
        if preferences.isGlutenFree && product.ingredients.contains(where: { 
            $0.contains("Wheat") || $0.contains("Barley") || $0.contains("Rye") 
        }) {
            score -= 50
        }
        
        if preferences.isLactoseIntolerant && product.ingredients.contains(where: { 
            $0.contains("Milk") || $0.contains("Cream") || $0.contains("Lactose") 
        }) {
            score -= 50
        }
        
        // Check allergens
        if containsUserAllergens(product) {
            score -= 75
        }
        
        return max(0, min(score, 100))
    }
    
    // Add debug logger at the top of the file
    private func debugLog(_ message: String, function: String = #function) {
        print("📱 ProductViewModel[\(function)]: \(message)")
    }

    // Update the preloadProduct method
    func preloadProduct(_ product: FoodProduct) -> FoodProduct {
        debugLog("⏳ Starting preload for product: \(product.name), ID: \(product.id)")
        
        // First, validate if we have basic data already
        debugLog("Initial product state: ingredients: \(product.ingredients.count), allergens: \(product.allergens.count), nutritionFacts: \(product.nutritionFacts != nil)")
        
        do {
            return try dbQueue.read { db in
                debugLog("🔍 Starting database read transaction")
                
                // First try to load from database
                debugLog("🔍 Attempting to load product \(product.id) with loadComplete")
                do {
                    if let completeProduct = try FoodProduct.loadComplete(id: product.id, db: db) {
                        debugLog("✅ Successfully loaded complete product from database")
                        return completeProduct
                    } else {
                        debugLog("⚠️ Could not load complete product with loadComplete")
                    }
                } catch {
                    debugLog("❌ Error loading complete product: \(error.localizedDescription)")
                }
                
                // If we can't find the product, let's see if it exists at all
                debugLog("🔍 Checking if product exists with fetchOne")
                do {
                    if let existingProduct = try FoodProduct.fetchOne(db, key: product.id) {
                        debugLog("🔍 Product exists in database but couldn't load relationships. Product name: \(existingProduct.name), ID: \(existingProduct.id)")
                        
                        // Try to manually load relationships
                        var updatedProduct = existingProduct
                        
                        // Load nutrition facts
                        if let nutritionFactsId = updatedProduct.nutritionFactsId {
                            debugLog("🔍 Attempting to load nutrition facts with ID: \(nutritionFactsId)")
                            do {
                                updatedProduct.nutritionFacts = try NutritionFacts.fetchOne(db, key: nutritionFactsId)
                                debugLog("- Loaded nutrition facts: \(updatedProduct.nutritionFacts != nil)")
                            } catch {
                                debugLog("❌ Error loading nutrition facts: \(error.localizedDescription)")
                            }
                        } else {
                            debugLog("⚠️ No nutrition facts ID found for product")
                        }
                        
                        // Load ingredients manually
                        debugLog("🔍 Attempting to load ingredients for product ID: \(product.id)")
                        do {
                            let ingredients = try FoodProductIngredient
                                .filter(Column("foodProductId") == product.id)
                                .fetchAll(db)
                                .map { $0.ingredient }
                            updatedProduct.ingredients = ingredients
                            debugLog("- Loaded \(ingredients.count) ingredients")
                        } catch {
                            debugLog("❌ Error loading ingredients: \(error.localizedDescription)")
                            updatedProduct.ingredients = []
                        }
                        
                        // Load allergens manually
                        debugLog("🔍 Attempting to load allergens for product ID: \(product.id)")
                        do {
                            let allergens = try FoodProductAllergen
                                .filter(Column("foodProductId") == product.id)
                                .fetchAll(db)
                                .map { $0.allergen }
                            updatedProduct.allergens = allergens
                            debugLog("- Loaded \(allergens.count) allergens")
                        } catch {
                            debugLog("❌ Error loading allergens: \(error.localizedDescription)")
                            updatedProduct.allergens = []
                        }
                        
                        // Load images manually
                        debugLog("🔍 Attempting to load images for product ID: \(product.id)")
                        do {
                            // Check if the table exists before attempting to query it
                            let tableExists = try db.tableExists("foodProductImages")
                            if tableExists {
                                let images = try FoodProductImage
                                    .filter(Column("foodProductId") == product.id)
                                    .fetchAll(db)
                                    .map { $0.imageData }
                                updatedProduct.images = images
                                debugLog("- Loaded \(images.count) images")
                            } else {
                                debugLog("⚠️ foodProductImages table doesn't exist, skipping image loading")
                                updatedProduct.images = []
                            }
                        } catch {
                            debugLog("❌ Error loading images: \(error.localizedDescription)")
                            updatedProduct.images = []
                        }
                        
                        // Ensure all fields are valid
                        debugLog("🔧 Ensuring product has valid data")
                        ensureProductHasValidData(&updatedProduct)
                        return updatedProduct
                    } else {
                        debugLog("⚠️ Product does not exist in database, using passed product")
                        var safeProduct = product
                        ensureProductHasValidData(&safeProduct)
                        return safeProduct
                    }
                } catch {
                    debugLog("❌ Error checking if product exists: \(error.localizedDescription)")
                    var safeProduct = product
                    ensureProductHasValidData(&safeProduct)
                    return safeProduct
                }
            }
        } catch {
            debugLog("❌ Error preloading product: \(error.localizedDescription)")
            var safeProduct = product
            ensureProductHasValidData(&safeProduct)
            return safeProduct
        }
    }
    
    private func ensureProductHasValidData(_ product: inout FoodProduct) {
        debugLog("🔧 Ensuring product has valid data for: \(product.name), ID: \(product.id)")
        
        // Make sure category is valid
        if product.category.isEmpty {
            product.category = "Other"
            debugLog("- Fixed empty category -> set to 'Other'")
        }
        
        // Ensure we have nutrition facts
        if product.nutritionFacts == nil {
            debugLog("⚠️ Creating default nutrition facts - original was nil")
            product.nutritionFacts = NutritionFacts(
                servingSize: "N/A",
                calories: 0,
                totalFat: 0,
                saturatedFat: 0,
                transFat: 0,
                cholesterol: 0,
                sodium: 0,
                totalCarbohydrates: 0,
                dietaryFiber: 0,
                sugars: 0,
                protein: 0,
                vitaminD: 0,
                calcium: 0,
                iron: 0,
                potassium: 0
            )
            debugLog("- Added missing nutrition facts")
        } else {
            debugLog("✅ Product already has nutrition facts")
        }
        
        // Ensure health score is set
        if product.healthScore == nil {
            debugLog("⚠️ Setting default health score - original was nil")
            product.healthScore = 50
            debugLog("- Added default health score: 50")
        } else {
            debugLog("✅ Product already has health score: \(product.healthScore!)")
        }
        
        // Ensure ingredients list is initialized
        if product.ingredients.isEmpty {
            debugLog("⚠️ Adding placeholder ingredients - original list was empty")
            product.ingredients = ["No ingredients information available"]
            debugLog("- Added placeholder ingredients")
        } else {
            debugLog("✅ Product has \(product.ingredients.count) ingredients")
        }
        
        // Ensure allergens list is initialized
        if product.allergens.isEmpty {
            debugLog("⚠️ Initializing empty allergens list")
            product.allergens = []
            debugLog("- Initialized empty allergens list")
        } else {
            debugLog("✅ Product has \(product.allergens.count) allergens")
        }
        
        // Ensure images list is initialized
        if product.images.isEmpty {
            debugLog("⚠️ Initializing empty images list")
            product.images = []
            debugLog("- Initialized empty images list")
        } else {
            debugLog("✅ Product has \(product.images.count) images")
        }
        
        // Ensure user notes is initialized
        if product.userNotes == nil {
            debugLog("⚠️ Adding placeholder user notes - original was nil")
            product.userNotes = "No detailed information available for this product."
            debugLog("- Added placeholder user notes")
        } else {
            let notesLength = product.userNotes?.count ?? 0
            debugLog("✅ Product has user notes (\(notesLength) characters)")
        }
        
        debugLog("✅ Product data validation complete for: \(product.name)")
    }
} 
