//
//  SocialMediaManagerView.swift
//  ProTech
//
//  Social media manager for multi-platform posting
//

import SwiftUI
import UniformTypeIdentifiers

struct SocialMediaManagerView: View {
    @State private var postContent = ""
    @State private var selectedImage: NSImage?
    @State private var showImagePicker = false
    @State private var selectedPlatforms: Set<SocialPlatform> = []
    @State private var isPosting = false
    @State private var showSuccess = false
    @State private var successfulPostCount = 0
    @State private var characterCount = 0
    
    // Platform connection states
    @State private var connectedPlatforms: Set<SocialPlatform> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Search
                headerSection
                    .padding()
                    .background(Color(hex: "F5F5F5"))
                
                // Main Content
                VStack(spacing: 20) {
                    // Post Composer
                    postComposerSection
                    
                    // Platform Selection
                    platformSelectionSection
                    
                    // Post Button
                    postButtonSection
                    
                    // Recent Posts
                    recentPostsSection
                }
                .padding()
                .background(Color(hex: "F5F5F5"))
            }
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("Social Media Manager")
        .onAppear {
            checkConnectedPlatforms()
        }
        .alert("Post Successful! 🎉", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your post has been published to \(successfulPostCount) platform(s)!")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Stats
            HStack(spacing: 20) {
                StatBadge(label: "Connected", value: "\(connectedPlatforms.count)", color: Color(hex: "00C853"))
                StatBadge(label: "Posts Today", value: "12", color: Color(hex: "2196F3"))
                StatBadge(label: "Scheduled", value: "5", color: Color(hex: "FF9800"))
            }
            
            Spacer()
            
            // Settings Button
            Button {
                // Open settings
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .foregroundColor(Color(hex: "757575"))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Post Composer
    
    private var postComposerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Post")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
            
            VStack(spacing: 16) {
                // Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if postContent.isEmpty {
                            Text("What's on your mind? Share with your customers...")
                                .foregroundColor(Color(hex: "757575"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $postContent)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(Color(hex: "212121"))
                            .padding(4)
                            .onChange(of: postContent) { _, newValue in
                                characterCount = newValue.count
                            }
                    }
                    .padding(8)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                    
                    // Character count
                    HStack {
                        Text("\(characterCount) characters")
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                        
                        Spacer()
                        
                        if characterCount > 280 {
                            Text("Note: X/Twitter limit is 280 characters")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FF9800"))
                        }
                    }
                }
                
                // Image Upload
                VStack(alignment: .leading, spacing: 12) {
                    if let image = selectedImage {
                        // Image Preview
                        VStack(spacing: 12) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                            
                            HStack {
                                Button {
                                    selectedImage = nil
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                Button {
                                    showImagePicker = true
                                } label: {
                                    Label("Change", systemImage: "photo")
                                        .foregroundColor(Color(hex: "2196F3"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // Upload Button
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "2196F3"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Photo")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "212121"))
                                    
                                    Text("Click to upload image")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "757575"))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "757575"))
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "2196F3").opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
    }
    
    // MARK: - Platform Selection
    
    private var platformSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Platforms")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "212121"))
                
                Spacer()
                
                Button {
                    if selectedPlatforms.count == SocialPlatform.allCases.count {
                        selectedPlatforms.removeAll()
                    } else {
                        selectedPlatforms = Set(SocialPlatform.allCases)
                    }
                } label: {
                    Text(selectedPlatforms.count == SocialPlatform.allCases.count ? "Deselect All" : "Select All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "00C853"))
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SocialPlatform.allCases, id: \.self) { platform in
                    PlatformCard(
                        platform: platform,
                        isSelected: selectedPlatforms.contains(platform),
                        isConnected: connectedPlatforms.contains(platform)
                    ) {
                        togglePlatform(platform)
                    }
                }
            }
        }
    }
    
    // MARK: - Post Button
    
    private var postButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                postToSocialMedia()
            } label: {
                HStack {
                    if isPosting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    
                    Text(isPosting ? "Posting..." : "Post to \(selectedPlatforms.count) Platform(s)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedPlatforms.isEmpty || postContent.isEmpty ?
                    Color.gray.opacity(0.3) :
                    Color(hex: "00C853")
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(selectedPlatforms.isEmpty || postContent.isEmpty || isPosting)
            
            Button {
                // Schedule for later
            } label: {
                HStack {
                    Image(systemName: "clock")
                    Text("Schedule for Later")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color(hex: "2196F3"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "2196F3"), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Recent Posts
    
    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Posts")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
            
            VStack(spacing: 12) {
                ForEach(mockRecentPosts) { post in
                    RecentPostCard(post: post)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkConnectedPlatforms() {
        connectedPlatforms.removeAll()
        
        // Check X/Twitter
        if SocialMediaOAuthService.shared.isAuthenticated(for: "X") {
            connectedPlatforms.insert(.x)
        }
        
        // Check Facebook
        if SocialMediaOAuthService.shared.isAuthenticated(for: "Facebook") {
            connectedPlatforms.insert(.facebook)
        }
        
        // Check LinkedIn
        if SocialMediaOAuthService.shared.isAuthenticated(for: "LinkedIn") {
            connectedPlatforms.insert(.linkedin)
        }
    }
    
    private func togglePlatform(_ platform: SocialPlatform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first,
               let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
        case .failure(let error):
            print("Error selecting image: \(error.localizedDescription)")
        }
    }
    
    private func postToSocialMedia() {
        isPosting = true
        
        // Capture image on MainActor to avoid Sendable warnings
        nonisolated(unsafe) let imageToPost = selectedImage
        
        Task {
            var successCount = 0
            var errorMessages: [String] = []
            
            for platform in selectedPlatforms {
                do {
                    switch platform {
                    case .x:
                        _ = try await SocialMediaAPIService.shared.postToX(content: postContent, image: imageToPost)
                        successCount += 1
                    case .facebook:
                        _ = try await SocialMediaAPIService.shared.postToFacebook(content: postContent, image: imageToPost)
                        successCount += 1
                    case .linkedin:
                        _ = try await SocialMediaAPIService.shared.postToLinkedIn(content: postContent, image: imageToPost)
                        successCount += 1
                    default:
                        errorMessages.append("\(platform.displayName): Not yet implemented")
                    }
                } catch {
                    errorMessages.append("\(platform.displayName): \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                isPosting = false
                
                if successCount > 0 {
                    successfulPostCount = successCount
                    showSuccess = true
                    
                    // Clear form only if at least one post succeeded
                    postContent = ""
                    selectedImage = nil
                    selectedPlatforms.removeAll()
                }
                
                // Show errors if any
                if !errorMessages.isEmpty {
                    print("Posting errors: \(errorMessages.joined(separator: "\n"))")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PlatformCard: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let isConnected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Platform Icon
                Circle()
                    .fill(platform.color.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: platform.icon)
                            .font(.title3)
                            .foregroundColor(platform.color)
                    )
                
                // Platform Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(platform.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isConnected ? Color(hex: "00C853") : Color(hex: "757575"))
                            .frame(width: 6, height: 6)
                        Text(isConnected ? "Connected" : "Not connected")
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                    }
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: "00C853"))
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundColor(Color(hex: "757575").opacity(0.3))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? platform.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct RecentPostCard: View {
    let post: RecentPost
    
    var body: some View {
        HStack(spacing: 16) {
            // Platforms Posted
            HStack(spacing: -8) {
                ForEach(post.platforms.prefix(3), id: \.self) { platform in
                    Circle()
                        .fill(platform.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: platform.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            // Post Content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.content)
                    .font(.body)
                    .foregroundColor(Color(hex: "212121"))
                    .lineLimit(2)
                
                Text(post.timestamp)
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
            
            Spacer()
            
            // Status
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "00C853"))
                Text("Posted")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Models

enum SocialPlatform: String, CaseIterable, Hashable {
    case x = "X"
    case facebook = "Facebook"
    case instagram = "Instagram"
    case linkedin = "LinkedIn"
    case threads = "Threads"
    case tiktok = "TikTok"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .x: return "xmark"
        case .facebook: return "f.circle.fill"
        case .instagram: return "camera.fill"
        case .linkedin: return "briefcase.fill"
        case .threads: return "at"
        case .tiktok: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .x: return Color(hex: "000000")
        case .facebook: return Color(hex: "1877F2")
        case .instagram: return Color(hex: "E4405F")
        case .linkedin: return Color(hex: "0A66C2")
        case .threads: return Color(hex: "000000")
        case .tiktok: return Color(hex: "000000")
        }
    }
}

struct RecentPost: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: String
    let platforms: [SocialPlatform]
}

// MARK: - Mock Data

let mockRecentPosts = [
    RecentPost(content: "Check out our latest repair deals! 🔧 Visit us today!", timestamp: "2 hours ago", platforms: [.x, .facebook, .instagram]),
    RecentPost(content: "New iPhone screen replacement service available now!", timestamp: "5 hours ago", platforms: [.x, .linkedin]),
    RecentPost(content: "Happy Friday! 🎉 We're open until 8 PM today.", timestamp: "Yesterday", platforms: [.facebook, .instagram])
]

// MARK: - Preview

struct SocialMediaManagerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SocialMediaManagerView()
        }
        .frame(width: 1200, height: 800)
    }
}
