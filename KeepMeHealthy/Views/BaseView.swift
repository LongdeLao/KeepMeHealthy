//
//  BaseView.swift
//  KeepMeHealthy
//
//  Created by Longde Lao on 01.06.25.
//
import SwiftUI

struct BaseView: View {
    
    // Using Image Names as Tab...
    @State var currentTab = "home"
    
    // Added state for showing the scanner
    @State private var showScanner = false
    
    // Custom font family
    private let titleFont = Font.custom("Avenir-Heavy", size: 24)
    private let headlineFont = Font.custom("Avenir-Medium", size: 18)
    private let bodyFont = Font.custom("Avenir-Book", size: 16)
    private let captionFont = Font.custom("Avenir-Light", size: 14)
    
    // Hiding Native One..
    init(){
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        
        VStack(spacing: 0){
            
            // Tab View..
            TabView(selection: $currentTab) {
                
                HomeView()
                    .modifier(BGModifier())
                    .tag("home")
                
                Text("Analytics")
                    .font(titleFont)
                    .modifier(BGModifier())
                    .tag("graph")
                
                Text("Favorites")
                    .font(titleFont)
                    .modifier(BGModifier())
                    .tag("heart")
                
                SettingsView()
                    .modifier(BGModifier())
                    .tag("settings")
            }
            
            // Custom Tab Bar...
            HStack(spacing: 0) {
                Spacer()
                
                // Tab Buttons...
                TabButton(image: "home", label: "Home", currentTab: $currentTab)
                
                Spacer()
                 
                TabButton(image: "graph", label: "Analytics", currentTab: $currentTab)
                
                Spacer()
                
                // Center Scan Button...
                ScanButton(showScanner: $showScanner)
                
                Spacer()
                
                TabButton(image: "heart", label: "Favorites", currentTab: $currentTab)
                
                Spacer()
                
                TabButton(image: "settings", label: "Settings", currentTab: $currentTab)
                
                Spacer()
            }
            .padding(.top, 7)
            .padding(.bottom,-12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -5)
                    .ignoresSafeArea(.all, edges: .bottom)
            )
        }
    }
}

// Tab Button Component
struct TabButton: View {
    let image: String
    let label: String
    @Binding var currentTab: String
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentTab = image
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: image == "home" ? "house.fill" : 
                               image == "graph" ? "chart.bar.fill" :
                               image == "heart" ? "heart.fill" : 
                               "gearshape.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(.custom("Avenir-Medium", size: 10))
            }
            .foregroundColor(
                currentTab == image ? Color("Tab") : Color.gray.opacity(0.7)
            )
            .padding(.vertical, 8)
            .frame(width: 60)
            .background(
                // Indicator for active tab
                ZStack {
                    if currentTab == image {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Tab").opacity(0.1))
                            .matchedGeometryEffect(id: "TAB", in: namespace)
                    }
                }
            )
        }
    }
    
    @Namespace private var namespace
}

// Scan Button Component
struct ScanButton: View {
    @Binding var showScanner: Bool
    @EnvironmentObject var productViewModel: ProductViewModel
    
    var body: some View {
        Button {
            showScanner = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("Tab").opacity(0.8), Color("Tab")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color("Tab").opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                
                Text("Scan")
                    .font(.custom("Avenir-Medium", size: 10))
                    .foregroundColor(Color("Tab"))
            }
            .offset(y: -20)
        }
        .fullScreenCover(isPresented: $showScanner) {
            // Show scan view with environmentObject to ensure data is properly shared
            ScanItemView()
                .environmentObject(productViewModel)
        }
    }
}

// BG Modifier...
struct BGModifier: ViewModifier{
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BG").ignoresSafeArea())
    }
}

#Preview{
    BaseView()
        .environmentObject(ProductViewModel())
}
