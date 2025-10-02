//
//  SquareWebhookHandler.swift
//  ProTech
//
//  Handles incoming webhooks from Square
//

import Foundation
import Network

/// Webhook handler for Square events
/// Note: This requires a web server to receive webhooks
/// For development, use ngrok to expose local server
class SquareWebhookHandler {
    static let shared = SquareWebhookHandler()
    
    private var syncManager: SquareInventorySyncManager?
    private let eventQueue = DispatchQueue(label: "SquareWebhookQueue", qos: .userInitiated)
    
    private init() {}
    
    func configure(syncManager: SquareInventorySyncManager) {
        self.syncManager = syncManager
    }
    
    // MARK: - Webhook Processing
    
    func handleWebhook(body: String, signature: String) async throws {
        // Verify signature
        guard SquareAPIService.shared.verifyWebhookSignature(body: body, signature: signature) else {
            throw WebhookError.invalidSignature
        }
        
        // Parse event
        guard let data = body.data(using: .utf8) else {
            throw WebhookError.invalidPayload
        }
        
        let event = try JSONDecoder().decode(WebhookEvent.self, from: data)
        
        // Process event
        try await processEvent(event)
    }
    
    private func processEvent(_ event: WebhookEvent) async throws {
        guard let syncManager = syncManager else {
            throw WebhookError.notConfigured
        }
        
        print("📨 Received webhook: \(event.type)")
        
        // Route to appropriate handler based on event type
        switch event.type {
        case let type where type.contains("inventory"):
            try await handleInventoryEvent(event)
        case let type where type.contains("catalog"):
            try await handleCatalogEvent(event)
        default:
            print("⚠️ Unhandled webhook type: \(event.type)")
        }
        
        // Log the webhook event
        try await syncManager.processWebhookEvent(event)
    }
    
    private func handleInventoryEvent(_ event: WebhookEvent) async throws {
        guard let syncManager = syncManager else { return }
        
        // Extract object ID from event
        let objectId = event.data.id
        
        // Find mapping
        await MainActor.run {
            if syncManager.getMapping(forSquareObjectId: objectId) != nil {
                print("🔄 Syncing inventory for item: \(objectId)")
                // Sync will be handled by processWebhookEvent
            } else {
                print("⚠️ No mapping found for Square object: \(objectId)")
            }
        }
    }
    
    private func handleCatalogEvent(_ event: WebhookEvent) async throws {
        guard let syncManager = syncManager else { return }
        
        let objectId = event.data.id
        
        await MainActor.run {
            if event.type.contains("deleted") {
                // Handle item deletion
                if syncManager.getMapping(forSquareObjectId: objectId) != nil {
                    print("🗑️ Item deleted in Square: \(objectId)")
                    // Optionally delete or mark as inactive in ProTech
                }
            } else {
                // Handle item update/creation
                if syncManager.getMapping(forSquareObjectId: objectId) != nil {
                    print("🔄 Syncing catalog item: \(objectId)")
                    // Sync will be handled by processWebhookEvent
                } else {
                    print("➕ New item in Square: \(objectId)")
                    // Optionally import new item
                }
            }
        }
    }
    
    // MARK: - Webhook Registration
    
    func registerWebhooks(url: String) async throws -> Webhook {
        let eventTypes = [
            "inventory.count.updated",
            "catalog.version.updated"
        ]
        
        return try await SquareAPIService.shared.registerWebhook(url: url, eventTypes: eventTypes)
    }
}

// MARK: - Errors

enum WebhookError: Error, LocalizedError {
    case invalidSignature
    case invalidPayload
    case notConfigured
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            return "Invalid webhook signature"
        case .invalidPayload:
            return "Invalid webhook payload"
        case .notConfigured:
            return "Webhook handler not configured"
        case .processingFailed(let message):
            return "Webhook processing failed: \(message)"
        }
    }
}

// MARK: - Simple HTTP Server for Webhooks (Development Only)

#if DEBUG
import Network

/// Simple HTTP server for receiving webhooks during development
/// In production, use a proper web server or cloud function
class WebhookServer {
    private var listener: NWListener?
    private let port: UInt16
    private let handler: SquareWebhookHandler
    
    init(port: UInt16 = 8080, handler: SquareWebhookHandler = .shared) {
        self.port = port
        self.handler = handler
    }
    
    func start() throws {
        let parameters = NWParameters.tcp
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener?.start(queue: .main)
        print("🌐 Webhook server listening on port \(port)")
        print("💡 Use ngrok to expose: ngrok http \(port)")
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        print("🛑 Webhook server stopped")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processRequest(data: data, connection: connection)
            }
            
            if isComplete {
                connection.cancel()
            }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: 400, body: "Bad Request")
            return
        }
        
        // Parse HTTP request (simplified)
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first,
              requestLine.contains("POST /webhook") else {
            sendResponse(connection: connection, status: 404, body: "Not Found")
            return
        }
        
        // Extract headers and body
        var headers: [String: String] = [:]
        var bodyStart = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStart = index + 1
                break
            }
            
            if line.contains(":") {
                let parts = line.components(separatedBy: ": ")
                if parts.count == 2 {
                    headers[parts[0]] = parts[1]
                }
            }
        }
        
        let body = lines[bodyStart...].joined(separator: "\r\n")
        let signature = headers["X-Square-Signature"] ?? ""
        
        // Process webhook
        Task {
            do {
                try await handler.handleWebhook(body: body, signature: signature)
                sendResponse(connection: connection, status: 200, body: "OK")
            } catch {
                sendResponse(connection: connection, status: 500, body: "Internal Server Error")
            }
        }
    }
    
    private func sendResponse(connection: NWConnection, status: Int, body: String) {
        let response = """
        HTTP/1.1 \(status) \(statusText(status))
        Content-Type: text/plain
        Content-Length: \(body.utf8.count)
        Connection: close
        
        \(body)
        """
        
        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }
    
    private func statusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}
#endif
