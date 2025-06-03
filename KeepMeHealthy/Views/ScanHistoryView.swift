import SwiftUI
import SwiftData

struct ScanHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var searchText = ""
    @State private var selectedCategory: FoodProduct.Category?
    @State private var showingDeleteAlert = false
    @State private var showingProductDetails = false
    @State private var selectedProduct: FoodProduct?
    @State private var isLoading = false
    
    // Custom font family
    private let titleFont = Font.custom("Avenir-Heavy", size: 24)
    private let headlineFont = Font.custom("Avenir-Medium", size: 18)
    private let bodyFont = Font.custom("Avenir-Book", size: 16)
    private let captionFont = Font.custom("Avenir-Light", size: 14)
    
    // Get products based on current filter state
    private var filteredProducts: [FoodProduct] {
        var products: [FoodProduct]
        
        if let category = selectedCategory {
            products = productViewModel.getProductsByCategory(category)
        } else {
            products = productViewModel.getRecentProducts(limit: 100)
        }
        
        if !searchText.isEmpty {
            products = products.filter { product in
                product.name.lowercased().contains(searchText.lowercased()) ||
                (product.brand?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
        
        return products
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    VStack(spacing: 8) {
                        HStack {
                            Text("Scan History")
                                .font(titleFont)
                            
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(.systemGray4))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            TextField("Search scans", text: $searchText)
                                .font(bodyFont)
                                .padding(8)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Category filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                CategoryPill(
                                    title: "All",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(FoodProduct.Category.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category,
                                        action: { 
                                            if selectedCategory == category {
                                                selectedCategory = nil
                                            } else {
                                                selectedCategory = category
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Divider()
                    
                    // Content
                    if filteredProducts.isEmpty {
                        emptyStateView
                    } else {
                        historyListView
                    }
                }
            }
            .sheet(isPresented: $showingProductDetails) {
                if let product = selectedProduct {
                 
                    AnalysisResultsView(product: product)
                        .environmentObject(productViewModel)
                } else {
                    // Fallback view if product is nil
                   
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Product")
                            .font(headlineFont)
                        
                        Text("There was a problem loading this product. Please try again later.")
                            .font(bodyFont)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            showingProductDetails = false
                        }) {
                            Text("Close")
                                .font(bodyFont)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color("Tab"))
                                )
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Clear History"),
                    message: Text("Are you sure you want to delete all scan history? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        productViewModel.clearHistory()
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Loading product...")
                                .font(bodyFont)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: isLoading)
                }
            }
        }
    }
    
    // Empty state view when no products are found
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(Color(.systemGray3))
            
            Text(searchText.isEmpty ? "No scan history yet" : "No matching scans found")
                .font(headlineFont)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    selectedCategory = nil
                }) {
                    Text("Clear Search")
                        .font(bodyFont)
                        .foregroundColor(Color("Tab"))
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // History list view with products
    private var historyListView: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredProducts) { product in
                        ProductHistoryCard(product: product)
                            .onTapGesture {
                                debugLog("👆 User tapped on product: \(product.name), ID: \(product.id)")
                                
                                // Show loading indicator
                                isLoading = true
                                debugLog("⏳ Setting isLoading to true")
                                
                                // Log product state before loading
                                debugLog("📋 Before preload - product has \(product.ingredients.count) ingredients, \(product.allergens.count) allergens")
                                debugLog("📋 Before preload - product has notes: \(product.userNotes?.count ?? 0) characters")
                                debugLog("📋 Before preload - product category: \(product.category)")
                                debugLog("📋 Before preload - product has nutritionFacts: \(product.nutritionFacts != nil)")
                                
                                // Load product data in background
                                DispatchQueue.global(qos: .userInitiated).async {
                                    debugLog("🔄 Starting background preload process")
                                    
                                    // Preload the product first
                                    let startTime = Date()
                                    debugLog("⏱️ Preload started at: \(startTime)")
                                    let preloadedProduct = productViewModel.preloadProduct(product)
                                    let loadTime = Date().timeIntervalSince(startTime)
                                    
                                    // Log product state after loading
                                    debugLog("📋 After preload - product has \(preloadedProduct.ingredients.count) ingredients, \(preloadedProduct.allergens.count) allergens")
                                    debugLog("📋 After preload - product has notes: \(preloadedProduct.userNotes?.count ?? 0) characters")
                                    debugLog("📋 After preload - product category: \(preloadedProduct.category)")
                                    debugLog("📋 After preload - product has nutritionFacts: \(preloadedProduct.nutritionFacts != nil)")
                                    debugLog("⏱️ Preload completed in \(loadTime) seconds")
                                    
                                    // Validate the product is ready to display
                                    if preloadedProduct.ingredients.isEmpty && preloadedProduct.nutritionFacts == nil {
                                        debugLog("⚠️ Preloaded product data is incomplete, may not display correctly")
                                    }
                                    
                                    // Slight delay to ensure UI is ready
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        debugLog("🔄 Processing UI updates on main thread")
                                        isLoading = false
                                        debugLog("⏳ Setting isLoading to false")
                                        selectedProduct = preloadedProduct
                                        debugLog("🔄 Set selectedProduct to: \(preloadedProduct.name)")
                                        showingProductDetails = true
                                        debugLog("🔄 Set showingProductDetails to true")
                                        debugLog("✅ Showing analysis results view for product: \(preloadedProduct.name)")
                                    }
                                }
                            }
                    }
                }
                .padding()
                .padding(.bottom, 70) // Space for the floating button
            }
            
            // Clear history button
            VStack {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear History")
                    }
                    .font(bodyFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.2), radius: 4)
                    )
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // Add debug logger function at the top of the file
    private func debugLog(_ message: String, function: String = #function) {
        print("📜 ScanHistoryView[\(function)]: \(message)")
    }
}

