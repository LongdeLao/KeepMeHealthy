import SwiftUI
import AVFoundation
import Vision
import UIKit

// VisionOS Style Menu Components
struct VisionOSStyleView<Content: View>: View {
    var cornerRadius: CGFloat = 30
    @ViewBuilder var content: Content
    /// View Properties
    @State private var viewSize: CGSize = .zero
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        content
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .background {
                BackgroundView()
            }
            .compositingGroup()
            /// Shadows (Optional)
            .shadow(color: .black.opacity(0.2), radius: 15, x: 8, y: 8)
            .shadow(color: .black.opacity(0.15), radius: 15, x: -5, y: -5)
    }
    
    /// VisionOS Style Background
    @ViewBuilder
    private func BackgroundView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.thinMaterial, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.65))
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.shadow(.inner(color: .black.opacity(0.15), radius: 10)))
                .opacity(0.7)
        }
        .compositingGroup()
    }
}

extension ColorScheme {
    var currentColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        @unknown default: 
            return .clear
        }
    }
}

struct MenuBarControls: View {
    @Binding var showHistory: Bool
    @Binding var isMenuExpanded: Bool
    @Binding var isDarkMode: Bool
    @Binding var appLanguage: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Animation properties
    @State private var showButtons = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Top controls row with 3 buttons
            HStack(spacing: 15) {
                // Language button
                Button {
                    toggleLanguage()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        Text(appLanguage.prefix(2))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : -10)
                
                // Theme toggle
                Button {
                    isDarkMode.toggle()
                    // This would typically toggle the app's theme
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 18))
                        Text(isDarkMode ? "Dark" : "Light")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : -10)
                
                // Settings button
                Button {
                    // Open settings
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                        Text("Settings")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : -10)
            }
            .padding(.top, 8)
            
            /// Custom Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 8)
                .opacity(showButtons ? 1 : 0)
            
            /// Custom Buttons - Creative options
            FeatureButton(title: "Scan History", icon: "clock.arrow.circlepath", description: "View your previous scans", action: {
                showHistory = true
                isMenuExpanded = false
            })
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)
            
            FeatureButton(title: "Favorites", icon: "heart.fill", description: "Your saved products", action: {
                // Action for favorites
            })
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 30)
            
            FeatureButton(title: "Nutrition Guide", icon: "chart.bar.fill", description: "Understand nutrition facts", action: {
                // Show nutrition guide
            })
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 40)
            
            FeatureButton(title: "Exit Scanner", icon: "arrow.left.circle.fill", description: "Return to main menu", action: {
                presentationMode.wrappedValue.dismiss()
            })
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 50)
        }
        .padding(20)
        .onAppear {
            // Staggered animation for menu items
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.1).delay(0.1)) {
                showButtons = true
            }
        }
        .onDisappear {
            showButtons = false
        }
    }
    
    private func toggleLanguage() {
        let languages = ["English", "Español", "Français", "Deutsch", "中文"]
        if let currentIndex = languages.firstIndex(of: appLanguage) {
            let nextIndex = (currentIndex + 1) % languages.count
            appLanguage = languages[nextIndex]
        } else {
            appLanguage = "English"
        }
    }
    
    // Custom feature button with icon and description
    @ViewBuilder
    private func FeatureButton(title: String, icon: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Scale animation for buttons
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ScanItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var scannedText: String = ""
    @State private var isScanning: Bool = true
    @State private var showingResult: Bool = false
    @State private var processingComplete: Bool = false
    @State private var apiProcessingStatus: String = "Analyzing ingredients..."
    @State private var showingAnalysisResults: Bool = false
    @State private var analyzedProduct: FoodProduct?
    
    // VisionOS Menu Properties
    @State private var isMenuExpanded: Bool = false
    @State private var menuPosition: CGRect = .zero
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = "English"
    @State private var showHistory: Bool = false
    @State private var isFlashlightOn: Bool = false
    
    // App lifecycle state
    @Environment(\.scenePhase) private var scenePhase
    
    // Custom font family
    private let titleFont = Font.custom("Avenir-Heavy", size: 24)
    private let headlineFont = Font.custom("Avenir-Medium", size: 18)
    private let bodyFont = Font.custom("Avenir-Book", size: 16)
    private let captionFont = Font.custom("Avenir-Light", size: 14)
    
    var body: some View {
        ZStack {
            // Camera view
            MeasureStyleCameraView(scannedText: $scannedText, isScanning: $isScanning, isFlashlightOn: $isFlashlightOn)
                .edgesIgnoringSafeArea(.all)
                .opacity(isScanning ? 1 : 0)
            
            if !isScanning {
                // Processing or Results View
                VStack(spacing: 25) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            if processingComplete {
                                // Return to scanning mode
                                isScanning = true
                                scannedText = ""
                                processingComplete = false
                                analyzedProduct = nil
                                showingAnalysisResults = false
                            } else {
                                // Go back to scanning
                                isScanning = true
                            }
                        }) {
                            Image(systemName: processingComplete ? "xmark.circle.fill" : "arrow.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        // Title
                        if !processingComplete {
                            Text("Scan Results")
                                .font(headlineFont)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    if productViewModel.isLoading {
                        // Loading indicator with DeepSeek AI processing status
                        loadingView()
                    } else if let errorMessage = productViewModel.errorMessage {
                        // Error message
                        errorView(message: errorMessage)
                    } else {
                        // Success view with scanned text info
                        if processingComplete {
                            // When processing is complete - show success message
                            successView()
                        } else {
                            // Initial scan results before processing
                            extractedTextView()
                        }
                    }
                    
                    Spacer()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)
                )
            }
            
            // Top Header Controls
            if isScanning {
                VStack {
                    // App Header
                    HStack {
                        // History Button
                        Button(action: {
                            showHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                }
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Text("KeepMeHealthy")
                            .font(headlineFont)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                isMenuExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20))
                                Text("Menu")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                            }
                        }
                        .padding(.trailing, 20)
                        .overlay(alignment: .topTrailing) {
                            if isMenuExpanded {
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            menuPosition = proxy.frame(in: .global)
                                        }
                                }
                                .frame(width: 0, height: 0)
                                
                                VisionOSStyleView {
                                    MenuBarControls(showHistory: $showHistory, isMenuExpanded: $isMenuExpanded, isDarkMode: $isDarkMode, appLanguage: $appLanguage)
                                }
                                .frame(width: 300)
                                .offset(x: -20, y: 60)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)).combined(with: .offset(x: 20, y: -10)),
                                    removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)).combined(with: .offset(x: 20, y: -10))
                                ))
                                .zIndex(1000)
                            }
                        }
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Instructions text with clean style
                        Text("Point camera at food label")
                            .font(bodyFont)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                        
                        HStack {
                            // Flashlight toggle
                            Button(action: {
                                isFlashlightOn.toggle()
                                toggleFlashlight(on: isFlashlightOn)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isFlashlightOn ? Color.yellow.opacity(0.8) : Color.black.opacity(0.5))
                                        .frame(width: 54, height: 54)
                                    
                                    Image(systemName: isFlashlightOn ? "bolt.fill" : "bolt.slash.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.leading, 30)
                            
                            Spacer()
                            
                            // Capture button in SwiftUI that triggers the UIKit camera capture
                            Button(action: {
                                // Send notification to trigger camera capture
                                NotificationCenter.default.post(name: NSNotification.Name("TriggerCameraCapture"), object: nil)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 54, height: 54)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.blue, lineWidth: 3)
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            // Empty space to balance the layout
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 54, height: 54)
                                .padding(.trailing, 30)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showHistory) {
            ScanHistoryView()
                .environmentObject(productViewModel)
        }
        .fullScreenCover(isPresented: $showingAnalysisResults, onDismiss: {
            // When the analysis view is dismissed, check if we should return to scanning
            print("Analysis view dismissed")
        }) {
            if let product = analyzedProduct {
                AnalysisResultsView(product: productViewModel.preloadProduct(product))
                    .environmentObject(productViewModel)
                    .onDisappear {
                        // Clear the analyzed product reference when view disappears
                        print("AnalysisResultsView disappeared")
                    }
            } else {
                // Fallback view in case product is nil
                Text("Error loading product details")
                    .onAppear {
                        print("⚠️ Error: analyzedProduct was nil when trying to show AnalysisResultsView")
                        // Auto-dismiss after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showingAnalysisResults = false
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App has become active again
                if isScanning {
                    // Reset any necessary state
                    isMenuExpanded = false
                }
            case .background:
                // App is going to background
                if isFlashlightOn {
                    isFlashlightOn = false
                    toggleFlashlight(on: false)
                }
                isMenuExpanded = false
            case .inactive:
                // App is inactive but still visible
                isMenuExpanded = false
            @unknown default:
                break
            }
        }
        .onDisappear {
            // Reset the loading and error states when view disappears
            if productViewModel.isLoading {
                productViewModel.isLoading = false
            }
            productViewModel.errorMessage = nil
            
            // Turn off flashlight if it's on
            if isFlashlightOn {
                toggleFlashlight(on: false)
            }
            
            // Close any open menus
            isMenuExpanded = false
        }
        .onAppear {
            // Set up notification observer for returning to scanning
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ReturnToScanning"), object: nil, queue: .main) { _ in
                // Reset state to scanning mode
                isScanning = true
                scannedText = ""
                processingComplete = false
                analyzedProduct = nil
                showingAnalysisResults = false
            }
            
            // Set up notification observer for auto-processing scans
            NotificationCenter.default.addObserver(forName: NSNotification.Name("AutoProcessScan"), object: nil, queue: .main) { _ in
                // Automatically process the scan when text recognition is complete
                print("Auto-processing scan with text: \(scannedText.prefix(100))...")
                processScan()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    // Helper function to toggle flashlight
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flashlight: \(error.localizedDescription)")
        }
    }
    
    // Loading view with minimal animation
    private func loadingView() -> some View {
        VStack(spacing: 20) {
            // Circular progress
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding()
            
            Text("Analyzing Product")
                .font(headlineFont)
                .foregroundColor(.white)
            
            Text("Identifying ingredients...")
                .font(captionFont)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(.horizontal, 32)
    }
    
    // Error view
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Processing Error")
                .font(titleFont)
                .foregroundColor(.white)
            
            Text(message)
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
            
            Button(action: {
                isScanning = true
            }) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(bodyFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("Tab")))
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(.horizontal, 32)
    }
    
    // Success view
    private func successView() -> some View {
        VStack(spacing: 24) {
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.green)
            }
            
            VStack(spacing: 8) {
                Text("Analysis Complete!")
                    .font(titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("We've analyzed what's in this product. Tap below to see the ingredients breakdown.")
                    .font(bodyFont)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            
            Button(action: {
                // Show the detailed analysis results
                showingAnalysisResults = true
            }) {
                Label("What's In There?", systemImage: "list.bullet.clipboard")
                    .font(headlineFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("Tab"))
                            .shadow(color: Color.black.opacity(0.2), radius: 5)
                    )
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(.horizontal, 32)
    }
    
    // Extracted text view
    private func extractedTextView() -> some View {
        VStack(spacing: 20) {
            Text("Text Extraction Complete!")
                .font(headlineFont)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.viewfinder")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Extracted Text:")
                        .font(bodyFont)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                ScrollView {
                    Text(scannedText.isEmpty ? "No text detected" : scannedText)
                        .font(bodyFont)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxHeight: 200)
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 20) {
                Button(action: {
                    isScanning = true
                    scannedText = ""
                }) {
                    Label("Scan Again", systemImage: "camera.fill")
                        .font(bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.7))
                        )
                }
                
                Button(action: {
                    // Process the scan
                    processScan()
                }) {
                    Label("Analyze", systemImage: "magnifyingglass")
                        .font(bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("Tab"))
                        )
                }
                .disabled(scannedText.isEmpty)
                .opacity(scannedText.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(.horizontal, 24)
    }
    
    // Process the scanned text through the DeepSeek-enabled ViewModel
    private func processScan() {
        processingComplete = false
        
        // Set up a timer to monitor for new products being added
        let startingProductCount = productViewModel.getRecentProducts(limit: 100).count
        
        productViewModel.processScanResult(extractedText: scannedText)
        
        // Show success state after processing is complete
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !productViewModel.isLoading && productViewModel.errorMessage == nil {
                processingComplete = true
                
                // Check if a new product was added
                let currentProducts = productViewModel.getRecentProducts(limit: 100)
                if currentProducts.count > startingProductCount {
                    // Get the most recently added product
                    if let newProduct = productViewModel.getRecentProducts(limit: 1).first {
                        print("Found newly added product: \(newProduct.name)")
                        
                        // Ensure the product is fully initialized before showing it
                        analyzedProduct = productViewModel.preloadProduct(newProduct)
                    } else {
                        print("No new products found in the first position")
                    }
                } else {
                    print("No new products detected after scan processing")
                }
                
                timer.invalidate()
            } else if productViewModel.errorMessage != nil {
                timer.invalidate()
            }
        }
    }
}

