//
//  SquareSyncScheduler.swift
//  ProTech
//
//  Handles scheduled background synchronization with Square
//

import Foundation
import Combine
import Network

class SquareSyncScheduler: ObservableObject {
    static let shared = SquareSyncScheduler()
    
    @Published var isScheduled = false
    @Published var nextSyncDate: Date?
    
    private var timer: Timer?
    private var syncManager: SquareInventorySyncManager?
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var isConnected = true
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Scheduling
    
    func startScheduledSync(syncManager: SquareInventorySyncManager, interval: TimeInterval) {
        self.syncManager = syncManager
        stopScheduledSync()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performScheduledSync()
        }
        
        isScheduled = true
        updateNextSyncDate(interval: interval)
        
        print("✅ Square sync scheduled every \(interval.syncIntervalDisplayName)")
    }
    
    func stopScheduledSync() {
        timer?.invalidate()
        timer = nil
        isScheduled = false
        nextSyncDate = nil
        
        print("⏸️ Square sync scheduling stopped")
    }
    
    func performManualSync() {
        performScheduledSync()
    }
    
    // MARK: - Private Methods
    
    private func performScheduledSync() {
        guard isConnected else {
            print("⚠️ Skipping sync - no network connection")
            return
        }
        
        guard let syncManager = syncManager else {
            print("⚠️ Sync manager not configured")
            return
        }
        
        Task { @MainActor in
            do {
                let lastSync = UserDefaults.standard.object(forKey: "lastSquareSync") as? Date ?? .distantPast
                
                print("🔄 Starting scheduled sync (last sync: \(lastSync.formatted()))")
                
                try await syncManager.syncChangedItems(since: lastSync)
                
                UserDefaults.standard.set(Date(), forKey: "lastSquareSync")
                
                print("✅ Scheduled sync completed successfully")
            } catch {
                print("❌ Scheduled sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateNextSyncDate(interval: TimeInterval) {
        nextSyncDate = Date().addingTimeInterval(interval)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            
            if path.status == .satisfied {
                print("📡 Network connection restored")
            } else {
                print("📡 Network connection lost")
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Network Monitor Helper

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