// Category pill component
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Avenir-Medium", size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("Tab") : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// Product history card
struct ProductHistoryCard: View {
    let product: FoodProduct
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Product category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 22))
                    .foregroundColor(categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(product.name)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if product.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if let brand = product.brand {
                    Text(brand)
                        .font(.custom("Avenir-Book", size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label(
                        product.categoryEnum.rawValue,
                        systemImage: "tag"
                    )
                    .font(.custom("Avenir-Light", size: 13))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: product.dateScanned))
                        .font(.custom("Avenir-Light", size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Health score indicator
                if let healthScore = product.healthScore {
                    HStack(spacing: 8) {
                        Text("Health Score")
                            .font(.custom("Avenir-Light", size: 12))
                            .foregroundColor(.secondary)
                        
                        HealthScoreBar(score: healthScore)
                    }
                    .padding(.top, 4)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Get icon for product category
    private var categoryIcon: String {
        switch product.categoryEnum {
        case .dairy: return "cup.and.saucer"
        case .produce: return "leaf"
        case .bakery: return "birthday.cake"
        case .meat: return "fork.knife"
        case .seafood: return "fish"
        case .snacks: return "popcorn"
        case .beverages: return "drop"
        case .frozen: return "snowflake"
        case .pantry: return "cabinet"
        case .other: return "shippingbox"
        }
    }
    
    // Get color for product category
    private var categoryColor: Color {
        switch product.categoryEnum {
        case .dairy: return .blue
        case .produce: return .green
        case .bakery: return .orange
        case .meat: return .red
        case .seafood: return .cyan
        case .snacks: return .yellow
        case .beverages: return .purple
        case .frozen: return .mint
        case .pantry: return .brown
        case .other: return .gray
        }
    }
}

// Health score bar component
struct HealthScoreBar: View {
    let score: Int
    
    private var healthColor: Color {
        switch score {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)
                
                // Filled bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(healthColor)
                    .frame(width: CGFloat(score) / 100 * geometry.size.width, height: 6)
            }
        }
        .frame(height: 6)
        .overlay(alignment: .trailing) {
            Text("\(score)")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(healthColor)
                .offset(y: -10)
        }
    }
}

struct ScanHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ScanHistoryView()
            .environmentObject(ProductViewModel())
    }
} 
