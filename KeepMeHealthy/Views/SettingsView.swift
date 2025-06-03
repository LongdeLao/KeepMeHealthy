import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    
    // Local state for user preferences that will be saved to the model
    @State private var prioritizeSpeed = false
    @State private var offlineMode = false
    @State private var enableNotifications = true
    @State private var selectedLanguage = "English"
    @State private var apiKey = "sk-dummy-api-key-12345"
    @State private var isEditingApiKey = false
    
    // Dietary preferences
    @State private var isVegetarian = false
    @State private var isVegan = false
    @State private var isGlutenFree = false
    @State private var isLactoseIntolerant = false
    @State private var isKeto = false
    @State private var isLowCarb = false
    
    // Allergen alerts
    @State private var allergenAlerts: [String] = []
    @State private var newAllergen = ""
    @State private var showingAllergenSheet = false
    
    // Available languages
    private let languages = ["English", "Spanish", "French", "German", "Chinese"]
    
    // Common allergens for selection
    private let commonAllergens = [
        "Milk", "Eggs", "Fish", "Shellfish", "Tree Nuts", 
        "Peanuts", "Wheat", "Soybeans", "Sesame"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BG").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Account Section
                        SettingsSection(title: "Account") {
                            NavigationLink(destination: Text("Account Details View")) {
                                SettingsRow(icon: "person.fill", iconColor: Color("Tab"), title: "Account Information")
                            }
                            
                            NavigationLink(destination: Text("Subscription Details View")) {
                                SettingsRow(icon: "creditcard.fill", iconColor: .green, title: "Subscription")
                            }
                        }
                        
                        // API Configuration Section
                        SettingsSection(title: "API Configuration") {
                            VStack(alignment: .leading) {
                                SettingsRow(icon: "key.fill", iconColor: .yellow, title: "API Key") {
                                    if isEditingApiKey {
                                        TextField("Enter API Key", text: $apiKey)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 150)
                                    } else {
                                        Text(apiKey.prefix(8) + "..." + apiKey.suffix(4))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Button(action: {
                                        if isEditingApiKey {
                                            // Save API key to preferences
                                            var preferences = productViewModel.userPreferences
                                            preferences.apiKey = apiKey
                                            productViewModel.updatePreferences(preferences: preferences)
                                        }
                                        isEditingApiKey.toggle()
                                    }) {
                                        Text(isEditingApiKey ? "Save" : "Edit")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color("Tab"))
                                            .cornerRadius(5)
                                    }
                                }
                                
                                Text("Your API key is securely stored and used to process product scans")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 45)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            SettingsToggleRow(
                                icon: "bolt.fill",
                                iconColor: .orange,
                                title: "Prioritize Speed",
                                subtitle: "Faster results with slightly lower accuracy",
                                isOn: $prioritizeSpeed
                            )
                            
                            SettingsToggleRow(
                                icon: "arrow.down.circle.fill",
                                iconColor: .blue,
                                title: "Offline Mode",
                                subtitle: "Use cached data when no internet connection is available",
                                isOn: $offlineMode
                            )
                            
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: .red,
                                title: "Notifications",
                                subtitle: "Receive alerts about nutrition facts and health tips",
                                isOn: $enableNotifications
                            )
                            
                            SettingsRow(icon: "globe", iconColor: .purple, title: "Language") {
                                Picker("", selection: $selectedLanguage) {
                                    ForEach(languages, id: \.self) { language in
                                        Text(language).tag(language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 120)
                            }
                        }
                        
                        // Dietary Preferences Section
                        SettingsSection(title: "Dietary Preferences") {
                            SettingsToggleRow(
                                icon: "leaf.fill",
                                iconColor: .green,
                                title: "Vegetarian",
                                subtitle: "Exclude products with meat and fish",
                                isOn: $isVegetarian
                            )
                            
                            SettingsToggleRow(
                                icon: "leaf.fill",
                                iconColor: .green,
                                title: "Vegan",
                                subtitle: "Exclude all animal products including dairy and eggs",
                                isOn: $isVegan
                            )
                            
                            SettingsToggleRow(
                                icon: "allergens",
                                iconColor: .orange,
                                title: "Gluten Free",
                                subtitle: "Exclude products containing gluten (wheat, barley, rye)",
                                isOn: $isGlutenFree
                            )
                            
                            SettingsToggleRow(
                                icon: "drop.fill",
                                iconColor: .blue,
                                title: "Lactose Intolerant",
                                subtitle: "Exclude products containing lactose",
                                isOn: $isLactoseIntolerant
                            )
                            
                            SettingsToggleRow(
                                icon: "flame.fill",
                                iconColor: .red,
                                title: "Keto Diet",
                                subtitle: "Highlight low-carb, high-fat products",
                                isOn: $isKeto
                            )
                            
                            SettingsToggleRow(
                                icon: "chart.bar.fill",
                                iconColor: .blue,
                                title: "Low Carb Diet",
                                subtitle: "Highlight products with reduced carbohydrates",
                                isOn: $isLowCarb
                            )
                        }
                        
                        // Allergen Alerts Section
                        SettingsSection(title: "Allergen Alerts") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Get warnings about products containing your allergens")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(allergenAlerts, id: \.self) { allergen in
                                    HStack {
                                        Text(allergen)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            allergenAlerts.removeAll { $0 == allergen }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                                
                                Button(action: {
                                    showingAllergenSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color("Tab"))
                                        
                                        Text("Add Allergen")
                                            .foregroundColor(Color("Tab"))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                                .sheet(isPresented: $showingAllergenSheet) {
                                    AllergenSelectionView(allergenAlerts: $allergenAlerts, commonAllergens: commonAllergens)
                                }
                            }
                            .padding(.vertical)
                        }
                        
                        // Data Management Section
                        SettingsSection(title: "Data Management") {
                            Button(action: {
                                productViewModel.clearHistory()
                            }) {
                                SettingsRow(icon: "trash.fill", iconColor: .red, title: "Clear Scan History")
                            }
                            
                            Button(action: {
                                // Export data action would go here
                            }) {
                                SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .blue, title: "Export Your Data")
                            }
                        }
                        
                        // About Section
                        SettingsSection(title: "About") {
                            NavigationLink(destination: Text("Help & FAQ View")) {
                                SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "Help & FAQ")
                            }
                            
                            NavigationLink(destination: Text("Privacy Policy View")) {
                                SettingsRow(icon: "lock.fill", iconColor: .gray, title: "Privacy Policy")
                            }
                            
                            SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "Version") {
                                Text("1.0.0")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load current preferences when the view appears
                let preferences = productViewModel.userPreferences
                prioritizeSpeed = preferences.prioritizeSpeed
                offlineMode = preferences.offlineMode
                enableNotifications = preferences.notificationsEnabled
                selectedLanguage = preferences.language
                apiKey = preferences.apiKey ?? "sk-dummy-api-key-12345"
                
                // Dietary preferences
                isVegetarian = preferences.isVegetarian
                isVegan = preferences.isVegan
                isGlutenFree = preferences.isGlutenFree
                isLactoseIntolerant = preferences.isLactoseIntolerant
                isKeto = preferences.isKeto
                isLowCarb = preferences.isLowCarb
                
                // Allergen alerts
                allergenAlerts = preferences.allergenAlerts
            }
            .onDisappear {
                // Save preferences when the view disappears
                var preferences = UserPreferences()
                preferences.prioritizeSpeed = prioritizeSpeed
                preferences.offlineMode = offlineMode
                preferences.notificationsEnabled = enableNotifications
                preferences.language = selectedLanguage
                preferences.apiKey = apiKey
                
                // Dietary preferences
                preferences.isVegetarian = isVegetarian
                preferences.isVegan = isVegan
                preferences.isGlutenFree = isGlutenFree
                preferences.isLactoseIntolerant = isLactoseIntolerant
                preferences.isKeto = isKeto
                preferences.isLowCarb = isLowCarb
                
                // Allergen alerts
                preferences.allergenAlerts = allergenAlerts
                
                productViewModel.updatePreferences(preferences: preferences)
            }
        }
    }
}

