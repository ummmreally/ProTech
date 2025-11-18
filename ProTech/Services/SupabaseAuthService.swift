//
//  SupabaseAuthService.swift
//  ProTech
//
//  Handles authentication with Supabase, including signup, login, and PIN fallback
//

import Foundation
import CoreData
import Supabase

@MainActor
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    private let authBridge = AuthenticationService.shared
    
    @Published var currentEmployee: Employee?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var isLoading = false
    
    // Session management
    private var sessionTimer: Timer?
    private let sessionTimeoutMinutes: TimeInterval = 30
    
    init() {
        // Don't auto-check session on init - let user explicitly log in
        // This prevents automatic login on app launch
        // Task {
        //     await checkCurrentSession()
        // }
    }
    
    // MARK: - Supabase Auth Methods
    
    /// Sign up new employee with Supabase Auth
    func signUpEmployee(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        shopId: UUID,
        role: String = "technician",
        pin: String? = nil
    ) async throws -> Employee {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Create Supabase Auth user with metadata
        // The metadata is used by the database trigger to auto-create employee record
        let authResponse: AuthResponse
        do {
            authResponse = try await supabase.client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "first_name": .string(firstName),
                    "last_name": .string(lastName),
                    "role": .string(role)
                ],
                redirectTo: URL(string: SupabaseConfig.redirectURL)
            )
        } catch {
            print("❌ Signup failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw SupabaseAuthError.signupFailed(error.localizedDescription)
        }
        
        let user = authResponse.user
        print("✅ Auth user created: \(user.id) - \(user.email ?? "no email")")
        
        // 2. Wait for the database trigger to create the employee record
        // Retry up to 5 times with increasing delays
        var employee: SupabaseEmployee?
        
        for attempt in 1...5 {
            do {
                // Wait before fetching (0.5s, 1s, 1.5s)
                try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                employee = try await fetchEmployeeByAuthId(user.id)
                print("✅ Employee record found on attempt \(attempt)")
                break
            } catch {
                print("⏳ Attempt \(attempt): Employee not found yet, retrying... Error: \(error)")
                if attempt == 5 {
                    print("❌ Trigger didn't create employee after 5 attempts")
                }
            }
        }
        
        // If still not found, employee record exists but we can't fetch it
        // This shouldn't happen with the trigger, but handle it gracefully
        guard let employee = employee else {
            throw SupabaseAuthError.employeeNotFound
        }
        
        // 4. Update PIN if provided (trigger doesn't handle PINs)
        if let pin = pin {
            try await updateEmployeePIN(employee.id, pin: pin)
        }
        
        // 5. Create local Core Data employee (but don't log in)
        let localEmployee = try syncLocalEmployee(from: employee)
        
        // Sign out after successful signup so user must log in explicitly
        try await signOut()
        
        return localEmployee
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        print("🔐 Starting sign in for: \(email)")
        isLoading = true
        defer { isLoading = false }
        
        // 1. Sign in with Supabase Auth
        print("📡 Attempting Supabase auth...")
        let session = try await supabase.client.auth.signIn(
            email: email,
            password: password
        )
        print("✅ Supabase auth successful - User ID: \(session.user.id)")
        
        // 2. Fetch employee data
        let userId = session.user.id
        print("🔍 Fetching employee record for auth ID: \(userId)")
        let employee = try await fetchEmployeeByAuthId(userId)
        let employeeFirstName = employee.firstName ?? "Unknown"
        let employeeLastName = employee.lastName ?? "Unknown"
        print("✅ Employee found: \(employeeFirstName) \(employeeLastName) - Role: \(employee.role)")
        
        // 3. Update local Core Data
        print("💾 Syncing to local Core Data...")
        let localEmployee = try syncLocalEmployee(from: employee)
        print("✅ Local employee synced: \(localEmployee.employeeNumber ?? "no number")")
        
        // 4. Update authentication state
        currentEmployee = localEmployee
        isAuthenticated = true
        authBridge.setAuthenticatedEmployee(localEmployee)
        startSessionTimer()
        print("✅ Authentication state updated - isAuthenticated: \(isAuthenticated)")
        
        // 5. Update shop context in SupabaseService
        await MainActor.run {
            supabase.currentShopId = employee.shopId.uuidString
            supabase.currentRole = employee.role
        }
        print("✅ Shop context updated - Shop: \(employee.shopId), Role: \(employee.role)")
        print("🎉 Sign in complete!")
    }
    
    /// Sign in with PIN (fallback for kiosk mode)
    func signInWithPIN(employeeNumber: String, pin: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Fetch employee by employee number
        let employee: SupabaseEmployee = try await supabase.client
            .from("employees")
            .select()
            .eq("employee_number", value: employeeNumber)
            .single()
            .execute()
            .value
        
        // 2. Verify PIN
        guard let storedPIN = employee.pinCode,
              pin.hashed() == storedPIN else {
            // Increment failed attempts
            try await incrementFailedPINAttempts(employee.id)
            throw SupabaseAuthError.invalidPIN
        }
        
        // 3. Check if account is locked
        if let lockedUntil = employee.pinLockedUntil,
           lockedUntil > Date() {
            throw SupabaseAuthError.accountLocked(until: lockedUntil)
        }
        
        // 4. Sign in using service account (for PIN-based auth)
        // This requires a service account that can impersonate users
        try await signInAsEmployee(employee)
        
        // 5. Reset failed attempts
        try await resetFailedPINAttempts(employee.id)
        
        // 6. Update local employee
        let localEmployee = try syncLocalEmployee(from: employee)
        
        currentEmployee = localEmployee
        isAuthenticated = true
        startSessionTimer()
    }
    
    /// Sign out current user
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.client.auth.signOut()
        
        currentEmployee = nil
        isAuthenticated = false
        authBridge.logout()
        stopSessionTimer()
        
        await MainActor.run {
            supabase.currentShopId = nil
            supabase.currentRole = nil
        }
    }
    
    // MARK: - URL Callback Handling
    
    /// Handle deep link callback from email confirmation
    func handleAuthCallback(url: URL) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Extract the URL components
        guard URLComponents(url: url, resolvingAgainstBaseURL: false) != nil else {
            throw SupabaseAuthError.invalidCallback
        }
        
        // Handle the auth callback
        // Supabase will include access_token, refresh_token in the URL
        try await supabase.client.auth.session(from: url)
        
        // Check and update session
        await checkCurrentSession()
    }
    
    // MARK: - Session Management
    
    /// Check if there's an active session
    func checkCurrentSession() async {
        do {
            let session = try await supabase.client.auth.session
            let authId = session.user.id
            if let employee = try? await fetchEmployeeByAuthId(authId) {
                let localEmployee = try syncLocalEmployee(from: employee)
                currentEmployee = localEmployee
                isAuthenticated = true
                authBridge.setAuthenticatedEmployee(localEmployee)
                await MainActor.run {
                    supabase.currentShopId = employee.shopId.uuidString
                    supabase.currentRole = employee.role
                }
            } else {
                print("⚠️ Session found but employee record missing for auth id: \(authId)")
                isAuthenticated = false
                authBridge.logout()
            }
        } catch {
            print("No active session: \(error)")
            isAuthenticated = false
            authBridge.logout()
        }
    }
    
    /// Refresh the current session
    func refreshSession() async throws {
        _ = try await supabase.client.auth.refreshSession()
        startSessionTimer() // Reset the timeout
    }
    
    // MARK: - Database Operations
    
    private func createEmployeeRecord(_ data: EmployeeCreateData) async throws -> SupabaseEmployee {
        let employee = SupabaseEmployee(
            id: data.id,
            shopId: data.shopId,
            authUserId: data.authUserId,
            employeeNumber: data.employeeNumber,
            email: data.email,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone,
            role: data.role,
            isActive: true,
            hourlyRate: 25.0,
            hireDate: Date(),
            pinCode: data.pinCode,
            failedPinAttempts: 0,
            pinLockedUntil: nil,
            lastLoginAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        try await supabase.client
            .from("employees")
            .insert(employee)
            .execute()
        
        return employee
    }
    
    private func fetchEmployeeByAuthId(_ authId: UUID) async throws -> SupabaseEmployee {
        // Query for employee by auth_user_id
        let response: [SupabaseEmployee] = try await supabase.client
            .from("employees")
            .select()
            .eq("auth_user_id", value: authId.uuidString)
            .execute()
            .value
        
        // Return first match or throw error
        guard let employee = response.first else {
            throw SupabaseAuthError.employeeNotFound
        }
        
        return employee
    }
    
    private func signInAsEmployee(_ employee: SupabaseEmployee) async throws {
        // For PIN-based auth, we need to create a session token
        // This would typically use a service role to generate a token
        // For now, we'll use the employee's linked auth account if it exists
        
        if employee.authUserId != nil {
            // If the employee has a linked auth account, use service role to get their session
            // This requires implementing a custom Edge Function for impersonation
            // For now, we'll throw an error indicating this needs to be implemented
            throw SupabaseAuthError.pinAuthNotFullyImplemented
        } else {
            // No linked auth account - need to create a temporary session
            throw SupabaseAuthError.noLinkedAuthAccount
        }
    }
    
    private func updateEmployeePIN(_ employeeId: UUID, pin: String) async throws {
        struct PinUpdate: Encodable {
            let pin_code: String
        }
        
        let updatePayload = PinUpdate(pin_code: pin.hashed())
        
        try await supabase.client
            .from("employees")
            .update(updatePayload)
            .eq("id", value: employeeId.uuidString)
            .execute()
    }
    
    private func incrementFailedPINAttempts(_ employeeId: UUID) async throws {
        let maxAttempts = 5
        
        // Fetch current attempts
        let employee: SupabaseEmployee = try await supabase.client
            .from("employees")
            .select()
            .eq("id", value: employeeId.uuidString)
            .single()
            .execute()
            .value
        
        let newAttempts = (employee.failedPinAttempts ?? 0) + 1
        
        let lockUntil = newAttempts >= maxAttempts ? Date().addingTimeInterval(15 * 60).iso8601String : nil
        let updatePayload = PinAttemptUpdate(
            failed_pin_attempts: newAttempts,
            pin_locked_until: lockUntil
        )
        
        try await supabase.client
            .from("employees")
            .update(updatePayload)
            .eq("id", value: employeeId.uuidString)
            .execute()
    }
    
    private func resetFailedPINAttempts(_ employeeId: UUID) async throws {
        let resetPayload = PinAttemptUpdate(
            failed_pin_attempts: 0,
            pin_locked_until: nil
        )
        try await supabase.client
            .from("employees")
            .update(resetPayload)
            .eq("id", value: employeeId.uuidString)
            .execute()
    }
    
    // MARK: - Core Data Sync
    
    private func createLocalEmployee(from remote: SupabaseEmployee) throws -> Employee {
        let employee = Employee(context: coreData.viewContext)
        employee.id = remote.id
        employee.createdAt = remote.createdAt
        updateLocalEmployee(employee, from: remote)
        try coreData.viewContext.save()
        return employee
    }
    
    private func syncLocalEmployee(from remote: SupabaseEmployee) throws -> Employee {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let employee = results.first {
            updateLocalEmployee(employee, from: remote)
        } else {
            return try createLocalEmployee(from: remote)
        }
        
        try coreData.viewContext.save()
        return results.first!
    }
    
    private func updateLocalEmployee(_ local: Employee, from remote: SupabaseEmployee) {
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
        local.updatedAt = remote.updatedAt
    }
    
    // MARK: - Session Timer
    
    private func startSessionTimer() {
        stopSessionTimer()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeoutMinutes * 60, repeats: false) { _ in
            Task { @MainActor in
                try? await self.signOut()
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
}

// MARK: - Models

struct EmployeeCreateData {
    let id: UUID
    let shopId: UUID
    let authUserId: UUID?
    var employeeNumber: String? = nil
    let email: String
    let firstName: String?
    let lastName: String?
    var phone: String? = nil
    let role: String
    var pinCode: String? = nil
}

struct PinAttemptUpdate: Encodable {
    let failed_pin_attempts: Int
    let pin_locked_until: String?
}

struct SupabaseEmployee: Codable {
    let id: UUID
    let shopId: UUID
    let authUserId: UUID?
    let employeeNumber: String?
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let role: String
    let isActive: Bool
    let hourlyRate: Double
    let hireDate: Date?
    let pinCode: String?
    let failedPinAttempts: Int?
    let pinLockedUntil: Date?
    let lastLoginAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopId = "shop_id"
        case authUserId = "auth_user_id"
        case employeeNumber = "employee_number"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case role
        case isActive = "is_active"
        case hourlyRate = "hourly_rate"
        case hireDate = "hire_date"
        case pinCode = "pin_code"
        case failedPinAttempts = "failed_pin_attempts"
        case pinLockedUntil = "pin_locked_until"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            if let date = iso8601WithFractionalSeconds.date(from: stringValue) ?? iso8601Formatter.date(from: stringValue) {
                return date
            }
            if let date = dateOnlyFormatter.date(from: stringValue) {
                return date
            }
        }
        return try container.decodeIfPresent(Date.self, forKey: key)
    }

    private static func decodeDouble(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Double {
        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return doubleValue
        }
        if let stringValue = try? container.decode(String.self, forKey: key), let doubleValue = Double(stringValue) {
            return doubleValue
        }
        throw DecodingError.dataCorrupted(.init(codingPath: [key], debugDescription: "Unable to decode Double"))
    }

    private static func encode(_ date: Date?, to container: inout KeyedEncodingContainer<CodingKeys>, forKey key: CodingKeys, formatter: ISO8601DateFormatter? = iso8601WithFractionalSeconds) throws {
        guard let date else {
            try container.encodeNil(forKey: key)
            return
        }
        if let formatter {
            try container.encode(formatter.string(from: date), forKey: key)
        } else {
            try container.encode(dateOnlyFormatter.string(from: date), forKey: key)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        shopId = try container.decode(UUID.self, forKey: .shopId)
        authUserId = try container.decodeIfPresent(UUID.self, forKey: .authUserId)
        employeeNumber = try container.decodeIfPresent(String.self, forKey: .employeeNumber)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        role = try container.decode(String.self, forKey: .role)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        hourlyRate = try SupabaseEmployee.decodeDouble(from: container, forKey: .hourlyRate)
        hireDate = try SupabaseEmployee.decodeDate(from: container, forKey: .hireDate)
        pinCode = try container.decodeIfPresent(String.self, forKey: .pinCode)
        failedPinAttempts = try container.decodeIfPresent(Int.self, forKey: .failedPinAttempts)
        pinLockedUntil = try SupabaseEmployee.decodeDate(from: container, forKey: .pinLockedUntil)
        lastLoginAt = try SupabaseEmployee.decodeDate(from: container, forKey: .lastLoginAt)
        createdAt = try SupabaseEmployee.decodeDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = try SupabaseEmployee.decodeDate(from: container, forKey: .updatedAt) ?? Date()
        deletedAt = try SupabaseEmployee.decodeDate(from: container, forKey: .deletedAt)
        syncVersion = try container.decode(Int.self, forKey: .syncVersion)
    }

    init(
        id: UUID,
        shopId: UUID,
        authUserId: UUID? = nil,
        employeeNumber: String? = nil,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        phone: String? = nil,
        role: String,
        isActive: Bool = true,
        hourlyRate: Double = 25.0,
        hireDate: Date? = nil,
        pinCode: String? = nil,
        failedPinAttempts: Int? = nil,
        pinLockedUntil: Date? = nil,
        lastLoginAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncVersion: Int = 1
    ) {
        self.id = id
        self.shopId = shopId
        self.authUserId = authUserId
        self.employeeNumber = employeeNumber
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.role = role
        self.isActive = isActive
        self.hourlyRate = hourlyRate
        self.hireDate = hireDate
        self.pinCode = pinCode
        self.failedPinAttempts = failedPinAttempts
        self.pinLockedUntil = pinLockedUntil
        self.lastLoginAt = lastLoginAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncVersion = syncVersion
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(shopId, forKey: .shopId)
        try container.encodeIfPresent(authUserId, forKey: .authUserId)
        try container.encodeIfPresent(employeeNumber, forKey: .employeeNumber)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(role, forKey: .role)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(hourlyRate, forKey: .hourlyRate)

        if let hireDate {
            try container.encode(SupabaseEmployee.dateOnlyFormatter.string(from: hireDate), forKey: .hireDate)
        } else {
            try container.encodeNil(forKey: .hireDate)
        }

        try container.encodeIfPresent(pinCode, forKey: .pinCode)
        try container.encodeIfPresent(failedPinAttempts, forKey: .failedPinAttempts)
        try SupabaseEmployee.encode(pinLockedUntil, to: &container, forKey: .pinLockedUntil)
        try SupabaseEmployee.encode(lastLoginAt, to: &container, forKey: .lastLoginAt)
        try SupabaseEmployee.encode(createdAt, to: &container, forKey: .createdAt)
        try SupabaseEmployee.encode(updatedAt, to: &container, forKey: .updatedAt)
        try SupabaseEmployee.encode(deletedAt, to: &container, forKey: .deletedAt)
        try container.encode(syncVersion, forKey: .syncVersion)
    }
}

// MARK: - Errors

enum SupabaseAuthError: LocalizedError {
    case signupFailed(String)
    case invalidCredentials
    case invalidPIN
    case accountLocked(until: Date)
    case employeeNotFound
    case noLinkedAuthAccount
    case pinAuthNotFullyImplemented
    case networkError(Error)
    case sessionExpired
    case invalidCallback
    
    var errorDescription: String? {
        switch self {
        case .signupFailed(let message):
            return "Signup failed: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidPIN:
            return "Invalid PIN"
        case .accountLocked(let until):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Account locked until \(formatter.string(from: until))"
        case .employeeNotFound:
            return "Employee record not found"
        case .noLinkedAuthAccount:
            return "No linked authentication account"
        case .pinAuthNotFullyImplemented:
            return "PIN authentication requires additional setup"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .invalidCallback:
            return "Invalid authentication callback URL"
        }
    }
}

// MARK: - String Extension for Hashing

extension String {
    func hashed() -> String {
        // In production, use proper hashing like bcrypt
        // For now, using a simple SHA256
        let data = Data(self.utf8)
        let hash = data.base64EncodedString()
        return hash
    }
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
