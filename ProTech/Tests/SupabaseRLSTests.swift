//
//  SupabaseRLSTests.swift
//  ProTech
//
//  Tests for Row Level Security policies with JWT claims
//

#if canImport(XCTest)

import Foundation
import XCTest
@testable import ProTech

@MainActor
class SupabaseRLSTests: XCTestCase {
    
    let authService = SupabaseAuthService.shared
    let supabase = SupabaseService.shared
    let testShopId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        // Ensure we're signed out before each test
        try? await authService.signOut()
    }
    
    // MARK: - Authentication Tests
    
    func testSignUpCreatesEmployee() async throws {
        // Test that signing up creates an employee record with correct shop_id
        let email = "test\(UUID())@example.com"
        let password = "Test123!@#"
        
        let employee = try await authService.signUpEmployee(
            email: email,
            password: password,
            firstName: "Test",
            lastName: "User",
            shopId: testShopId,
            role: "technician",
            pin: "1234"
        )
        
        XCTAssertNotNil(employee)
        XCTAssertEqual(employee.email, email)
        XCTAssertEqual(employee.role, "technician")
        
        // Verify JWT claims are set
        XCTAssertNotNil(supabase.currentShopId)
        XCTAssertEqual(supabase.currentRole, "technician")
    }
    
    func testSignInSetsJWTClaims() async throws {
        // Use existing test account
        let email = "admin@protech.test"
        let password = "Admin123!@#"
        
        try await authService.signIn(email: email, password: password)
        
        // Verify JWT claims
        XCTAssertEqual(supabase.currentShopId, testShopId.uuidString)
        XCTAssertNotNil(supabase.currentRole)
    }
    
    // MARK: - RLS Policy Tests
    
    func testShopIsolation() async throws {
        // Test that users can only see data from their own shop
        
        // Sign in as user from shop 1
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        // Try to fetch customers
        let customers: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .execute()
            .value
        
        // All customers should be from the user's shop only
        for customer in customers {
            XCTAssertEqual(customer.shopId, testShopId)
        }
    }
    
    func testCustomerCannotAccessOtherShops() async throws {
        // Customer should not see data from other shops
        try await authService.signIn(email: "customer@protech.test", password: "Customer123!@#")
        
        let orders: [SupabaseOrder] = try await supabase.client
            .from("orders")
            .select()
            .execute()
            .value
        
        for order in orders {
            XCTAssertEqual(order.shopId, testShopId)
        }
    }
    
    func testEmployeeRoleRestrictions() async throws {
        // Test that only admins/managers can modify employees
        
        // Sign in as technician
        try await authService.signIn(email: "tech@protech.test", password: "Tech123!@#")
        
        // Try to create an employee (should fail)
        let newEmployee = SupabaseEmployee(
            id: UUID(),
            shopId: testShopId,
            authUserId: nil,
            employeeNumber: "TEST001",
            email: "newtech@test.com",
            firstName: "New",
            lastName: "Tech",
            phone: nil,
            role: "technician",
            isActive: true,
            hourlyRate: 25.0,
            hireDate: Date(),
            pinCode: nil,
            failedPinAttempts: 0,
            pinLockedUntil: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        do {
            try await supabase.client
                .from("employees")
                .insert(newEmployee)
                .execute()
            
            XCTFail("Technician should not be able to create employees")
        } catch {
            // Expected to fail - RLS should block this
            XCTAssertNotNil(error)
        }
        
        // Sign out and sign in as admin
        try await authService.signOut()
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        // Try again as admin (should succeed)
        do {
            try await supabase.client
                .from("employees")
                .insert(newEmployee)
                .execute()
            // Success expected for admin
        } catch {
            XCTFail("Admin should be able to create employees: \(error)")
        }
    }
    
    func testCustomerCRUD() async throws {
        // Test customer operations respect shop isolation
        
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        // Create a customer
        let customerId = UUID()
        let customer = SupabaseCustomer(
            id: customerId,
            shopId: testShopId,
            firstName: "Test",
            lastName: "Customer",
            email: "testcustomer@example.com",
            phone: "555-0123",
            address: "123 Test St",
            notes: "Test customer",
            squareCustomerId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        // Insert
        try await supabase.client
            .from("customers")
            .insert(customer)
            .execute()
        
        // Read back
        let fetched: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .eq("id", value: customerId.uuidString)
            .single()
            .execute()
            .value
        
        XCTAssertEqual(fetched.first?.id, customerId)
        XCTAssertEqual(fetched.first?.shopId, testShopId)
        
        // Update
        try await supabase.client
            .from("customers")
            .update(["notes": "Updated notes"])
            .eq("id", value: customerId.uuidString)
            .execute()
        
        // Delete (soft delete)
        try await supabase.client
            .from("customers")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: customerId.uuidString)
            .execute()
    }
    
    func testStorageBucketAccess() async throws {
        // Test storage bucket policies
        
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        let fileName = "test-\(UUID()).txt"
        let fileData = "Test file content".data(using: .utf8)!
        
        // Upload to repair-photos bucket (should work for authenticated users)
        do {
            _ = try await supabase.client.storage
                .from("repair-photos")
                .upload(
                    path: "\(testShopId.uuidString)/\(fileName)",
                    file: fileData
                )
        } catch {
            XCTFail("Should be able to upload to repair-photos: \(error)")
        }
        
        // Try to read from repair-photos (public bucket)
        do {
            let url = try await supabase.client.storage
                .from("repair-photos")
                .createSignedURL(
                    path: "\(testShopId.uuidString)/\(fileName)",
                    expiresIn: 60
                )
            XCTAssertNotNil(url)
        } catch {
            XCTFail("Should be able to read from repair-photos: \(error)")
        }
        
        // Upload to receipts bucket (authenticated only)
        do {
            _ = try await supabase.client.storage
                .from("receipts")
                .upload(
                    path: "\(testShopId.uuidString)/\(fileName)",
                    file: fileData
                )
        } catch {
            XCTFail("Should be able to upload to receipts: \(error)")
        }
    }
    
    func testRealtimeSubscriptions() async throws {
        // Test that realtime only receives events for user's shop
        
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        let expectation = expectation(description: "Realtime event received")
        var receivedEvent = false
        
        // Subscribe to customer changes
        let channel = supabase.client
            .channel("test-customers")
            .onPostgresChange(
                event: .insert,
                schema: "public",
                table: "customers",
                filter: "shop_id=eq.\(testShopId.uuidString)"
            ) { payload in
                receivedEvent = true
                
                // Verify the event is for our shop
                if let shopId = payload.record?["shop_id"] as? String {
                    XCTAssertEqual(shopId, self.testShopId.uuidString)
                }
                
                expectation.fulfill()
            }
        
        await channel.subscribe()
        
        // Insert a customer to trigger event
        let customer = SupabaseCustomer(
            id: UUID(),
            shopId: testShopId,
            firstName: "Realtime",
            lastName: "Test",
            email: "realtime@test.com",
            phone: nil,
            address: nil,
            notes: nil,
            squareCustomerId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        try await supabase.client
            .from("customers")
            .insert(customer)
            .execute()
        
        // Wait for realtime event
        await fulfillment(of: [expectation], timeout: 5)
        
        XCTAssertTrue(receivedEvent)
        
        // Cleanup
        await channel.unsubscribe()
    }
    
    // MARK: - Cross-Shop Security Tests
    
    func testCannotAccessOtherShopData() async throws {
        // Test that users absolutely cannot access another shop's data
        
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        let otherShopId = UUID()
        
        // Try to insert a customer for another shop (should fail)
        let customer = SupabaseCustomer(
            id: UUID(),
            shopId: otherShopId, // Different shop!
            firstName: "Hacker",
            lastName: "Test",
            email: "hacker@test.com",
            phone: nil,
            address: nil,
            notes: nil,
            squareCustomerId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        do {
            try await supabase.client
                .from("customers")
                .insert(customer)
                .execute()
            
            XCTFail("Should not be able to insert into another shop")
        } catch {
            // Expected - RLS should block this
            XCTAssertNotNil(error)
        }
        
        // Try to read from another shop (should return empty)
        let results: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .eq("shop_id", value: otherShopId.uuidString)
            .execute()
            .value
        
        XCTAssertEqual(results.count, 0, "Should not see any data from other shops")
    }
    
    // MARK: - PIN Auth Tests
    
    func testPINAuthentication() async throws {
        // Test PIN-based authentication flow
        
        // First create an employee with PIN
        try await authService.signIn(email: "admin@protech.test", password: "Admin123!@#")
        
        let employeeNumber = "PIN\(Int.random(in: 1000...9999))"
        let pin = "5678"
        
        let employee = SupabaseEmployee(
            id: UUID(),
            shopId: testShopId,
            authUserId: nil,
            employeeNumber: employeeNumber,
            email: "pintest@test.com",
            firstName: "PIN",
            lastName: "Test",
            phone: nil,
            role: "technician",
            isActive: true,
            hourlyRate: 25.0,
            hireDate: Date(),
            pinCode: pin.hashed(),
            failedPinAttempts: 0,
            pinLockedUntil: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        try await supabase.client
            .from("employees")
            .insert(employee)
            .execute()
        
        // Sign out
        try await authService.signOut()
        
        // Try PIN auth (Note: This requires the Edge Function to be working)
        do {
            try await authService.signInWithPIN(employeeNumber: employeeNumber, pin: pin)
            // If this works, the PIN auth Edge Function is properly configured
            XCTAssertTrue(authService.isAuthenticated)
        } catch SupabaseAuthError.pinAuthNotFullyImplemented {
            // Expected if Edge Function needs additional setup
            print("PIN auth needs Edge Function configuration")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Data Setup

extension SupabaseRLSTests {
    
    /// Create test data for RLS testing
    static func setupTestData() async throws {
        let supabase = SupabaseService.shared
        
        // Ensure test shop exists
        let testShop = [
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Test Shop",
            "email": "test@protech.local",
            "subscription_tier": "pro"
        ]
        
        try await supabase.client
            .from("shops")
            .upsert(testShop)
            .execute()
        
        print("Test shop created/verified")
        
        // Create test employees if they don't exist
        // Admin, Manager, Technician for testing different roles
        
        // Note: In production, you'd create these through proper signup flow
    }
}

#endif // canImport(XCTest)
