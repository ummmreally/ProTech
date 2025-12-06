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
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Supabase Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.blue)
                        Text("Supabase Configuration")
                            .sectionHeader()
                    }
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Project URL", text: $supabaseURL)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Anonymous Key", text: $supabaseKey)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .premiumCard()
                
                // Square Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.green)
                        Text("Square Configuration")
                            .sectionHeader()
                    }
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Application ID", text: $squareAppId)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Access Token", text: $squareToken)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Client Secret", text: $squareSecret)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .premiumCard()
                
                // Social Media Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(.purple)
                        Text("Social Media Configuration")
                            .sectionHeader()
                    }
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Facebook Page ID", text: $facebookPageId)
                            .textFieldStyle(.roundedBorder)
                        TextField("LinkedIn User ID", text: $linkedInUserId)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .premiumCard()
                
                // Info Section
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("These settings are used when the app is in Production mode.")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.info.opacity(0.1))
                .cornerRadius(AppTheme.cardCornerRadius)
            }
            .padding()
        }
        .navigationTitle("API Configuration")
    }
}
