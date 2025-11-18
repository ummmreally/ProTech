//
//  EmployeeSyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for employees
//

import Foundation
import CoreData
import Supabase

@MainActor
class EmployeeSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Upload
    
    /// Upload a local employee to Supabase
    func upload(_ employee: Employee) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        // Only admins/managers can manage employees
        guard let currentRole = supabase.currentRole,
              ["admin", "manager"].contains(currentRole) else {
            throw SyncError.insufficientPermissions
        }
        
        guard let employeeId = employee.id else {
            throw SyncError.conflict(details: "Employee missing ID")
        }
        
        let supabaseEmployee = SupabaseEmployee(
            id: employeeId,
            shopId: shopId,
            authUserId: nil, // Will be set when employee creates account
            employeeNumber: employee.employeeNumber,
            email: employee.email ?? "",
            firstName: employee.firstName,
            lastName: employee.lastName,
            phone: employee.phone,
            role: employee.role ?? "technician",
            isActive: employee.isActive,
            hourlyRate: Double(truncating: employee.hourlyRate),
            hireDate: employee.hireDate,
            pinCode: employee.pinCode?.hashed(),
            failedPinAttempts: Int(employee.failedPinAttempts),
            pinLockedUntil: employee.pinLockedUntil,
            lastLoginAt: employee.lastLoginAt,
            createdAt: employee.createdAt ?? Date(),
            updatedAt: employee.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1 // Default sync version
        )
        
        try await supabase.client
            .from("employees")
            .upsert(supabaseEmployee)
            .execute()
        
        // Mark as synced
        employee.cloudSyncStatus = "synced"
        employee.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        
        let pendingEmployees = try coreData.viewContext.fetch(request)
        
        for employee in pendingEmployees {
            try await upload(employee)
        }
    }
    
    // MARK: - Download
    
    /// Download all employees from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteEmployees: [SupabaseEmployee] = try await supabase.client
            .from("employees")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil)
            .order("last_name", ascending: true)
            .execute()
            .value
        
        for remote in remoteEmployees {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabaseEmployee) async throws {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let local = results.first {
            // Merge existing: use newest version
            if shouldUpdateLocal(local, from: remote) {
                updateLocal(local, from: remote)
            }
        } else {
            // Create new local record
            createLocal(from: remote)
        }
        
        try coreData.viewContext.save()
    }
    
    private func shouldUpdateLocal(_ local: Employee, from remote: SupabaseEmployee) -> Bool {
        // Use timestamp for comparison since Employee doesn't have syncVersion
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: Employee, from remote: SupabaseEmployee) {
        local.employeeNumber = remote.employeeNumber
        local.email = remote.email
        local.firstName = remote.firstName
        local.lastName = remote.lastName
        local.phone = remote.phone
        local.role = remote.role
        local.isAdmin = remote.role == "admin"
        local.isActive = remote.isActive
        local.hourlyRate = NSDecimalNumber(value: remote.hourlyRate)
        local.hireDate = remote.hireDate
        local.pinCode = remote.pinCode
        local.failedPinAttempts = Int16(remote.failedPinAttempts ?? 0)
        local.pinLockedUntil = remote.pinLockedUntil
        local.lastLoginAt = remote.lastLoginAt
        local.updatedAt = remote.updatedAt
        local.cloudSyncStatus = "synced"
    }
    
    private func createLocal(from remote: SupabaseEmployee) {
        let employee = Employee(context: coreData.viewContext)
        employee.id = remote.id
        employee.createdAt = remote.createdAt
        updateLocal(employee, from: remote)
    }
    
    // MARK: - Team Management
    
    /// Activate/deactivate an employee
    func setEmployeeActive(_ employeeId: UUID, isActive: Bool) async throws {
        guard let currentRole = supabase.currentRole,
              ["admin", "manager"].contains(currentRole) else {
            throw SyncError.insufficientPermissions
        }
        
        try await supabase.client
            .from("employees")
            .update(["is_active": isActive ? "true" : "false", "updated_at": Date().iso8601String])
            .eq("id", value: employeeId.uuidString)
            .execute()
        
        // Update local
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        
        if let employee = try coreData.viewContext.fetch(request).first {
            employee.isActive = isActive
            employee.updatedAt = Date()
            try coreData.viewContext.save()
        }
    }
    
    /// Update employee role
    func updateEmployeeRole(_ employeeId: UUID, role: String) async throws {
        guard let currentRole = supabase.currentRole,
              currentRole == "admin" else {
            throw SyncError.insufficientPermissions
        }
        
        let isAdmin = role == "admin"
        
        try await supabase.client
            .from("employees")
            .update([
                "role": role,
                "is_admin": isAdmin ? "true" : "false",
                "updated_at": Date().iso8601String
            ])
            .eq("id", value: employeeId.uuidString)
            .execute()
        
        // Update local
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        
        if let employee = try coreData.viewContext.fetch(request).first {
            employee.role = role
            employee.isAdmin = isAdmin
            employee.updatedAt = Date()
            try coreData.viewContext.save()
        }
    }
    
    /// Reset employee PIN
    func resetEmployeePIN(_ employeeId: UUID, newPIN: String) async throws {
        guard let currentRole = supabase.currentRole,
              ["admin", "manager"].contains(currentRole) else {
            throw SyncError.insufficientPermissions
        }
        
        let hashedPIN = newPIN.hashed()
        
        try await supabase.client
            .from("employees")
            .update([
                "pin_code": hashedPIN,
                "failed_pin_attempts": "0",
                "pin_locked_until": nil,
                "updated_at": Date().iso8601String
            ])
            .eq("id", value: employeeId.uuidString)
            .execute()
        
        // Update local
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        
        if let employee = try coreData.viewContext.fetch(request).first {
            employee.pinCode = hashedPIN
            employee.failedPinAttempts = 0
            employee.pinLockedUntil = nil
            employee.updatedAt = Date()
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Time Tracking
    
    /// Clock in/out for an employee
    func clockInOut(_ employeeId: UUID, isClockingIn: Bool) async throws {
        let timestamp = Date()
        
        // Update last login if clocking in
        if isClockingIn {
            try await supabase.client
                .from("employees")
                .update(["last_login_at": timestamp.iso8601String])
                .eq("id", value: employeeId.uuidString)
                .execute()
        }
        
        // In production, you'd also create a time_entries record here
        
        // Update local
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        
        if let employee = try coreData.viewContext.fetch(request).first {
            if isClockingIn {
                employee.lastLoginAt = timestamp
            }
            employee.updatedAt = Date()
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Analytics
    
    /// Get active employees count
    func getActiveEmployeeCount() async throws -> Int {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let response = try await supabase.client
            .from("employees")
            .select("id", head: false, count: .exact)
            .eq("shop_id", value: shopId.uuidString)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .execute()
        
        return response.count ?? 0
    }
    
    /// Get employees by role
    func getEmployeesByRole(_ role: String) async throws -> [Employee] {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let remoteEmployees: [SupabaseEmployee] = try await supabase.client
            .from("employees")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .eq("role", value: role)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        // Update local with fetched employees
        for remote in remoteEmployees {
            try await mergeOrCreate(remote)
        }
        
        // Return local employees
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND isActive == true", role)
        
        return try coreData.viewContext.fetch(request)
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Subscribe to realtime changes for employees
    func subscribeToChanges() async {
        // TODO: Implement proper Supabase Realtime API
        // The Realtime types (PostgresChangePayload, RealtimeChannel) need proper imports
        // For now, use polling as workaround
        print("Realtime subscriptions not yet implemented for EmployeeSyncer")
    }
    
    // TODO: Uncomment when Supabase Realtime types are available
    // private func handleRealtimeChange(_ payload: PostgresChangePayload) async { ... }
    
    private func deleteLocal(id: UUID) async throws {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let employee = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(employee)
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Batch Operations
    
    /// Batch import employees (for initial setup)
    func batchImport(_ employees: [EmployeeImportData]) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        guard let currentRole = supabase.currentRole,
              currentRole == "admin" else {
            throw SyncError.insufficientPermissions
        }
        
        let supabaseEmployees = employees.map { data -> SupabaseEmployee in
            SupabaseEmployee(
                id: UUID(),
                shopId: shopId,
                authUserId: nil,
                employeeNumber: data.employeeNumber,
                email: data.email,
                firstName: data.firstName,
                lastName: data.lastName,
                phone: data.phone,
                role: data.role ?? "technician",
                isActive: true,
                hourlyRate: data.hourlyRate ?? 25.0,
                hireDate: data.hireDate,
                pinCode: data.pin?.hashed(),
                failedPinAttempts: 0,
                pinLockedUntil: nil,
                lastLoginAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil,
                syncVersion: 1
            )
        }
        
        // Upload in batches of 50 (employees are more complex)
        let batchSize = 50
        for batch in supabaseEmployees.chunked(into: batchSize) {
            try await supabase.client
                .from("employees")
                .insert(batch)
                .execute()
        }
        
        // Download to sync local
        try await download()
    }
    
    // MARK: - Helpers
    
    private func getShopId() -> UUID? {
        if let shopIdString = supabase.currentShopId {
            return UUID(uuidString: shopIdString)
        }
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
}

// MARK: - Import Model

struct EmployeeImportData {
    let employeeNumber: String?
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let role: String?
    let hourlyRate: Double?
    let hireDate: Date?
    let pin: String?
}

// Note: SyncError.insufficientPermissions is already defined in SyncErrors.swift
