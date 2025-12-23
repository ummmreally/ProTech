//
//  SocialMediaPlatformSettingsView.swift
//  ProTech
//
//  Social media platform API configuration settings
//

import SwiftUI

struct SocialMediaPlatformSettingsView: View {
    @State private var selectedPlatform: ConfigurablePlatform = .twitter
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Platform", selection: $selectedPlatform) {
                ForEach(ConfigurablePlatform.allCases, id: \.self) { platform in
                    Text(platform.displayName).tag(platform)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            platformView
                .id(selectedPlatform)
        }
    }
    
    @ViewBuilder
    private var platformView: some View {
        switch selectedPlatform {
        case .twitter:
            TwitterSettingsView()
        case .facebook:
            FacebookSettingsView()
        case .linkedin:
            LinkedInSettingsView()
        case .instagram:
            InstagramSettingsView()
        }
    }
}

// MARK: - Twitter/X Settings

struct TwitterSettingsView: View {
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var isConnected = false
    @State private var isConnecting = false
    @State private var showTutorial = false
    @State private var testResult = ""
    @State private var showTestResult = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark")
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("X (Twitter) Integration")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "212121"))
                            Text("Post to X/Twitter from ProTech")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    HStack {
                        Text("Don't have a developer account?")
                            .font(.callout)
                            .foregroundColor(Color(hex: "757575"))
                        Link("Sign up here →", destination: URL(string: "https://developer.twitter.com")!)
                            .font(.callout)
                    }
                    
                    Button {
                        showTutorial = true
                    } label: {
                        Label("View Setup Tutorial", systemImage: "book.fill")
                            .foregroundColor(Color(hex: "2196F3"))
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Section("API Credentials") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client ID")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    TextField("Your X Client ID", text: $clientId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "212121"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Secret")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    SecureField("Your X Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section("Connection") {
                HStack {
                    Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isConnected ? Color(hex: "00C853") : Color(hex: "757575"))
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(isConnected ? "Connected to X" : "Not Connected")
                            .font(.headline)
                            .foregroundColor(Color(hex: "212121"))
                        if isConnected {
                            Text("Ready to post")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .disabled(clientId.isEmpty || clientSecret.isEmpty)
                    
                    Spacer()
                    
                    if isConnecting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button(isConnected ? "Disconnect" : "Connect Account") {
                        if isConnected {
                            disconnect()
                        } else {
                            connectAccount()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isConnected ? .red : Color(hex: "2196F3"))
                    .disabled(clientId.isEmpty || clientSecret.isEmpty || isConnecting)
                }
            }
            
            if showTestResult {
                Section {
                    Text(testResult)
                        .foregroundColor(Color(hex: "212121"))
                }
            }
            
            Section("Setup Instructions") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(number: "1", text: "Go to developer.twitter.com and sign in")
                    InfoRow(number: "2", text: "Create a new App in the Developer Portal")
                    InfoRow(number: "3", text: "Go to 'Keys and tokens' tab")
                    InfoRow(number: "4", text: "Copy Client ID and Client Secret")
                    InfoRow(number: "5", text: "Paste credentials above and click 'Connect Account'")
                }
            }
            
            Section("Required Permissions") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Read and write Tweets")
                    Text("• Read user profile")
                    Text("• Upload media")
                }
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadCredentials()
        }
        .sheet(isPresented: $showTutorial) {
            TwitterTutorialView()
        }
    }
    
    private func loadCredentials() {
        clientId = SecureStorage.retrieve(key: "x_client_id") ?? ""
        clientSecret = SecureStorage.retrieve(key: "x_client_secret") ?? ""
        isConnected = SecureStorage.retrieve(key: "x_access_token") != nil
    }
    
    private func saveCredentials() {
        _ = SecureStorage.save(key: "x_client_id", value: clientId)
        _ = SecureStorage.save(key: "x_client_secret", value: clientSecret)
        
        testResult = "✅ Credentials saved! Click 'Connect Account' to authorize."
        showTestResult = true
    }
    
    private func connectAccount() {
        isConnecting = true
        
        // Save credentials first if they're not saved
        if !clientId.isEmpty && !clientSecret.isEmpty {
            _ = SecureStorage.save(key: "x_client_id", value: clientId)
            _ = SecureStorage.save(key: "x_client_secret", value: clientSecret)
        }
        
        SocialMediaOAuthService.shared.authenticateX { result in
            isConnecting = false
            
            switch result {
            case .success:
                isConnected = true
                testResult = "✅ Successfully connected to X!"
                showTestResult = true
            case .failure(let error):
                if let oauthError = error as? OAuthError {
                    testResult = "❌ " + oauthError.localizedDescription
                } else {
                    testResult = "❌ Connection failed: \(error.localizedDescription)"
                }
                showTestResult = true
            }
        }
    }
    
    private func disconnect() {
        SocialMediaOAuthService.shared.disconnect(platform: "X")
        isConnected = false
        testResult = "Disconnected from X"
        showTestResult = true
    }
}

