//
//  SignPalApp.swift
//  SignPal
//
//  Created by Godwin IE on 09/04/2025.
//

import SwiftUI

@main
struct SignAlphabetRecognizerApp: App {
    var classificationViewModel = ClassificationViewModel()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .accentColor(.mint)
                .environmentObject(classificationViewModel)
            
        }
        
    }
}
