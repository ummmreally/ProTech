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
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        self.employeeService = EmployeeService(context: context)
    }
    
    // MARK: - Authentication Methods
    
    func loginWithPIN(_ pin: String) -> Result<Employee, AuthError> {
        guard let employee = Employee.fetchEmployeeByPIN(pin, context: context) else {
            return .failure(.invalidCredentials)
        }
        
        guard employee.isActive else {
            return .failure(.accountInactive)
        }
        
        setCurrentEmployee(employee)
        return .success(employee)
    }
    
    func loginWithEmail(_ email: String, password: String) -> Result<Employee, AuthError> {
        guard let employee = Employee.fetchEmployeeByEmail(email, context: context) else {
            return .failure(.invalidCredentials)
        }
        
        guard employee.isActive else {
            return .failure(.accountInactive)
        }
        
        guard let passwordHash = employee.passwordHash else {
            return .failure(.passwordNotSet)
        }
        
        guard employeeService.verifyPassword(password, hash: passwordHash) else {
            return .failure(.invalidCredentials)
        }
        
        setCurrentEmployee(employee)
        return .success(employee)
    }
    
    func logout() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        currentEmployee = nil
        isAuthenticated = false
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
            throw AuthError.insufficientPermissions
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
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case accountInactive
    case passwordNotSet
    case insufficientPermissions
    case notAuthenticated
    
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
        }
    }
}
