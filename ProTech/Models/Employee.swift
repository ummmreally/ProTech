//
//  Employee.swift
//  ProTech
//
//  Employee/User model for authentication and time tracking
//

import Foundation
import CoreData

@objc(Employee)
public class Employee: NSManagedObject {}

extension Employee: Identifiable {}

extension Employee {
    @NSManaged public var id: UUID?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var role: String? // Admin, Technician, FrontDesk
    @NSManaged public var pinCode: String? // 6 digit PIN for quick login
    @NSManaged public var passwordHash: String? // For secure password login
    @NSManaged public var hourlyRate: NSDecimalNumber
    @NSManaged public var isActive: Bool
    @NSManaged public var isAdmin: Bool
    @NSManaged public var employeeNumber: String?
    @NSManaged public var hireDate: Date?
    @NSManaged public var lastLoginAt: Date?
    @NSManaged public var failedPinAttempts: Int16
    @NSManaged public var lastPinAttemptAt: Date?
    @NSManaged public var pinLockedUntil: Date?
    @NSManaged public var failedPasswordAttempts: Int16
    @NSManaged public var lastPasswordAttemptAt: Date?
    @NSManaged public var passwordLockedUntil: Date?
    @NSManaged public var profileImageData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cloudSyncStatus: String?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    firstName: String,
                    lastName: String,
                    email: String,
                    role: EmployeeRole,
                    pinCode: String? = nil,
                    hourlyRate: Decimal = 25.00) {
        self.init(context: context)
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role.rawValue
        self.pinCode = pinCode
        self.hourlyRate = NSDecimalNumber(decimal: hourlyRate)
        self.isActive = true
        self.isAdmin = (role == .admin)
        self.employeeNumber = Employee.generateEmployeeNumber()
        self.hireDate = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.failedPinAttempts = 0
        self.failedPasswordAttempts = 0
    }
    
    // Generate unique employee number
    private static func generateEmployeeNumber() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomNum = Int.random(in: 1000...9999)
        return "EMP-\(timestamp % 10000)-\(randomNum)"
    }
}

// MARK: - Employee Role Enum
enum EmployeeRole: String, CaseIterable {
    case admin = "Admin"
    case technician = "Technician"
    case frontDesk = "Front Desk"
    case manager = "Manager"
    
    var permissions: [Permission] {
        switch self {
        case .admin:
            return Permission.allCases
        case .manager:
            return [.viewReports, .manageTickets, .manageCustomers, .manageInventory, .viewPayments]
        case .technician:
            return [.manageTickets, .viewCustomers, .viewInventory]
        case .frontDesk:
            return [.viewTickets, .manageCustomers, .viewInventory]
        }
    }
}

// MARK: - Permissions Enum
enum Permission: String, CaseIterable {
    case viewReports = "View Reports"
    case manageEmployees = "Manage Employees"
    case manageTickets = "Manage Tickets"
    case manageCustomers = "Manage Customers"
    case manageInventory = "Manage Inventory"
    case viewPayments = "View Payments"
    case processPayments = "Process Payments"
    case manageSettings = "Manage Settings"
    case viewTickets = "View Tickets"
    case viewCustomers = "View Customers"
    case viewInventory = "View Inventory"
}

// MARK: - Core Data Entity Description
extension Employee {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Employee"
        entity.managedObjectClassName = NSStringFromClass(Employee.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("firstName", type: .stringAttributeType, optional: false),
            makeAttribute("lastName", type: .stringAttributeType, optional: false),
            makeAttribute("email", type: .stringAttributeType, optional: false),
            makeAttribute("phone", type: .stringAttributeType),
            makeAttribute("role", type: .stringAttributeType, optional: false, defaultValue: "Technician"),
            makeAttribute("pinCode", type: .stringAttributeType),
            makeAttribute("passwordHash", type: .stringAttributeType),
            makeAttribute("hourlyRate", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber(value: 25.0)),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("isAdmin", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("employeeNumber", type: .stringAttributeType),
            makeAttribute("hireDate", type: .dateAttributeType),
            makeAttribute("lastLoginAt", type: .dateAttributeType),
            makeAttribute("failedPinAttempts", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("lastPinAttemptAt", type: .dateAttributeType),
            makeAttribute("pinLockedUntil", type: .dateAttributeType),
            makeAttribute("failedPasswordAttempts", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("lastPasswordAttemptAt", type: .dateAttributeType),
            makeAttribute("passwordLockedUntil", type: .dateAttributeType),
            makeAttribute("profileImageData", type: .binaryDataAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false),
            makeAttribute("cloudSyncStatus", type: .stringAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription,
           let emailAttribute = entity.properties.first(where: { $0.name == "email" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "employee_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            let emailIndex = NSFetchIndexDescription(name: "employee_email_index", elements: [NSFetchIndexElementDescription(property: emailAttribute, collationType: .binary)])
            entity.indexes = [idIndex, emailIndex]
        }
        
        return entity
    }
}

// MARK: - Fetch Requests
extension Employee {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }
    
    static func fetchActiveEmployees(context: NSManagedObjectContext) -> [Employee] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchEmployeeByEmail(_ email: String, context: NSManagedObjectContext) -> Employee? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    static func fetchEmployeeByPIN(_ pin: String, context: NSManagedObjectContext) -> Employee? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "pinCode == %@ AND isActive == true", pin)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    static func fetchEmployeesByRole(_ role: EmployeeRole, context: NSManagedObjectContext) -> [Employee] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND isActive == true", role.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Computed Properties
extension Employee {
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let first = firstName?.first?.uppercased() ?? ""
        let last = lastName?.first?.uppercased() ?? ""
        return "\(first)\(last)"
    }
    
    var roleType: EmployeeRole {
        get {
            let normalized = (role ?? "technician").lowercased()
            switch normalized {
            case "admin":
                return .admin
            case "manager":
                return .manager
            case "receptionist", "front desk", "front_desk":
                return .frontDesk
            case "technician":
                return .technician
            default:
                return .technician
            }
        }
        set {
            // Persist Supabase-compatible lowercase role identifiers
            switch newValue {
            case .admin:
                role = "admin"
            case .manager:
                role = "manager"
            case .technician:
                role = "technician"
            case .frontDesk:
                role = "receptionist"
            }
            isAdmin = (newValue == .admin)
        }
    }
    
    var hasPermission: (Permission) -> Bool {
        { permission in
            self.roleType.permissions.contains(permission)
        }
    }
    
    var displayRole: String {
        roleType.rawValue
    }
    
    var formattedHourlyRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: hourlyRate) ?? "$0.00"
    }
    
    var hasPINSet: Bool {
        return pinCode != nil && !pinCode!.isEmpty
    }
    
    var hasPasswordSet: Bool {
        return passwordHash != nil && !passwordHash!.isEmpty
    }
    
    /// Display name for migration purposes
    var migrationDisplayName: String {
        return fullName.isEmpty ? (email ?? "Unknown Employee") : fullName
    }
}