// MARK: - Facebook Settings

struct FacebookSettingsView: View {
    @State private var appId = ""
    @State private var appSecret = ""
    @State private var pageId = ""
    @State private var isConnected = false
    @State private var isConnecting = false
    @State private var showTutorial = false
    @State private var testResult = ""
    @State private var showTestResult = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "f.circle.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "1877F2"))
                        VStack(alignment: .leading) {
                            Text("Facebook Integration")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "212121"))
                            Text("Post to Facebook Pages from ProTech")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    HStack {
                        Text("Don't have a developer account?")
                            .font(.callout)
                            .foregroundColor(Color(hex: "757575"))
                        Link("Sign up here →", destination: URL(string: "https://developers.facebook.com")!)
                            .font(.callout)
                    }
                    
                    Button {
                        showTutorial = true
                    } label: {
                        Label("View Setup Tutorial", systemImage: "book.fill")
                            .foregroundColor(Color(hex: "1877F2"))
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Section("API Credentials") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App ID")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    TextField("Your Facebook App ID", text: $appId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "212121"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Secret")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    SecureField("Your Facebook App Secret", text: $appSecret)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Page ID (Optional - will be auto-fetched)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    TextField("Your Facebook Page ID", text: $pageId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "212121"))
                }
            }
            
            Section("Connection") {
                HStack {
                    Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isConnected ? Color(hex: "00C853") : Color(hex: "757575"))
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(isConnected ? "Connected to Facebook" : "Not Connected")
                            .font(.headline)
                            .foregroundColor(Color(hex: "212121"))
                        if isConnected {
                            Text("Ready to post")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .disabled(appId.isEmpty || appSecret.isEmpty)
                    
                    Spacer()
                    
                    if isConnecting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button(isConnected ? "Disconnect" : "Connect Account") {
                        if isConnected {
                            disconnect()
                        } else {
                            connectAccount()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isConnected ? .red : Color(hex: "1877F2"))
                    .disabled(appId.isEmpty || appSecret.isEmpty || isConnecting)
                }
            }
            
            if showTestResult {
                Section {
                    Text(testResult)
                        .foregroundColor(Color(hex: "212121"))
                }
            }
            
            Section("Setup Instructions") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(number: "1", text: "Go to developers.facebook.com and sign in")
                    InfoRow(number: "2", text: "Create a new App")
                    InfoRow(number: "3", text: "Add 'Facebook Login' product")
                    InfoRow(number: "4", text: "Go to Settings → Basic and copy App ID & Secret")
                    InfoRow(number: "5", text: "Paste credentials above and click 'Connect Account'")
                }
            }
            
            Section("Required Permissions") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• pages_manage_posts")
                    Text("• pages_read_engagement")
                    Text("• publish_to_groups (optional)")
                }
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadCredentials()
        }
        .sheet(isPresented: $showTutorial) {
            FacebookTutorialView()
        }
    }
    
    private func loadCredentials() {
        appId = SecureStorage.retrieve(key: "facebook_app_id") ?? ""
        appSecret = SecureStorage.retrieve(key: "facebook_app_secret") ?? ""
        pageId = SecureStorage.retrieve(key: "facebook_page_id") ?? ""
        isConnected = SecureStorage.retrieve(key: "facebook_access_token") != nil
    }
    
    private func saveCredentials() {
        _ = SecureStorage.save(key: "facebook_app_id", value: appId)
        _ = SecureStorage.save(key: "facebook_app_secret", value: appSecret)
        if !pageId.isEmpty {
            _ = SecureStorage.save(key: "facebook_page_id", value: pageId)
        }
        
        testResult = "✅ Credentials saved! Click 'Connect Account' to authorize."
        showTestResult = true
    }
    
    private func connectAccount() {
        isConnecting = true
        
        // Save credentials first if they're not saved
        if !appId.isEmpty && !appSecret.isEmpty {
            _ = SecureStorage.save(key: "facebook_app_id", value: appId)
            _ = SecureStorage.save(key: "facebook_app_secret", value: appSecret)
            if !pageId.isEmpty {
                _ = SecureStorage.save(key: "facebook_page_id", value: pageId)
            }
        }
        
        SocialMediaOAuthService.shared.authenticateFacebook { result in
            isConnecting = false
            
            switch result {
            case .success:
                isConnected = true
                testResult = "✅ Successfully connected to Facebook!"
                showTestResult = true
            case .failure(let error):
                if let oauthError = error as? OAuthError {
                    testResult = "❌ " + oauthError.localizedDescription
                } else {
                    testResult = "❌ Connection failed: \(error.localizedDescription)"
                }
                showTestResult = true
            }
        }
    }
    
    private func disconnect() {
        SocialMediaOAuthService.shared.disconnect(platform: "Facebook")
        isConnected = false
        testResult = "Disconnected from Facebook"
        showTestResult = true
    }
}

