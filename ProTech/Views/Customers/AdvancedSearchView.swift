//
//  AdvancedSearchView.swift
//  ProTech
//
//  Advanced search and filtering for customers
//

import SwiftUI
import CoreData

struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var searchCriteria: SearchCriteria
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Search") {
                    TextField("Name", text: $searchCriteria.name)
                    TextField("Email", text: $searchCriteria.email)
                    TextField("Phone", text: $searchCriteria.phone)
                }
                
                Section("Date Range") {
                    Toggle("Filter by date added", isOn: $searchCriteria.useDateFilter)
                    
                    if searchCriteria.useDateFilter {
                        DatePicker("From", selection: $searchCriteria.dateFrom, displayedComponents: .date)
                        DatePicker("To", selection: $searchCriteria.dateTo, displayedComponents: .date)
                    }
                }
                
                Section("Location") {
                    TextField("Address contains", text: $searchCriteria.addressContains)
                }
                
                Section {
                    Button("Apply Filters") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear All") {
                        searchCriteria = SearchCriteria()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Advanced Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Search Criteria

struct SearchCriteria {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var addressContains: String = ""
    var useDateFilter: Bool = false
    var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var dateTo: Date = Date()
    
    var isActive: Bool {
        !name.isEmpty || !email.isEmpty || !phone.isEmpty || !addressContains.isEmpty || useDateFilter
    }
    
    func buildPredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []
        
        if !name.isEmpty {
            let firstNamePredicate = NSPredicate(format: "firstName CONTAINS[cd] %@", name)
            let lastNamePredicate = NSPredicate(format: "lastName CONTAINS[cd] %@", name)
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [firstNamePredicate, lastNamePredicate]))
        }
        
        if !email.isEmpty {
            predicates.append(NSPredicate(format: "email CONTAINS[cd] %@", email))
        }
        
        if !phone.isEmpty {
            predicates.append(NSPredicate(format: "phone CONTAINS %@", phone))
        }
        
        if !addressContains.isEmpty {
            predicates.append(NSPredicate(format: "address CONTAINS[cd] %@", addressContains))
        }
        
        if useDateFilter {
            predicates.append(NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateFrom as NSDate, dateTo as NSDate))
        }
        
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
