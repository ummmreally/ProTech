//
//  APISettingsView.swift
//  ProTech
//
//  Settings view for configuring API credentials
//

import SwiftUI

struct APISettingsView: View {
    @AppStorage("production_supabase_url") private var supabaseURL = ""
    @AppStorage("production_supabase_key") private var supabaseKey = ""
    
    @AppStorage("production_square_app_id") private var squareAppId = ""
    @AppStorage("production_square_token") private var squareToken = ""
    @AppStorage("production_square_secret") private var squareSecret = ""
    
    @AppStorage("production_facebook_page_id") private var facebookPageId = ""
    @AppStorage("production_linkedin_user_id") private var linkedInUserId = ""
    
    var body: some View {
        Form {
            Section("Supabase Configuration") {
                TextField("Project URL", text: $supabaseURL)
                SecureField("Anonymous Key", text: $supabaseKey)
            }
            
            Section("Square Configuration") {
                TextField("Application ID", text: $squareAppId)
                SecureField("Access Token", text: $squareToken)
                SecureField("Client Secret", text: $squareSecret)
            }
            
            Section("Social Media Configuration") {
                TextField("Facebook Page ID", text: $facebookPageId)
                TextField("LinkedIn User ID", text: $linkedInUserId)
            }
            
            Section {
                Text("These settings are used when the app is in Production mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("API Configuration")
    }
}