// MARK: - LinkedIn Settings

struct LinkedInSettingsView: View {
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var isConnected = false
    @State private var isConnecting = false
    @State private var showTutorial = false
    @State private var testResult = ""
    @State private var showTestResult = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "0A66C2"))
                        VStack(alignment: .leading) {
                            Text("LinkedIn Integration")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "212121"))
                            Text("Post professional updates from ProTech")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    HStack {
                        Text("Don't have a developer account?")
                            .font(.callout)
                            .foregroundColor(Color(hex: "757575"))
                        Link("Sign up here →", destination: URL(string: "https://www.linkedin.com/developers")!)
                            .font(.callout)
                    }
                    
                    Button {
                        showTutorial = true
                    } label: {
                        Label("View Setup Tutorial", systemImage: "book.fill")
                            .foregroundColor(Color(hex: "0A66C2"))
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Section("API Credentials") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client ID")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    TextField("Your LinkedIn Client ID", text: $clientId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "212121"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Secret")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                    SecureField("Your LinkedIn Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section("Connection") {
                HStack {
                    Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isConnected ? Color(hex: "00C853") : Color(hex: "757575"))
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(isConnected ? "Connected to LinkedIn" : "Not Connected")
                            .font(.headline)
                            .foregroundColor(Color(hex: "212121"))
                        if isConnected {
                            Text("Ready to post")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .disabled(clientId.isEmpty || clientSecret.isEmpty)
                    
                    Spacer()
                    
                    if isConnecting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button(isConnected ? "Disconnect" : "Connect Account") {
                        if isConnected {
                            disconnect()
                        } else {
                            connectAccount()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isConnected ? .red : Color(hex: "0A66C2"))
                    .disabled(clientId.isEmpty || clientSecret.isEmpty || isConnecting)
                }
            }
            
            if showTestResult {
                Section {
                    Text(testResult)
                        .foregroundColor(Color(hex: "212121"))
                }
            }
            
            Section("Setup Instructions") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(number: "1", text: "Go to linkedin.com/developers and sign in")
                    InfoRow(number: "2", text: "Click 'Create app'")
                    InfoRow(number: "3", text: "Fill in app details and verify")
                    InfoRow(number: "4", text: "Go to 'Auth' tab and copy Client ID & Secret")
                    InfoRow(number: "5", text: "Paste credentials above and click 'Connect Account'")
                }
            }
            
            Section("Required Permissions") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• w_member_social (Post on behalf of member)")
                    Text("• r_liteprofile (Read basic profile)")
                    Text("• r_emailaddress (Read email)")
                }
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadCredentials()
        }
        .sheet(isPresented: $showTutorial) {
            LinkedInTutorialView()
        }
    }
    
    private func loadCredentials() {
        clientId = SecureStorage.retrieve(key: "linkedin_client_id") ?? ""
        clientSecret = SecureStorage.retrieve(key: "linkedin_client_secret") ?? ""
        isConnected = SecureStorage.retrieve(key: "linkedin_access_token") != nil
    }
    
    private func saveCredentials() {
        _ = SecureStorage.save(key: "linkedin_client_id", value: clientId)
        _ = SecureStorage.save(key: "linkedin_client_secret", value: clientSecret)
        
        testResult = "✅ Credentials saved! Click 'Connect Account' to authorize."
        showTestResult = true
    }
    
    private func connectAccount() {
        isConnecting = true
        
        // Save credentials first if they're not saved
        if !clientId.isEmpty && !clientSecret.isEmpty {
            _ = SecureStorage.save(key: "linkedin_client_id", value: clientId)
            _ = SecureStorage.save(key: "linkedin_client_secret", value: clientSecret)
        }
        
        SocialMediaOAuthService.shared.authenticateLinkedIn { result in
            isConnecting = false
            
            switch result {
            case .success:
                isConnected = true
                testResult = "✅ Successfully connected to LinkedIn!"
                showTestResult = true
            case .failure(let error):
                if let oauthError = error as? OAuthError {
                    testResult = "❌ " + oauthError.localizedDescription
                } else {
                    testResult = "❌ Connection failed: \(error.localizedDescription)"
                }
                showTestResult = true
            }
        }
    }
    
    private func disconnect() {
        SocialMediaOAuthService.shared.disconnect(platform: "LinkedIn")
        isConnected = false
        testResult = "Disconnected from LinkedIn"
        showTestResult = true
    }
}

