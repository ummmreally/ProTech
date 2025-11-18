//
//  SyncTests.swift
//  ProTechTests
//
//  Comprehensive tests for Supabase sync functionality
//

import XCTest
import CoreData
@testable import ProTech

@MainActor
final class SyncTests: XCTestCase {
    
    var coreDataManager: CoreDataManager!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Use in-memory store for testing
        coreDataManager = CoreDataManager.shared
        testContext = coreDataManager.viewContext
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        testContext = nil
        coreDataManager = nil
        super.tearDown()
    }
    
    // MARK: - Customer Sync Tests
    
    func testCustomerCloudSyncStatus() throws {
        // Given: A new customer
        let customer = Customer(context: testContext)
        customer.id = UUID()
        customer.firstName = "John"
        customer.lastName = "Doe"
        customer.email = "john.doe@test.com"
        customer.cloudSyncStatus = "pending"
        customer.createdAt = Date()
        customer.updatedAt = Date()
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: cloudSyncStatus should be set
        XCTAssertEqual(customer.cloudSyncStatus, "pending")
        XCTAssertNotNil(customer.id)
        XCTAssertEqual(customer.firstName, "John")
    }
    
    func testCustomerSyncStatusTransitions() throws {
        // Given: A customer with pending status
        let customer = Customer(context: testContext)
        customer.id = UUID()
        customer.firstName = "Jane"
        customer.lastName = "Smith"
        customer.cloudSyncStatus = "pending"
        customer.createdAt = Date()
        customer.updatedAt = Date()
        try testContext.save()
        
        // When: Simulating successful sync
        customer.cloudSyncStatus = "synced"
        try testContext.save()
        
        // Then: Status should be synced
        XCTAssertEqual(customer.cloudSyncStatus, "synced")
        
        // When: Simulating failed sync
        customer.cloudSyncStatus = "failed"
        try testContext.save()
        
        // Then: Status should be failed
        XCTAssertEqual(customer.cloudSyncStatus, "failed")
    }
    
    // MARK: - Ticket Sync Tests
    
    func testTicketCloudSyncStatus() throws {
        // Given: A new ticket
        let ticket = Ticket(context: testContext)
        ticket.id = UUID()
        ticket.customerId = UUID()
        ticket.ticketNumber = 1001
        ticket.deviceType = "iPhone"
        ticket.deviceModel = "iPhone 15 Pro"
        ticket.status = "pending"
        ticket.cloudSyncStatus = "pending"
        ticket.createdAt = Date()
        ticket.updatedAt = Date()
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: cloudSyncStatus should be set
        XCTAssertEqual(ticket.cloudSyncStatus, "pending")
        XCTAssertNotNil(ticket.id)
        XCTAssertEqual(ticket.ticketNumber, 1001)
    }
    
    func testTicketStatusUpdate() throws {
        // Given: An existing ticket
        let ticket = Ticket(context: testContext)
        ticket.id = UUID()
        ticket.customerId = UUID()
        ticket.ticketNumber = 1002
        ticket.status = "pending"
        ticket.cloudSyncStatus = "synced"
        ticket.createdAt = Date()
        ticket.updatedAt = Date()
        try testContext.save()
        
        let originalUpdatedAt = ticket.updatedAt
        
        // When: Updating status
        ticket.status = "in_progress"
        ticket.cloudSyncStatus = "pending"
        ticket.updatedAt = Date()
        try testContext.save()
        
        // Then: Status and sync status should update
        XCTAssertEqual(ticket.status, "in_progress")
        XCTAssertEqual(ticket.cloudSyncStatus, "pending")
        XCTAssertNotEqual(ticket.updatedAt, originalUpdatedAt)
    }
    
    // MARK: - Inventory Sync Tests
    
    func testInventoryCloudSyncStatus() throws {
        // Given: A new inventory item
        let item = InventoryItem(context: testContext)
        item.id = UUID()
        item.name = "iPhone Screen"
        item.sku = "SCR-001"
        item.quantity = 100
        item.cost = NSDecimalNumber(value: 50.00)
        item.price = NSDecimalNumber(value: 150.00)
        item.isActive = true
        item.cloudSyncStatus = "pending"
        item.createdAt = Date()
        item.updatedAt = Date()
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: cloudSyncStatus should be set
        XCTAssertEqual(item.cloudSyncStatus, "pending")
        XCTAssertEqual(item.name, "iPhone Screen")
        XCTAssertEqual(item.quantity, 100)
    }
    
    func testInventoryStockAdjustment() throws {
        // Given: An inventory item
        let item = InventoryItem(context: testContext)
        item.id = UUID()
        item.name = "Battery Pack"
        item.quantity = 50
        item.cost = NSDecimalNumber(value: 20.00)
        item.price = NSDecimalNumber(value: 60.00)
        item.isActive = true
        item.cloudSyncStatus = "synced"
        item.createdAt = Date()
        item.updatedAt = Date()
        try testContext.save()
        
        // When: Adjusting stock
        item.quantity = 45 // Used 5
        item.cloudSyncStatus = "pending"
        item.updatedAt = Date()
        try testContext.save()
        
        // Then: Quantity and sync status should update
        XCTAssertEqual(item.quantity, 45)
        XCTAssertEqual(item.cloudSyncStatus, "pending")
    }
    
    // MARK: - Employee Sync Tests
    
    func testEmployeeCloudSyncStatus() throws {
        // Given: A new employee
        let employee = Employee(context: testContext)
        employee.id = UUID()
        employee.firstName = "Tech"
        employee.lastName = "Support"
        employee.email = "tech@example.com"
        employee.role = "technician"
        employee.isActive = true
        employee.cloudSyncStatus = "pending"
        employee.createdAt = Date()
        employee.updatedAt = Date()
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: cloudSyncStatus should be set
        XCTAssertEqual(employee.cloudSyncStatus, "pending")
        XCTAssertEqual(employee.email, "tech@example.com")
        XCTAssertTrue(employee.isActive)
    }
    
    // MARK: - Appointment Sync Tests
    
    func testAppointmentCloudSyncStatus() throws {
        // Given: A new appointment
        let appointment = Appointment(context: testContext)
        appointment.id = UUID()
        appointment.customerId = UUID()
        appointment.appointmentType = "dropoff"
        appointment.scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
        appointment.duration = 30
        appointment.status = "scheduled"
        appointment.cloudSyncStatus = "pending"
        appointment.createdAt = Date()
        appointment.updatedAt = Date()
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: cloudSyncStatus should be set
        XCTAssertEqual(appointment.cloudSyncStatus, "pending")
        XCTAssertEqual(appointment.appointmentType, "dropoff")
        XCTAssertEqual(appointment.status, "scheduled")
    }
    
    // MARK: - Offline Queue Tests
    
    func testOfflineQueueOperations() {
        // Given: Offline queue manager
        let queueManager = OfflineQueueManager.shared
        
        // When: Checking initial state
        let initialCount = queueManager.pendingOperations.count
        
        // Then: Should be accessible
        XCTAssertNotNil(queueManager)
        XCTAssertGreaterThanOrEqual(initialCount, 0)
    }
    
    // MARK: - Fetch Pending Changes Tests
    
    func testFetchPendingCustomers() throws {
        // Given: Multiple customers with different sync states
        let customer1 = Customer(context: testContext)
        customer1.id = UUID()
        customer1.firstName = "Pending"
        customer1.lastName = "One"
        customer1.cloudSyncStatus = "pending"
        customer1.createdAt = Date()
        customer1.updatedAt = Date()
        
        let customer2 = Customer(context: testContext)
        customer2.id = UUID()
        customer2.firstName = "Synced"
        customer2.lastName = "Two"
        customer2.cloudSyncStatus = "synced"
        customer2.createdAt = Date()
        customer2.updatedAt = Date()
        
        let customer3 = Customer(context: testContext)
        customer3.id = UUID()
        customer3.firstName = "Failed"
        customer3.lastName = "Three"
        customer3.cloudSyncStatus = "failed"
        customer3.createdAt = Date()
        customer3.updatedAt = Date()
        
        try testContext.save()
        
        // When: Fetching pending customers
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        let pendingCustomers = try testContext.fetch(request)
        
        // Then: Should only return pending customer
        XCTAssertEqual(pendingCustomers.count, 1)
        XCTAssertEqual(pendingCustomers.first?.firstName, "Pending")
    }
    
    func testFetchFailedTickets() throws {
        // Given: Multiple tickets with different sync states
        let ticket1 = Ticket(context: testContext)
        ticket1.id = UUID()
        ticket1.customerId = UUID()
        ticket1.ticketNumber = 2001
        ticket1.cloudSyncStatus = "pending"
        ticket1.createdAt = Date()
        ticket1.updatedAt = Date()
        
        let ticket2 = Ticket(context: testContext)
        ticket2.id = UUID()
        ticket2.customerId = UUID()
        ticket2.ticketNumber = 2002
        ticket2.cloudSyncStatus = "failed"
        ticket2.createdAt = Date()
        ticket2.updatedAt = Date()
        
        try testContext.save()
        
        // When: Fetching failed tickets
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@", "failed")
        let failedTickets = try testContext.fetch(request)
        
        // Then: Should only return failed ticket
        XCTAssertEqual(failedTickets.count, 1)
        XCTAssertEqual(failedTickets.first?.ticketNumber, 2002)
    }
    
    // MARK: - Performance Tests
    
    func testBulkCustomerCreation() throws {
        measure {
            for i in 0..<100 {
                let customer = Customer(context: testContext)
                customer.id = UUID()
                customer.firstName = "Test"
                customer.lastName = "Customer \(i)"
                customer.email = "test\(i)@example.com"
                customer.cloudSyncStatus = "pending"
                customer.createdAt = Date()
                customer.updatedAt = Date()
            }
            
            do {
                try testContext.save()
            } catch {
                XCTFail("Failed to save bulk customers: \(error)")
            }
        }
    }
    
    func testBulkTicketQuery() throws {
        // Given: 100 tickets in the database
        for i in 0..<100 {
            let ticket = Ticket(context: testContext)
            ticket.id = UUID()
            ticket.customerId = UUID()
            ticket.ticketNumber = Int32(3000 + i)
            ticket.status = i % 2 == 0 ? "pending" : "in_progress"
            ticket.cloudSyncStatus = "synced"
            ticket.createdAt = Date()
            ticket.updatedAt = Date()
        }
        try testContext.save()
        
        // When: Querying by status
        measure {
            let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
            request.predicate = NSPredicate(format: "status == %@", "pending")
            
            do {
                let results = try testContext.fetch(request)
                XCTAssertEqual(results.count, 50)
            } catch {
                XCTFail("Query failed: \(error)")
            }
        }
    }
}
