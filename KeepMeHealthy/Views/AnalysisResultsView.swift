import SwiftUI

struct AnalysisResultsView: View {
    let product: FoodProduct
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var productViewModel: ProductViewModel
    
    @State private var selectedTab = 0
    @State private var showingIngredientDetails = false
    @State private var selectedIngredient: (name: String, explanation: String)?
    @State private var isProductLoaded = false
    @State private var parsedData: (
        concerningAdditives: [(name: String, explanation: String, concernLevel: String)], 
        summary: String,
        processingLevel: String,
        naturalContent: String,
        ingredientExplanations: [(name: String, explanation: String, concernLevel: String, concernReason: String?)],
        healthierAlternatives: String
    ) = ([], "Loading...", "Unknown", "Unknown", [], "")
    
    // Custom font family
    private let titleFont = Font.custom("Avenir-Medium", size: 20)
    private let headlineFont = Font.custom("Avenir-Heavy", size: 17)
    private let bodyFont = Font.custom("Avenir-Book", size: 15)
    private let captionFont = Font.custom("Avenir-Light", size: 13)
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .padding()
            
            Text("Loading product details...")
                .font(headlineFont)
                .foregroundColor(.primary)
            
            Text("This will take just a moment")
                .font(captionFont)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    // At the top of the file, add a debug logger function
    private func debugLog(_ message: String, function: String = #function) {
        print("📊 AnalysisResultsView[\(function)]: \(message)")
    }
    
    // Update the original parseUserNotes function to call the new one
    private func parseUserNotes() -> (concerningAdditives: [(name: String, explanation: String, concernLevel: String)], 
                                    summary: String,
                                    processingLevel: String,
                                    naturalContent: String,
                                    ingredientExplanations: [(name: String, explanation: String, concernLevel: String, concernReason: String?)],
                                    healthierAlternatives: String) {
        return parseUserNotes(from: product)
    }
    
