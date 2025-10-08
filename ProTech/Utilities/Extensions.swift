//
//  Extensions.swift
//  ProTech
//
//  Useful extensions and notification names
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    static let newCustomer = Notification.Name("newCustomer")
    static let openTwilioTutorial = Notification.Name("openTwilioTutorial")
    static let openTwilioSettings = Notification.Name("openTwilioSettings")
    static let appointmentsDidChange = Notification.Name("appointmentsDidChange")
    
    // Quick Action Navigation
    static let navigateToQueue = Notification.Name("navigateToQueue")
    static let navigateToEstimates = Notification.Name("navigateToEstimates")
    static let navigateToPayments = Notification.Name("navigateToPayments")
    static let navigateToForms = Notification.Name("navigateToForms")
    static let navigateToSMS = Notification.Name("navigateToSMS")
    static let navigateToInventory = Notification.Name("navigateToInventory")
    
    // Kiosk Mode
    static let kioskModeEnabled = Notification.Name("kioskModeEnabled")
    static let kioskModeDisabled = Notification.Name("kioskModeDisabled")
    static let customerSelfRegistered = Notification.Name("customerSelfRegistered")
    
    // Check-In Queue
    static let customerCheckedIn = Notification.Name("customerCheckedIn")
}
