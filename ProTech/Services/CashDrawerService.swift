//
//  CashDrawerService.swift
//  ProTech
//
//  Manages cash drawer operations, tracking cash-in-hand and drawer events.
//

import Foundation
import CoreData

class CashDrawerService: ObservableObject {
    static let shared = CashDrawerService()
    private let coreDataManager = CoreDataManager.shared
    
    @Published var currentDrawerId: UUID?
    
    private init() {
        // Restore active drawer session if exists
        // simplified logic for MVP
        self.currentDrawerId = UserDefaults.standard.string(forKey: "activeDrawerId").flatMap { UUID(uuidString: $0) }
    }
    
    var isDrawerOpen: Bool {
        return currentDrawerId != nil
    }
    
    // MARK: - Actions
    
    func openDrawer(startingBalance: Decimal, employeeId: UUID) {
        // Start a new drawer session
        // In a real app, this would create a `DrawerSession` entity in Core Data
        print("💵 Opening Drawer with $\(startingBalance)")
        
        let sessionID = UUID()
        currentDrawerId = sessionID
        UserDefaults.standard.set(sessionID.uuidString, forKey: "activeDrawerId")
        UserDefaults.standard.set(Double(truncating: startingBalance as NSNumber), forKey: "drawer_\(sessionID)_start")
        
        logEvent(type: "OPEN", amount: startingBalance, employeeId: employeeId, note: "Start of shift")
    }
    
    func closeDrawer(closingBalance: Decimal, employeeId: UUID) -> Decimal {
        guard let sessionID = currentDrawerId else { return 0 }
        
        // Calculate Expected
        let starting = Decimal(UserDefaults.standard.double(forKey: "drawer_\(sessionID)_start"))
        let cashSales = calculateCashSales(for: sessionID)
        let expected = starting + cashSales
        
        let discrepancy = closingBalance - expected
        
        print("💵 Closing Drawer. Expected: \(expected), Actual: \(closingBalance), Diff: \(discrepancy)")
        
        logEvent(type: "CLOSE", amount: closingBalance, employeeId: employeeId, note: "End of shift. Discrepancy: \(discrepancy)")
        
        // Cleanup
        currentDrawerId = nil
        UserDefaults.standard.removeObject(forKey: "activeDrawerId")
        
        return discrepancy
    }
    
    func addCash(amount: Decimal, reason: String, employeeId: UUID) {
        guard isDrawerOpen else { return }
        print("💵 Pay In: +$\(amount) (\(reason))")
        logEvent(type: "PAY_IN", amount: amount, employeeId: employeeId, note: reason)
    }
    
    func removeCash(amount: Decimal, reason: String, employeeId: UUID) {
        guard isDrawerOpen else { return }
        print("💵 Pay Out: -$\(amount) (\(reason))")
        logEvent(type: "PAY_OUT", amount: amount, employeeId: employeeId, note: reason)
    }
    
    // MARK: - Helpers
    
    private func logEvent(type: String, amount: Decimal, employeeId: UUID, note: String?) {
        // Persist to Core Data or Log file
        // For MVP, we'll log to console and potentially a simple Core Data entity if we created one
        // Avoiding creating new Entity for this specific task unless strictly necessary to avoid migration complexity in the same step
        print("[DRAWER LOG] \(type) | \(amount) | \(note ?? "")")
    }
    
    private func calculateCashSales(for sessionId: UUID) -> Decimal {
        // Query PaymentService for cash transactions since session start
        // Stub:
        return 0.0
    }
}