// Corner bracket component for scan frame
struct ScanCornerBracket: View {
    enum Orientation {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let orientation: Orientation
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .frame(width: 20, height: 2.5)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.5), radius: 1)
            
            // Vertical line
            Rectangle()
                .frame(width: 2.5, height: 20)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.5), radius: 1)
        }
        .rotationEffect(.degrees(
            orientation == .topLeft ? 0 :
            orientation == .topRight ? 90 :
            orientation == .bottomLeft ? 270 :
            180
        ))
    }
}

// Modern camera view inspired by Apple's Measure app
struct MeasureStyleCameraView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isScanning: Bool
    @Binding var isFlashlightOn: Bool

    func makeUIViewController(context: Context) -> MeasureStyleCameraViewController {
        let cameraViewController = MeasureStyleCameraViewController()
        cameraViewController.delegate = context.coordinator
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: MeasureStyleCameraViewController, context: Context) {
        if uiViewController.isFlashlightOn != isFlashlightOn {
            uiViewController.toggleFlashlight(isOn: isFlashlightOn)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MeasureStyleCameraViewControllerDelegate {
        var parent: MeasureStyleCameraView

        init(_ parent: MeasureStyleCameraView) {
            self.parent = parent
        }

        func didCapturePhoto(image: UIImage) {
            recognizeText(in: image)
        }

        func recognizeText(in image: UIImage) {
            guard let cgImage = image.cgImage else { return }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      error == nil else {
                    print("Text recognition error: \(error?.localizedDescription ?? "unknown error")")
                    // Update UI to show error
                    DispatchQueue.main.async {
                        self?.parent.scannedText = "Error recognizing text."
                        self?.parent.isScanning = false
                    }
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    DispatchQueue.main.async {
                        self?.parent.scannedText = "No text found. Please try again."
                        self?.parent.isScanning = false
                    }
                    return
                }

                // Instead of just showing the text, immediately process it
                DispatchQueue.main.async {
                    self?.parent.scannedText = recognizedText
                    self?.parent.isScanning = false
                    
                    // Notify parent view to process the scan automatically
                    NotificationCenter.default.post(name: NSNotification.Name("AutoProcessScan"), object: nil)
                }
            }

            // Configure language recognition for food labels
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant", "fr-FR", "es-ES", "de-DE"]
            request.recognitionLevel = .accurate // Use accurate for better results with food labels
            request.usesLanguageCorrection = true // Enable language correction for better recognition

            do {
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform text recognition request: \(error)")
                DispatchQueue.main.async {
                    self.parent.scannedText = "Error performing recognition."
                    self.parent.isScanning = false
                }
            }
        }
    }
}

