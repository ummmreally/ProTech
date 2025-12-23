//
//  AuthenticationService.swift
//  ProTech
//
//  Service for user authentication and session management
//

import Foundation
import CoreData
import Combine

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentEmployee: Employee?
    @Published var isAuthenticated = false
    
    private let context: NSManagedObjectContext
    private let employeeService: EmployeeService
    private var sessionTimer: Timer?
    
    private let sessionTimeoutMinutes: TimeInterval = 30 // Auto-logout after 30 minutes
    private let maxPinAttempts: Int16 = 5
    private let maxPasswordAttempts: Int16 = 5
    private let lockDuration: TimeInterval = 15 * 60
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        self.employeeService = EmployeeService(context: context)
    }
    
    // MARK: - Authentication Methods
    
    func loginWithPIN(_ pin: String) -> Result<Employee, LocalAuthError> {
        // PINs are stored hashed in Supabase and synced to Core Data
        // so we must hash the input PIN to match
        let hashedPin = pin.hashed()
        
        guard let employee = Employee.fetchEmployeeByPIN(hashedPin, context: context) else {
            return .failure(.invalidCredentials)
        }
        
        if let lockedUntil = employee.pinLockedUntil {
            if lockedUntil > Date() {
                return .failure(.accountLocked(until: lockedUntil))
            } else {
                resetPinFailures(for: employee)
            }
        }
        
        guard employee.isActive else {
            return .failure(.accountInactive)
        }
        
        resetPinFailures(for: employee)
        setCurrentEmployee(employee)
        return .success(employee)
    }
    
    func loginWithEmail(_ email: String, password: String) -> Result<Employee, LocalAuthError> {
        guard let employee = Employee.fetchEmployeeByEmail(email, context: context) else {
            return .failure(.invalidCredentials)
        }
        
        if let lockedUntil = employee.passwordLockedUntil {
            if lockedUntil > Date() {
                return .failure(.accountLocked(until: lockedUntil))
            } else {
                resetPasswordFailures(for: employee)
            }
        }
        
        guard employee.isActive else {
            return .failure(.accountInactive)
        }
        
        guard let passwordHash = employee.passwordHash else {
            return .failure(.passwordNotSet)
        }
        
        guard employeeService.verifyPassword(password, hash: passwordHash) else {
            recordPasswordFailure(for: employee)
            return .failure(.invalidCredentials)
        }
        
        resetPasswordFailures(for: employee)
        setCurrentEmployee(employee)
        return .success(employee)
    }
    
    func logout() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        currentEmployee = nil
        isAuthenticated = false
    }
    
    @MainActor
    func setAuthenticatedEmployee(_ employee: Employee) {
        setCurrentEmployee(employee)
    }
    
    private func setCurrentEmployee(_ employee: Employee) {
        currentEmployee = employee
        isAuthenticated = true
        employee.lastLoginAt = Date()
        try? context.save()
        
        // Start session timeout
        resetSessionTimer()
    }
    
    // MARK: - Session Management
    
    func resetSessionTimer() {
        sessionTimer?.invalidate()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeoutMinutes * 60, repeats: false) { [weak self] _ in
            self?.logout()
        }
    }
    
    func extendSession() {
        resetSessionTimer()
    }
    
    // MARK: - Permission Checks
    
    func hasPermission(_ permission: Permission) -> Bool {
        guard let employee = currentEmployee else { return false }
        return employee.hasPermission(permission)
    }
    
    func requirePermission(_ permission: Permission) throws {
        guard hasPermission(permission) else {
            throw LocalAuthError.insufficientPermissions
        }
    }
    
    func isAdmin() -> Bool {
        return currentEmployee?.isAdmin ?? false
    }
    
    // MARK: - Quick Access
    
    var currentEmployeeId: UUID? {
        return currentEmployee?.id
    }
    
    var currentEmployeeName: String {
        return currentEmployee?.fullName ?? "Unknown"
    }
    
    var currentEmployeeRole: EmployeeRole {
        return currentEmployee?.roleType ?? .technician
    }
    
    // MARK: - Lockout Helpers
    
    private func recordPasswordFailure(for employee: Employee) {
        employee.failedPasswordAttempts += 1
        employee.lastPasswordAttemptAt = Date()
        if employee.failedPasswordAttempts >= maxPasswordAttempts {
            employee.passwordLockedUntil = Date().addingTimeInterval(lockDuration)
            employee.failedPasswordAttempts = 0
        }
        saveContext()
    }
    
    private func resetPasswordFailures(for employee: Employee) {
        employee.failedPasswordAttempts = 0
        employee.passwordLockedUntil = nil
        saveContext()
    }
    
    private func resetPinFailures(for employee: Employee) {
        employee.failedPinAttempts = 0
        employee.pinLockedUntil = nil
        saveContext()
    }
    
    private func saveContext() {
        try? context.save()
    }
}

// MARK: - Auth Errors
enum LocalAuthError: LocalizedError {
    case invalidCredentials
    case accountInactive
    case passwordNotSet
    case insufficientPermissions
    case notAuthenticated
    case accountLocked(until: Date)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email/PIN or password"
        case .accountInactive:
            return "This account is inactive"
        case .passwordNotSet:
            return "Password not set for this account"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .notAuthenticated:
            return "Please log in to continue"
        case .accountLocked(let until):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Account locked until \(formatter.string(from: until))."
        }
    }
}
