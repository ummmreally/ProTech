//
//  CustomerNotesView.swift
//  ProTech
//
//  Add and manage customer notes with timestamps
//

import SwiftUI
import CoreData

struct CustomerNotesView: View {
    @ObservedObject var customer: Customer
    @State private var newNote: String = ""
    @State private var notes: [CustomerNote] = []
    @FocusState private var isNoteFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Customer Notes")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(notes.count) note\(notes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Notes list
            if notes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No notes yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Add notes to track interactions and important information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notes) { note in
                            NoteCard(note: note, onDelete: {
                                deleteNote(note)
                            })
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            // Add note input
            HStack(alignment: .top, spacing: 12) {
                TextEditor(text: $newNote)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .focused($isNoteFieldFocused)
                    .overlay(alignment: .topLeading) {
                        if newNote.isEmpty {
                            Text("Add a note...")
                                .foregroundColor(.secondary)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
                
                Button {
                    addNote()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadNotes()
        }
    }
    
    private func loadNotes() {
        // Parse notes from customer.notes JSON string
        guard let notesData = customer.notes?.data(using: .utf8) else {
            notes = []
            return
        }
        
        if let decoded = try? JSONDecoder().decode([CustomerNote].self, from: notesData) {
            notes = decoded.sorted { $0.timestamp > $1.timestamp }
        } else {
            notes = []
        }
    }
    
    private func addNote() {
        let trimmedNote = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }
        
        let note = CustomerNote(
            id: UUID(),
            text: trimmedNote,
            timestamp: Date()
        )
        
        notes.insert(note, at: 0)
        saveNotes()
        newNote = ""
        isNoteFieldFocused = false
    }
    
    private func deleteNote(_ note: CustomerNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            customer.notes = String(data: encoded, encoding: .utf8)
            customer.updatedAt = Date()
            CoreDataManager.shared.save()
        }
    }
}

// MARK: - Customer Note Model

struct CustomerNote: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
}

// MARK: - Note Card

struct NoteCard: View {
    let note: CustomerNote
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.timestamp, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            Text(note.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .confirmationDialog("Delete this note?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
