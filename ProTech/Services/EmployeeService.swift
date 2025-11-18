//
//  EmployeeService.swift
//  ProTech
//
//  Service for employee management operations
//

import Foundation
import CoreData
import CryptoKit

class EmployeeService: ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    func createEmployee(
        firstName: String,
        lastName: String,
        email: String,
        role: EmployeeRole,
        pinCode: String? = nil,
        password: String? = nil,
        hourlyRate: Decimal = 25.00,
        phone: String? = nil
    ) throws -> Employee {
        // Check if email already exists
        if let _ = Employee.fetchEmployeeByEmail(email, context: context) {
            throw EmployeeError.emailAlreadyExists
        }
        
        // Validate PIN if provided
        if let pin = pinCode, !pin.isEmpty {
            if !isValidPIN(pin) {
                throw EmployeeError.invalidPIN
            }
        }
        
        let employee = Employee(
            context: context,
            firstName: firstName,
            lastName: lastName,
            email: email,
            role: role,
            pinCode: pinCode,
            hourlyRate: hourlyRate
        )
        
        employee.phone = phone
        
        // Hash password if provided
        if let password = password, !password.isEmpty {
            guard isValidPassword(password) else {
                throw EmployeeError.invalidPassword
            }
            employee.passwordHash = hashPassword(password)
        }
        
        try context.save()
        return employee
    }
    
    func updateEmployee(
        _ employee: Employee,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        role: EmployeeRole? = nil,
        pinCode: String? = nil,
        hourlyRate: Decimal? = nil,
        phone: String? = nil,
        isActive: Bool? = nil
    ) throws {
        if let firstName = firstName {
            employee.firstName = firstName
        }
        if let lastName = lastName {
            employee.lastName = lastName
        }
        if let email = email {
            // Check if new email is already used by another employee
            if let existingEmployee = Employee.fetchEmployeeByEmail(email, context: context),
               existingEmployee.id != employee.id {
                throw EmployeeError.emailAlreadyExists
            }
            employee.email = email
        }
        if let role = role {
            employee.roleType = role
        }
        if let pinCode = pinCode {
            if !pinCode.isEmpty && !isValidPIN(pinCode) {
                throw EmployeeError.invalidPIN
            }
            employee.pinCode = pinCode
        }
        if let hourlyRate = hourlyRate {
            employee.hourlyRate = NSDecimalNumber(decimal: hourlyRate)
        }
        if let phone = phone {
            employee.phone = phone
        }
        if let isActive = isActive {
            employee.isActive = isActive
        }
        
        employee.updatedAt = Date()
        try context.save()
    }
    
    func updateEmployeePassword(_ employee: Employee, newPassword: String) throws {
        guard isValidPassword(newPassword) else {
            throw EmployeeError.invalidPassword
        }
        
        employee.passwordHash = hashPassword(newPassword)
        employee.updatedAt = Date()
        try context.save()
    }
    
    func deleteEmployee(_ employee: Employee) throws {
        context.delete(employee)
        try context.save()
    }
    
    func deactivateEmployee(_ employee: Employee) throws {
        employee.isActive = false
        employee.updatedAt = Date()
        try context.save()
    }
    
    func activateEmployee(_ employee: Employee) throws {
        employee.isActive = true
        employee.updatedAt = Date()
        try context.save()
    }
    
    // MARK: - Fetch Operations
    
    func fetchAllEmployees() -> [Employee] {
        let request = Employee.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isActive", ascending: false),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }
    
    func fetchActiveEmployees() -> [Employee] {
        return Employee.fetchActiveEmployees(context: context)
    }
    
    func fetchEmployeesByRole(_ role: EmployeeRole) -> [Employee] {
        return Employee.fetchEmployeesByRole(role, context: context)
    }
    
    func fetchEmployeeByEmail(_ email: String) -> Employee? {
        return Employee.fetchEmployeeByEmail(email, context: context)
    }
    
    func fetchEmployeeById(_ id: UUID) -> Employee? {
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    // MARK: - Statistics
    
    func getTotalEmployeeCount() -> Int {
        let request = Employee.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    func getActiveEmployeeCount() -> Int {
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        return (try? context.count(for: request)) ?? 0
    }
    
    func getEmployeeCountByRole(_ role: EmployeeRole) -> Int {
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND isActive == true", role.rawValue)
        return (try? context.count(for: request)) ?? 0
    }
    
    // MARK: - Validation
    
    func isValidPIN(_ pin: String) -> Bool {
        guard pin.range(of: #"^\\d{6}$"#, options: .regularExpression) != nil else { return false }
        let digits = pin.compactMap { $0.wholeNumberValue }
        guard digits.count == 6 else { return false }
        let repeated = Set(digits).count == 1
        let ascending = zip(digits, digits.dropFirst()).allSatisfy { (current, next) in next == current + 1 }
        let descending = zip(digits, digits.dropFirst()).allSatisfy { (current, next) in next == current - 1 }
        return !repeated && !ascending && !descending
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return emailTest.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 10 else { return false }
        let uppercase = CharacterSet.uppercaseLetters
        let lowercase = CharacterSet.lowercaseLetters
        let digits = CharacterSet.decimalDigits
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_-+=[]{}|\\:;\"'<>?,./")
        guard password.rangeOfCharacter(from: uppercase) != nil else { return false }
        guard password.rangeOfCharacter(from: lowercase) != nil else { return false }
        guard password.rangeOfCharacter(from: digits) != nil else { return false }
        guard password.rangeOfCharacter(from: specialCharacters) != nil else { return false }
        return true
    }
    
    // MARK: - Password Hashing
    
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func verifyPassword(_ password: String, hash: String) -> Bool {
        return hashPassword(password) == hash
    }
    
}

// MARK: - Employee Errors
enum EmployeeError: LocalizedError {
    case emailAlreadyExists
    case invalidPIN
    case invalidPassword
    case employeeNotFound
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyExists:
            return "An employee with this email already exists"
        case .invalidPIN:
            return "PIN must be 6 digits with no repeats or sequences"
        case .invalidPassword:
            return "Password must be at least 10 characters with upper/lowercase, number, and symbol"
        case .employeeNotFound:
            return "Employee not found"
        }
    }
}