// Allergen Selection View
struct AllergenSelectionView: View {
    @Binding var allergenAlerts: [String]
    @State private var customAllergen = ""
    let commonAllergens: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Common Allergens")) {
                        ForEach(commonAllergens, id: \.self) { allergen in
                            Button(action: {
                                if !allergenAlerts.contains(allergen) {
                                    allergenAlerts.append(allergen)
                                }
                            }) {
                                HStack {
                                    Text(allergen)
                                    Spacer()
                                    if allergenAlerts.contains(allergen) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    
                    Section(header: Text("Add Custom Allergen")) {
                        HStack {
                            TextField("Enter allergen name", text: $customAllergen)
                            
                            Button(action: {
                                if !customAllergen.isEmpty && !allergenAlerts.contains(customAllergen) {
                                    allergenAlerts.append(customAllergen)
                                    customAllergen = ""
                                }
                            }) {
                                Text("Add")
                                    .foregroundColor(customAllergen.isEmpty ? .gray : Color("Tab"))
                            }
                            .disabled(customAllergen.isEmpty)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Allergens")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Section container component
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// Standard settings row
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let trailing: Trailing
    
    init(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .cornerRadius(8)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            trailing
        }
        .padding()
        .background(Color.white)
    }
}

// Toggle settings row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProductViewModel()) // Add the environment object for previews
} 