protocol MeasureStyleCameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(image: UIImage)
}

// Modern camera view controller inspired by Apple's Measure app
class MeasureStyleCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate {
    weak var delegate: MeasureStyleCameraViewControllerDelegate?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // UI elements for camera
    private var focusView: UIView!
    var isFlashlightOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupFocusView()
        
        // Use notification to respond to SwiftUI button
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCaptureTrigger),
            name: NSNotification.Name("TriggerCameraCapture"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopCamera()
    }
    
    @objc private func handleCaptureTrigger() {
        capturePhoto()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds // Ensure previewLayer resizes correctly
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCamera()
    }
    
    private func setupFocusView() {
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 2
        focusView.backgroundColor = UIColor.clear
        focusView.isHidden = true
        view.addSubview(focusView)
        
        // Add tap gesture for focus and ensure it doesn't interfere with the capture button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFocus(_:)))
        tapGesture.cancelsTouchesInView = false // Allow touch events to pass through to views underneath
        tapGesture.delegate = self // Set delegate to handle gesture recognition
        view.addGestureRecognizer(tapGesture)
    }

    func toggleFlashlight(isOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            isFlashlightOn = isOn
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flashlight: \(error)")
        }
    }

    private func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Unable to access camera")
            return
        }

        // Configure for high frame rate - improved implementation
        do {
            try backCamera.lockForConfiguration()
            if backCamera.isFocusModeSupported(.continuousAutoFocus) {
                backCamera.focusMode = .continuousAutoFocus
            }
            
            // Find a format that supports high frame rate
            var bestFormat: AVCaptureDevice.Format? = nil
            var bestFrameRateRange: AVFrameRateRange? = nil
            
            // Look for formats that support at least 60fps, preferably 100fps or higher
            for format in backCamera.formats {
                // Skip formats with incompatible dimensions
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let width = dimensions.width
                let height = dimensions.height
                
                // Only consider reasonably sized formats (not too high resolution)
                if width > 1920 || height > 1080 {
                    continue
                }
                
                // Check frame rate ranges
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= 60 {
                        // If we haven't found a good format yet, or this one is better
                        if bestFrameRateRange == nil || range.maxFrameRate > bestFrameRateRange!.maxFrameRate {
                            bestFormat = format
                            bestFrameRateRange = range
                        }
                    }
                }
            }
            
            // Apply the best format if found
            if let bestFormat = bestFormat, let bestRange = bestFrameRateRange {
                backCamera.activeFormat = bestFormat
                
                // Target the highest frame rate supported, up to 100fps
                let targetFrameRate = min(100.0, bestRange.maxFrameRate)
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
                
                backCamera.activeVideoMinFrameDuration = frameDuration
                backCamera.activeVideoMaxFrameDuration = frameDuration
                
                print("Camera format set to: \(bestFormat.formatDescription)")
                print("Camera frame rate configuration: target=\(targetFrameRate) fps, applied=\(1.0/CMTimeGetSeconds(backCamera.activeVideoMinFrameDuration)) fps")
            } else {
                print("No suitable high frame rate format found, using default settings")
            }
            
            backCamera.unlockForConfiguration()
        } catch {
            print("Error configuring camera for high frame rate: \(error)")
        }

        if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds

            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
        } else {
            print("Could not add input or output to capture session")
        }
    }

    private func startCamera() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    private func stopCamera() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Simply allow all touches since the capture button is now in SwiftUI
        return true
    }
    
    @objc private func handleFocus(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.autoFocus) {
                let focusPoint = CGPoint(
                    x: location.x / view.bounds.width,
                    y: location.y / view.bounds.height
                )
                
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                
                // Show focus animation
                focusView.center = location
                focusView.isHidden = false
                focusView.alpha = 1.0
                focusView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.focusView.transform = CGAffineTransform.identity
                }) { _ in
                    UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                        self.focusView.alpha = 0.0
                    }) { _ in
                        self.focusView.isHidden = true
                    }
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error)")
        }
    }

    @objc private func capturePhoto() {
        // Flash animation
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.2, animations: {
            flashView.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 0.0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // Take the photo
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        
        // Ensure photoOutput is valid and session is running before capturing
        guard captureSession.isRunning && captureSession.outputs.contains(photoOutput) else {
            print("Capture session not running or photoOutput not added.")
            return
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Unable to create image from photo data")
            return
        }

        delegate?.didCapturePhoto(image: image)
    }
}

#Preview {
    ScanItemView()
        .environmentObject(ProductViewModel())
}
