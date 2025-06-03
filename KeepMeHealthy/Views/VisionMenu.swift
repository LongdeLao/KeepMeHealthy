import SwiftUI

struct VisionoMenu: View {
    @Binding var isShowing: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var animationAmount: CGFloat = 0
    @State private var opacity: Double = 0
    
    var onLanguageChange: (String) -> Void
    var onDismiss: () -> Void
    
    // Available languages
    private let languages = [
        ("English", "en"),
        ("Español", "es"),
        ("Français", "fr"),
        ("Deutsch", "de"),
        ("中文", "zh")
    ]
    
    @State private var showingLanguagePicker = false
    @State private var showingSettings = false
    @State private var showScanHistory = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(isShowing ? 0.6 : 0)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissMenu()
                }
            
            // Menu panel
            VStack(spacing: 0) {
                // Menu header
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Menu")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: dismissMenu) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Top section buttons
                VStack(spacing: 15) {
                    MenuButton(
                        icon: "globe",
                        title: "Language",
                        subtitle: getCurrentLanguageName()
                    ) {
                        showingLanguagePicker.toggle()
                    }
                    
                    MenuButton(
                        icon: isDarkMode ? "sun.max.fill" : "moon.fill",
                        title: "Appearance",
                        subtitle: isDarkMode ? "Light Mode" : "Dark Mode"
                    ) {
                        withAnimation {
                            isDarkMode.toggle()
                        }
                    }
                    
                    MenuButton(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "Preferences & Account"
                    ) {
                        showingSettings.toggle()
                        dismissMenu()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 15)
                
                // Bottom section buttons
                VStack(spacing: 15) {
                    MenuButton(
                        icon: "chart.bar.fill",
                        title: "Nutrition Stats",
                        subtitle: "View your dietary trends"
                    ) {
                        // Will implement later
                        dismissMenu()
                    }
                    
                    MenuButton(
                        icon: "heart.fill",
                        title: "Health Goals",
                        subtitle: "Set and track progress"
                    ) {
                        // Will implement later
                        dismissMenu()
                    }
                    
                    MenuButton(
                        icon: "barcode.viewfinder",
                        title: "Scan History",
                        subtitle: "View all scanned products"
                    ) {
                        showScanHistory.toggle()
                        dismissMenu()
                    }
                    
                    MenuButton(
                        icon: "book.fill",
                        title: "Food Journal",
                        subtitle: "Track your daily consumption"
                    ) {
                        // Will implement later
                        dismissMenu()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Version info
                Text("KeepMeHealthy v1.0")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .offset(x: isShowing ? 0 : -320)
            .offset(x: animationAmount)
            .opacity(opacity)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: animationAmount)
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: isShowing) { newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 1
                    animationAmount = 0
                }
            } else {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 0
                    animationAmount = -320
                }
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(
                selectedLanguage: $appLanguage,
                languages: languages,
                onLanguageSelected: { lang in
                    appLanguage = lang
                    onLanguageChange(lang)
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(ProductViewModel())
        }
        .sheet(isPresented: $showScanHistory) {
            ScanHistoryView()
                .environmentObject(ProductViewModel())
        }
    }
    
    private func getCurrentLanguageName() -> String {
        if let langTuple = languages.first(where: { $0.1 == appLanguage }) {
            return langTuple.0
        }
        return "English"
    }
    
    private func dismissMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }
}

// Menu Button Component
struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 10)
        }
    }
}

// Language Picker Sheet
struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    let languages: [(String, String)]
    let onLanguageSelected: (String) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.1) { language in
                    Button(action: {
                        selectedLanguage = language.1
                        onLanguageSelected(language.1)
                        dismiss()
                    }) {
                        HStack {
                            Text(language.0)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language.1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
