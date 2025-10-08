//
//  KioskModeManager.swift
//  ProTech
//
//  Manages kiosk mode for customer self-service
//

import Foundation
import SwiftUI

class KioskModeManager: ObservableObject {
    static let shared = KioskModeManager()
    
    @Published var isKioskModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isKioskModeEnabled, forKey: "kioskModeEnabled")
            if isKioskModeEnabled {
                NotificationCenter.default.post(name: .kioskModeEnabled, object: nil)
            } else {
                NotificationCenter.default.post(name: .kioskModeDisabled, object: nil)
            }
        }
    }
    
    @Published var requiresAdminUnlock: Bool = false
    
    @Published var kioskTitle: String {
        didSet {
            UserDefaults.standard.set(kioskTitle, forKey: "kioskTitle")
        }
    }
    
    @Published var kioskWelcomeMessage: String {
        didSet {
            UserDefaults.standard.set(kioskWelcomeMessage, forKey: "kioskWelcomeMessage")
        }
    }
    
    @Published var adminPasscode: String {
        didSet {
            UserDefaults.standard.set(adminPasscode, forKey: "kioskAdminPasscode")
        }
    }
    
    @Published var autoLogoutAfterSeconds: Int {
        didSet {
            UserDefaults.standard.set(autoLogoutAfterSeconds, forKey: "kioskAutoLogoutSeconds")
        }
    }
    
    private init() {
        self.isKioskModeEnabled = UserDefaults.standard.bool(forKey: "kioskModeEnabled")
        self.kioskTitle = UserDefaults.standard.string(forKey: "kioskTitle") ?? "Welcome to ProTech"
        self.kioskWelcomeMessage = UserDefaults.standard.string(forKey: "kioskWelcomeMessage") ?? "Please enter your phone number or email to check in"
        self.adminPasscode = UserDefaults.standard.string(forKey: "kioskAdminPasscode") ?? "1234"
        self.autoLogoutAfterSeconds = UserDefaults.standard.integer(forKey: "kioskAutoLogoutSeconds") == 0 ? 300 : UserDefaults.standard.integer(forKey: "kioskAutoLogoutSeconds")
    }
    
    func enableKioskMode() {
        isKioskModeEnabled = true
    }
    
    func disableKioskMode(withPasscode passcode: String) -> Bool {
        if passcode == adminPasscode {
            isKioskModeEnabled = false
            requiresAdminUnlock = false
            return true
        }
        return false
    }
    
    func requestAdminUnlock() {
        requiresAdminUnlock = true
    }
    
    func cancelAdminUnlock() {
        requiresAdminUnlock = false
    }
}