    // Replace the incomplete parseUserNotes implementation with the complete one
    private func parseUserNotes(from product: FoodProduct) -> (concerningAdditives: [(name: String, explanation: String, concernLevel: String)],
                                                             summary: String,
                                                             processingLevel: String,
                                                             naturalContent: String,
                                                             ingredientExplanations: [(name: String, explanation: String, concernLevel: String, concernReason: String?)],
                                                             healthierAlternatives: String) {
        debugLog("🔍 Starting parseUserNotes for product: \(product.name)")
        
        // Default empty values
        var concerningAdditives: [(name: String, explanation: String, concernLevel: String)] = []
        var summary = "No summary available"
        var processingLevel = "Unknown"
        var naturalContent = "Unknown natural content percentage"
        var ingredientExplanations: [(name: String, explanation: String, concernLevel: String, concernReason: String?)] = []
        var healthierAlternatives = ""
        
        // Safety check for nil user notes
        guard let notes = product.userNotes, !notes.isEmpty else {
            debugLog("⚠️ No user notes available for product: \(product.name)")
            return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
        }
        
        debugLog("📝 Notes length: \(notes.count) characters")
        
        // First, try to parse as JSON if it contains DeepSeek response
        if notes.contains("DeepSeek response: ```json") {
            debugLog("🔄 Found DeepSeek JSON response format")
            do {
                let jsonStartMarker = "DeepSeek response: ```json"
                let jsonEndMarker = "```"
                
                guard let jsonStartRange = notes.range(of: jsonStartMarker),
                      let jsonEndRange = notes.range(of: jsonEndMarker, options: .backwards) else {
                    debugLog("⚠️ Could not find JSON markers in notes")
                    return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
                }
                
                let jsonStartIndex = notes.index(jsonStartRange.upperBound, offsetBy: 0)
                let jsonContent = notes[jsonStartIndex..<jsonEndRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                
                debugLog("📄 Extracted JSON content length: \(jsonContent.count) characters")
                
                guard let jsonData = jsonContent.data(using: .utf8) else {
                    debugLog("⚠️ Could not convert JSON content to data")
                    return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
                }
                
                let decoder = JSONDecoder()
                
                // Try a preliminary check if this is valid JSON
                if let _ = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                    debugLog("✅ JSON appears to be valid")
                } else {
                    debugLog("❌ JSON validation failed")
                    debugLog("📄 JSON content: \(jsonContent.prefix(100))...")
                    return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
                }
                
                do {
                    let response = try decoder.decode(ProductViewModel.DeepSeekResponse.self, from: jsonData)
                    debugLog("✅ Successfully decoded DeepSeekResponse")
                    
                    // Extract data from JSON response
                    if let simpleSummary = response.simpleSummary {
                        summary = simpleSummary
                    }
                    
                    if let processLevel = response.processingLevel {
                        processingLevel = processLevel.capitalized
                    }
                    
                    if let naturalPercentage = response.naturalContentPercentage {
                        naturalContent = "Approximately \(Int(naturalPercentage))% natural ingredients"
                    }
                    
                    // Map ingredients
                    ingredientExplanations = response.ingredients.map { ingredient in
                        return (
                            name: ingredient.name,
                            explanation: ingredient.explanation,
                            concernLevel: ingredient.concernLevel,
                            concernReason: ingredient.concernReason
                        )
                    }
                    
                    // Map concerning additives
                    if let additives = response.concerningAdditives {
                        concerningAdditives = additives.map { additive in
                            return (
                                name: additive.name,
                                explanation: additive.explanation,
                                concernLevel: additive.concernLevel
                            )
                        }
                    }
                    
                    // Get healthier alternatives
                    if let alternatives = response.recommendationsForHealthierOptions {
                        healthierAlternatives = alternatives
                    }
                    
                    debugLog("🔄 Parsed \(ingredientExplanations.count) ingredients and \(concerningAdditives.count) additives")
                    return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
                } catch {
                    debugLog("❌ Error decoding DeepSeekResponse: \(error)")
                }
            } catch {
                debugLog("❌ Error parsing DeepSeek JSON response: \(error)")
            }
        } else {
            debugLog("📝 Using traditional parsing (no JSON found)")
        }
        
        // Fall back to traditional parsing if JSON parsing didn't work
        let sections = notes.components(separatedBy: "\n\n")
        debugLog("📄 Found \(sections.count) sections for traditional parsing")
        
        for section in sections {
            if section.starts(with: "SUMMARY:") {
                summary = section.replacingOccurrences(of: "SUMMARY:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if section.starts(with: "PROCESSING LEVEL:") {
                processingLevel = section.replacingOccurrences(of: "PROCESSING LEVEL:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if section.starts(with: "NATURAL CONTENT:") {
                naturalContent = section.replacingOccurrences(of: "NATURAL CONTENT:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if section.starts(with: "INGREDIENT EXPLANATIONS:") {
                let content = section.replacingOccurrences(of: "INGREDIENT EXPLANATIONS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                // Parse ingredient explanations
                let items = content.components(separatedBy: "\n\n")
                for item in items {
                    // Parse concern level if present
                    var name = ""
                    var explanation = ""
                    var concernLevel = "none"
                    var concernReason: String? = nil
                    
                    if item.contains(" - CONCERN: ") {
                        let parts = item.components(separatedBy: " - CONCERN: ")
                        if parts.count >= 2 {
                            let namePart = parts[0]
                            let restPart = parts[1]
                            
                            if let colonIndex = namePart.firstIndex(of: ":") {
                                name = String(namePart[..<colonIndex])
                                explanation = String(namePart[namePart.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                                
                                if restPart.contains("Reason: ") {
                                    let concernParts = restPart.components(separatedBy: "\nReason: ")
                                    if concernParts.count >= 2 {
                                        concernLevel = concernParts[0].lowercased()
                                        concernReason = concernParts[1]
                                    } else {
                                        concernLevel = restPart.lowercased()
                                    }
                                } else {
                                    concernLevel = restPart.lowercased()
                                }
                            }
                        }
                    } else if let colonIndex = item.firstIndex(of: ":") {
                        name = String(item[..<colonIndex])
                        explanation = String(item[item.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    }
                    
                    if !name.isEmpty {
                        ingredientExplanations.append((name: name, explanation: explanation, concernLevel: concernLevel, concernReason: concernReason))
                    }
                }
            } else if section.starts(with: "CONCERNING ADDITIVES:") {
                let content = section.replacingOccurrences(of: "CONCERNING ADDITIVES:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                // Parse concerning additives
                let items = content.components(separatedBy: "\n\n")
                for item in items {
                    // Matches pattern: "Name (CONCERN: LEVEL): explanation"
                    if let nameRange = item.range(of: " \\(CONCERN: [A-Z]+\\): ", options: .regularExpression) {
                        let name = String(item[..<nameRange.lowerBound])
                        
                        // Extract concern level
                        let levelStartIndex = item.index(nameRange.lowerBound, offsetBy: 10) // Length of " (CONCERN: "
                        let levelEndIndex = item.index(nameRange.upperBound, offsetBy: -3) // Before "): "
                        let concernLevel = String(item[levelStartIndex..<levelEndIndex]).lowercased()
                        
                        let explanation = String(item[nameRange.upperBound...])
                        
                        concerningAdditives.append((name: name, explanation: explanation, concernLevel: concernLevel))
                    }
                }
            } else if section.starts(with: "HEALTHIER ALTERNATIVES:") {
                healthierAlternatives = section.replacingOccurrences(of: "HEALTHIER ALTERNATIVES:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        debugLog("✅ Traditional parsing complete")
        return (concerningAdditives, summary, processingLevel, naturalContent, ingredientExplanations, healthierAlternatives)
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern header with product name and close button
                HStack {
                    Text(product.name)
                        .font(titleFont)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        debugLog("Dismiss button tapped")
                        dismiss()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(.systemGray4))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Minimalist tab selection with SF Symbols
                HStack(spacing: 0) {
                    AnalysisTabButton(
                        title: "Summary",
                        icon: "text.viewfinder",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    AnalysisTabButton(
                        title: "Ingredients",
                        icon: "list.bullet.clipboard",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    AnalysisTabButton(
                        title: "Additives",
                        icon: "exclamationmark.shield",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.top, 8)
                
                // Content area
                if !isProductLoaded {
                    loadingView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            switch selectedTab {
                            case 0: // Summary
                                summaryView(summary: parsedData.summary, processingLevel: parsedData.processingLevel, naturalContent: parsedData.naturalContent, healthierAlternatives: parsedData.healthierAlternatives)
                            case 1: // Ingredients
                                ingredientsView(ingredientExplanations: parsedData.ingredientExplanations)
                            case 2: // Additives
                                additivesView(concerningAdditives: parsedData.concerningAdditives)
                            default:
                                Text("Tab not implemented")
                                    .font(bodyFont)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Minimal footer
                Divider()
                
                HStack(spacing: 20) {
                    Button(action: {
                        productViewModel.toggleFavorite(for: product.id)
                    }) {
                        Label(
                            product.isFavorite ? "Saved" : "Save",
                            systemImage: product.isFavorite ? "heart.fill" : "heart"
                        )
                        .font(bodyFont)
                        .foregroundColor(product.isFavorite ? .red : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        debugLog("Dismissing to camera")
                        // First dismiss this view
                        dismiss()
                        presentationMode.wrappedValue.dismiss()
                        
                        // Then use NotificationCenter to tell the parent view to return to scanning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("ReturnToScanning"), object: nil)
                        }
                    }) {
                        Label("Scan Again", systemImage: "camera.fill")
                            .font(bodyFont)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color("Tab")))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        debugLog("Closing results view")
                        dismiss()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Close", systemImage: "arrow.down.circle.fill")
                            .font(bodyFont)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.systemGray6)))
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingIngredientDetails) {
            if let ingredient = selectedIngredient {
                MinimalDetailView(name: ingredient.name, explanation: ingredient.explanation)
            }
        }
        .onAppear {
            debugLog("🔄 AnalysisResultsView appeared for product: \(product.name)")
           
            
            // Ensure the product is properly loaded
            isProductLoaded = false // Start with loading state
            
            DispatchQueue.main.async {
                // Try to preload the product with proper initialization
                do {
                    // Add delay for database context to be fully ready
                    try Task {
                        // Preload the product first to ensure all fields are initialized
                        debugLog("🔄 Starting product preload")
                        let startTime = Date()
                        let preloadedProduct = productViewModel.preloadProduct(product)
                        let loadTime = Date().timeIntervalSince(startTime)
                        debugLog("✅ Product preloaded successfully in \(loadTime) seconds")
                        
                        // Update our reference to use the preloaded product
                        if preloadedProduct.id == product.id {
                            debugLog("✓ Product ID match confirmed")
                            // Only parse if we have user notes
                            if preloadedProduct.userNotes != nil && !preloadedProduct.userNotes!.isEmpty {
                                // Try to parse the user notes
                                debugLog("🔄 Starting to parse user notes")
                                parsedData = parseUserNotes(from: preloadedProduct)
                                debugLog("✓ Parsed data: summary length: \(parsedData.summary.count), ingredients: \(parsedData.ingredientExplanations.count)")
                            } else {
                                debugLog("⚠️ No user notes to parse")
                                // Set fallback data
                                parsedData.summary = "No detailed information available for this product."
                            }
                        } else {
                           
                        }
                        
                        // Always mark as loaded to prevent infinite loading state
                        isProductLoaded = true
                        debugLog("✅ Product fully initialized with parsed data")
                    }
                } catch {
                    debugLog("❌ Error during product initialization: \(error)")
                    // Still mark as loaded to prevent infinite loading state
                    isProductLoaded = true
                    
                    // Set basic data
                    parsedData.summary = "Error loading product details."
                    parsedData.processingLevel = "Unknown"
                    parsedData.naturalContent = "Unknown"
                }
            }
        }
    }
    
    // Summary tab view - enhanced with SF Symbols
    private func summaryView(summary: String, processingLevel: String, naturalContent: String, healthierAlternatives: String) -> some View {
        // Pre-compute processing level values
        let (icon, iconColor) = getProcessingLevelIconInfo(level: processingLevel)
        
        return VStack(alignment: .leading, spacing: 18) {
            // Product info with icon
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color("Tab").opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("Tab"))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(titleFont)
                    
                    if let brand = product.brand {
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(brand)
                                .font(captionFont)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Health metrics card
            VStack(spacing: 4) {
                HStack {
                    Label(
                        "Processing Level",
                        systemImage: "gauge"
                    )
                    .font(headlineFont)
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // Processing level indicator
                HStack(spacing: 12) {
                    processingLevelIndicator(level: processingLevel)
                        .frame(width: 12, height: 12)
                    
                    Text("\(processingLevel.capitalized)")
                        .font(bodyFont)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                .padding(.bottom, 8)
                
                // Natural content
                HStack {
                    Label(
                        "Natural Content",
                        systemImage: "leaf"
                    )
                    .font(bodyFont)
                    
                    Spacer()
                    
                    Text(naturalContent)
                        .font(bodyFont)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Product summary
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    "Summary",
                    systemImage: "text.alignleft"
                )
                .font(headlineFont)
                .foregroundColor(.primary)
                
                Text(summary)
                    .font(bodyFont)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Allergens - if there are any
            if !product.allergens.isEmpty {
                Divider()
                    .padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        "Allergens",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(headlineFont)
                    .foregroundColor(.primary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(product.allergens, id: \.self) { allergen in
                            HStack(spacing: 4) {
                                Image(systemName: "allergens")
                                    .font(.system(size: 10))
                                
                                Text(allergen)
                                    .font(.custom("Avenir-Medium", size: 13))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Healthier alternatives if available
            if !healthierAlternatives.isEmpty {
                Divider()
                    .padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        "Healthier Alternatives",
                        systemImage: "arrow.triangle.swap"
                    )
                    .font(headlineFont)
                    
                    Text(healthierAlternatives)
                        .font(bodyFont)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // Helper function to get icon and color for processing level
    private func getProcessingLevelIconInfo(level: String) -> (icon: String, color: Color) {
        switch level.lowercased() {
        case "minimally":
            return ("leaf.fill", .green)
        case "moderately":
            return ("exclamationmark.triangle", .orange)
        case "highly":
            return ("exclamationmark.octagon.fill", .red)
        default:
            return ("questionmark", .gray)
        }
    }
    
    // Ingredients tab view - enhanced with SF Symbols
    private func ingredientsView(ingredientExplanations: [(name: String, explanation: String, concernLevel: String, concernReason: String?)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !product.ingredients.isEmpty {
                // Ingredients list
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        "Ingredients",
                        systemImage: "list.bullet"
                    )
                    .font(headlineFont)
                    
                    Text(product.ingredients.joined(separator: ", "))
                        .font(bodyFont)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !ingredientExplanations.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Ingredients details
                    Label(
                        "Ingredient Details",
                        systemImage: "square.grid.2x2"
                    )
                    .font(headlineFont)
                    
                    ForEach(ingredientExplanations, id: \.name) { ingredient in
                        IngredientCard(
                            ingredient: ingredient,
                            onTap: {
                                selectedIngredient = (
                                    name: ingredient.name,
                                    explanation: ingredient.explanation + 
                                    (ingredient.concernLevel != "none" ? 
                                    "\n\nConcern level: \(ingredient.concernLevel.capitalized)" : "") +
                                    (ingredient.concernReason != nil ? 
                                    "\n\nReason for concern: \(ingredient.concernReason!)" : "")
                                )
                                showingIngredientDetails = true
                            }
                        )
                    }
                } else {
                    EmptyContentView(
                        icon: "magnifyingglass",
                        message: "No detailed ingredient information available"
                    )
                }
            } else {
                EmptyContentView(
                    icon: "list.bullet",
                    message: "No ingredient information available"
                )
            }
        }
    }
    
    // Additives tab view - enhanced with SF Symbols
    private func additivesView(concerningAdditives: [(name: String, explanation: String, concernLevel: String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "Concerning Additives",
                systemImage: "exclamationmark.triangle"
            )
            .font(headlineFont)
            
            if !concerningAdditives.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        
                        Text("These ingredients may have negative health implications.")
                            .font(captionFont)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 12)
                }
                
                ForEach(concerningAdditives, id: \.name) { additive in
                    AdditiveCard(
                        additive: additive,
                        onTap: {
                            selectedIngredient = (
                                name: additive.name,
                                explanation: additive.explanation + 
                                    "\n\nConcern level: \(additive.concernLevel.capitalized)"
                            )
                            showingIngredientDetails = true
                        }
                    )
                }
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    Text("No concerning additives identified")
                        .font(bodyFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            }
        }
    }
    
    // Processing level indicator - simplified
    private func processingLevelIndicator(level: String) -> some View {
        // Pre-compute the color outside the view
        let color = getProcessingLevelColor(level: level)
        
        return Circle()
            .fill(color)
    }
    
    // Helper function to get color for processing level
    private func getProcessingLevelColor(level: String) -> Color {
        switch level.lowercased() {
        case "minimally":
            return .green
        case "moderately":
            return .orange
        case "highly":
            return .red
        default:
            return .gray
        }
    }
    
    // Concern level pill - modern and minimal
    private func concernLevelPill(level: String) -> some View {
        // Pre-compute values outside the view
        let (color, icon) = getConcernLevelInfo(level: level)
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            
            Text(level.uppercased())
                .font(.custom("Avenir-Heavy", size: 9))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.15)))
        .foregroundColor(color)
    }
    
    // Helper function to get color and icon for concern level
    private func getConcernLevelInfo(level: String) -> (color: Color, icon: String) {
        switch level.lowercased() {
        case "low":
            return (.yellow, "exclamationmark.circle")
        case "medium":
            return (.orange, "exclamationmark.triangle")
        case "high":
            return (.red, "exclamationmark.octagon")
        default:
            return (.green, "checkmark.circle")
        }
    }
}

// MARK: - Supporting Views

// Tab button for custom tab bar
struct AnalysisTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.custom("Avenir-Medium", size: 12))
            }
            .foregroundColor(isSelected ? Color("Tab") : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                Rectangle()
                    .fill(Color("Tab").opacity(0.1))
                    .cornerRadius(10)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Ingredient card for a cleaner look
struct IngredientCard: View {
    let ingredient: (name: String, explanation: String, concernLevel: String, concernReason: String?)
    let onTap: () -> Void
    
    var body: some View {
        // Compute values before the view
        let (icon, color) = getIconAndColor(concernLevel: ingredient.concernLevel)
        let showConcernLevel = ingredient.concernLevel != "none"
        
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon based on pre-computed values
                if showConcernLevel {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ingredient.name)
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.primary)
                        
                        if showConcernLevel {
                            Spacer()
                            
                            Text(ingredient.concernLevel.uppercased())
                                .font(.custom("Avenir-Heavy", size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.15)))
                                .foregroundColor(color)
                        }
                    }
                    
                    Text(ingredient.explanation.prefix(120) + (ingredient.explanation.count > 120 ? "..." : ""))
                        .font(.custom("Avenir-Book", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to get icon and color based on concern level
    private func getIconAndColor(concernLevel: String) -> (icon: String, color: Color) {
        switch concernLevel.lowercased() {
        case "low":
            return ("exclamationmark.circle", .yellow)
        case "medium":
            return ("exclamationmark.triangle", .orange)
        case "high":
            return ("exclamationmark.octagon", .red)
        default:
            return ("leaf", .green)
        }
    }
}

// Additive card for a cleaner look
struct AdditiveCard: View {
    let additive: (name: String, explanation: String, concernLevel: String)
    let onTap: () -> Void
    
    var body: some View {
        // Compute values before the view
        let (icon, color) = getIconAndColor(concernLevel: additive.concernLevel)
        
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon using pre-computed values
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(additive.name)
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(additive.concernLevel.uppercased())
                            .font(.custom("Avenir-Heavy", size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(0.15)))
                            .foregroundColor(color)
                    }
                    
                    Text(additive.explanation.prefix(120) + (additive.explanation.count > 120 ? "..." : ""))
                        .font(.custom("Avenir-Book", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to get icon and color based on concern level
    private func getIconAndColor(concernLevel: String) -> (icon: String, color: Color) {
        switch concernLevel.lowercased() {
        case "low":
            return ("exclamationmark.circle", .yellow)
        case "medium":
            return ("exclamationmark.triangle", .orange)
        case "high":
            return ("exclamationmark.octagon", .red)
        default:
            return ("checkmark.circle", .green)
        }
    }
}

// Empty content view
struct EmptyContentView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
            
            Text(message)
                .font(.custom("Avenir-Book", size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 30)
    }
}

// Detail view for ingredients and additives - minimalistic
struct MinimalDetailView: View {
    let name: String
    let explanation: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(name)
                    .font(.custom("Avenir-Heavy", size: 18))
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.systemGray4))
                }
            }
            
            Divider()
            
            // Content
            ScrollView {
                Text(explanation)
                    .font(.custom("Avenir-Book", size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Flow layout for allergen tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var width: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += size.height + spacing
            }
            
            if currentX + size.width > width {
                width = min(currentX + size.width, containerWidth)
            }
            
            currentX += size.width + spacing
        }
        
        height = currentY + (subviews.last?.sizeThatFits(.unspecified).height ?? 0)
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += size.height + spacing
            }
            
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
        }
    }
}

struct AnalysisResultsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisResultsView(product: FoodProduct.sampleProducts()[0])
            .environmentObject(ProductViewModel())
    }
} 
