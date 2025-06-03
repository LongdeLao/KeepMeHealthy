import SwiftUI

struct HomeView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var searchText = ""
    @State private var searchResults: [FoodProduct] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BG").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search products", text: $searchText)
                                .foregroundColor(.primary)
                                .onChange(of: searchText) { newValue in
                                    if newValue.isEmpty {
                                        isSearching = false
                                        searchResults = []
                                    } else {
                                        isSearching = true
                                        searchResults = productViewModel.searchProducts(query: newValue)
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    isSearching = false
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        if isSearching {
                            // Search results
                            VStack(alignment: .leading) {
                                Text("Search Results")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                if searchResults.isEmpty {
                                    Text("No products found")
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    ForEach(searchResults) { product in
                                        SearchResultRow(product: product)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // Main content when not searching
                            
                            
                            // Recent Items
                            VStack(alignment: .leading) {
                                Text("Recently Viewed")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(productViewModel.getRecentProducts(limit: 10)) { product in
                                            RecentProductCard(product: product)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Categories section
                            VStack(alignment: .leading) {
                                Text("Categories")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 15) {
                                    CategoryCard(icon: "heart.fill", color: Color("Pink"), title: "Favorites")
                                    CategoryCard(icon: "exclamationmark.triangle.fill", color: Color("DarkBlue"), title: "Allergens")
                                    CategoryCard(icon: "chart.bar.fill", color: Color("LightBlue"), title: "Nutrition")
                                    CategoryCard(icon: "clock.fill", color: .orange, title: "History")
                                }
                                .padding(.horizontal)
                            }
                            
                            // Tips section
                            VStack(alignment: .leading) {
                                Text("Health Tips")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 15) {
                                    TipCard(
                                        title: "Reduce Sugar Intake",
                                        description: "Try to limit products with added sugars for better health.",
                                        icon: "drop.fill",
                                        color: .red
                                    )
                                    
                                    TipCard(
                                        title: "Choose Whole Grains",
                                        description: "Whole grains provide more nutrients and fiber than refined grains.",
                                        icon: "leaf.fill",
                                        color: .green
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Keep Me Healthy")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// Component for Recent Product Cards
struct RecentProductCard: View {
    let product: FoodProduct
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Display category icon based on product category
                Image(systemName: iconForCategory(product.categoryEnum))
                    .font(.system(size: 40))
                    .foregroundColor(Color("Tab"))
            }
            
            Text(product.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(product.categoryEnum.rawValue)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 120)
    }
    
    // Helper to return icon based on category
    private func iconForCategory(_ category: FoodProduct.Category) -> String {
        switch category {
        case .dairy:
            return "cup.and.saucer.fill"
        case .bakery:
            return "takeoutbag.and.cup.and.straw.fill"
        case .produce:
            return "leaf.fill"
        case .meat:
            return "fork.knife"
        case .seafood:
            return "fish.fill"
        case .snacks:
            return "popcorn.fill"
        case .beverages:
            return "mug.fill"
        case .frozen:
            return "snowflake"
        case .pantry:
            return "cabinet.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}

// Search Result Row
struct SearchResultRow: View {
    let product: FoodProduct
    
    var body: some View {
        HStack(spacing: 15) {
            // Product icon/image
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("BG"))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconForCategory(product.categoryEnum))
                    .font(.system(size: 30))
                    .foregroundColor(Color("Tab"))
            }
            
            // Product details
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let brand = product.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(product.categoryEnum.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color("Tab"))
                        .cornerRadius(10)
                    
                    if let healthScore = product.healthScore {
                        Text("Health: \(healthScore)%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(healthScoreColor(healthScore))
                            .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            // Date scanned
            Text(formattedDate(product.dateScanned))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // Helper to return icon based on category
    private func iconForCategory(_ category: FoodProduct.Category) -> String {
        switch category {
        case .dairy:
            return "cup.and.saucer.fill"
        case .bakery:
            return "takeoutbag.and.cup.and.straw.fill"
        case .produce:
            return "leaf.fill"
        case .meat:
            return "fork.knife"
        case .seafood:
            return "fish.fill"
        case .snacks:
            return "popcorn.fill"
        case .beverages:
            return "mug.fill"
        case .frozen:
            return "snowflake"
        case .pantry:
            return "cabinet.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
    
    // Helper to color code health score
    private func healthScoreColor(_ score: Int) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Format date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Component for Category Cards
struct CategoryCard: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Component for Tip Cards
struct TipCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(ProductViewModel()) // Add the environment object for previews
} 