// MARK: - Instagram Settings (Placeholder)

struct InstagramSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "E4405F"))
                        VStack(alignment: .leading) {
                            Text("Instagram Integration")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "212121"))
                            Text("Post to Instagram from ProTech")
                                .font(.caption)
                                .foregroundColor(Color(hex: "757575"))
                        }
                    }
                    
                    Text("Instagram posting requires a Facebook Business Page and Instagram Business Account. Configure Facebook first, then Instagram will become available.")
                        .font(.body)
                        .foregroundColor(Color(hex: "757575"))
                        .padding()
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(8)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Tutorial Views (Placeholders)

struct TwitterTutorialView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("X/Twitter Setup Tutorial")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    SocialMediaTutorialStep(number: 1, title: "Create Developer Account", description: "Visit developer.twitter.com and sign in with your X account")
                    SocialMediaTutorialStep(number: 2, title: "Create New App", description: "Click 'Create App' and fill in the required details")
                    SocialMediaTutorialStep(number: 3, title: "Enable OAuth 2.0", description: "Go to App Settings → User authentication settings → Set up OAuth 2.0")
                    SocialMediaTutorialStep(number: 4, title: "Add Redirect URI", description: "Add: protech://oauth/x")
                    SocialMediaTutorialStep(number: 5, title: "Get Credentials", description: "Copy Client ID and Client Secret from Keys and tokens tab")
                    SocialMediaTutorialStep(number: 6, title: "Paste in ProTech", description: "Return here and paste your credentials, then click Connect")
                }
                .padding()
            }
            .navigationTitle("Setup Tutorial")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FacebookTutorialView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Facebook Setup Tutorial")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    SocialMediaTutorialStep(number: 1, title: "Create Developer Account", description: "Visit developers.facebook.com and sign in")
                    SocialMediaTutorialStep(number: 2, title: "Create New App", description: "Click 'Create App' and select app type")
                    SocialMediaTutorialStep(number: 3, title: "Add Facebook Login", description: "Add the Facebook Login product to your app")
                    SocialMediaTutorialStep(number: 4, title: "Configure OAuth", description: "Add redirect URI: protech://oauth/facebook")
                    SocialMediaTutorialStep(number: 5, title: "Get Credentials", description: "Go to Settings → Basic and copy App ID and App Secret")
                    SocialMediaTutorialStep(number: 6, title: "Paste in ProTech", description: "Return here and paste your credentials, then click Connect")
                }
                .padding()
            }
            .navigationTitle("Setup Tutorial")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LinkedInTutorialView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("LinkedIn Setup Tutorial")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    SocialMediaTutorialStep(number: 1, title: "Create Developer Account", description: "Visit linkedin.com/developers and sign in")
                    SocialMediaTutorialStep(number: 2, title: "Create New App", description: "Click 'Create app' and fill in app details")
                    SocialMediaTutorialStep(number: 3, title: "Verify App", description: "Complete verification process for your company")
                    SocialMediaTutorialStep(number: 4, title: "Configure OAuth", description: "Add redirect URI: protech://oauth/linkedin")
                    SocialMediaTutorialStep(number: 5, title: "Get Credentials", description: "Go to Auth tab and copy Client ID and Client Secret")
                    SocialMediaTutorialStep(number: 6, title: "Paste in ProTech", description: "Return here and paste your credentials, then click Connect")
                }
                .padding()
            }
            .navigationTitle("Setup Tutorial")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SocialMediaTutorialStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color(hex: "2196F3"))
                .frame(width: 32, height: 32)
                .overlay {
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                Text(description)
                    .font(.body)
                    .foregroundColor(Color(hex: "757575"))
            }
        }
    }
}

// MARK: - Platform Enum

enum ConfigurablePlatform: String, CaseIterable {
    case twitter = "X/Twitter"
    case facebook = "Facebook"
    case linkedin = "LinkedIn"
    case instagram = "Instagram"
    
    var displayName: String { rawValue }
}

// MARK: - Preview

struct SocialMediaPlatformSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SocialMediaPlatformSettingsView()
            .frame(width: 700, height: 600)
    }
}
