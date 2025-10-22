// MedicationEditor.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum MedicationEditResult {
    case create(Medication)
    case update(id: String, patch: [String: Any])
}

struct MedicationEditor: View {
    let existing: Medication?
    var onFinish: (MedicationEditResult) -> Void
    @Environment(\.dismiss) private var dismiss

    // form state
    @State private var name = ""
    @State private var strength = ""
    @State private var form = ""
    @State private var route = ""
    @State private var frequency = ""
    @State private var instructions = ""
    @State private var startDate = Date()
    @State private var endDate: Date? = nil
    @State private var prescribedBy = ""
    @State private var notes = ""

    typealias Timestamp = FirebaseFirestore.Timestamp

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Strength (e.g. 500 mg)", text: $strength)
                    TextField("Form (tablet, syrup…)", text: $form)
                    TextField("Route (oral, topical…)", text: $route)
                    TextField("Frequency (e.g. 1-0-1)", text: $frequency)
                    TextField("Instructions", text: $instructions, axis: .vertical)
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    Toggle("Has end date", isOn: Binding(
                        get: { endDate != nil },
                        set: { endDate = $0 ? Date() : nil }
                    ))
                    if endDate != nil {
                        DatePicker("End", selection: Binding(get: {
                            endDate ?? Date()
                        }, set: {
                            endDate = $0
                        }), displayedComponents: [.date])
                    }
                }

                Section("Prescriber / Notes") {
                    TextField("Prescriber", text: $prescribedBy)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(existing == nil ? "Add Medication" : "Edit Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let m = existing {
                    name = m.name
                    strength = m.strength ?? ""
                    form = m.form ?? ""
                    route = m.route ?? ""
                    frequency = m.frequency ?? ""
                    instructions = m.instructions ?? ""
                    startDate = m.startDate
                    endDate = m.endDate
                    prescribedBy = m.prescribedBy ?? ""
                    notes = m.notes ?? ""
                }
            }
        }
    }

    private func save() {
        if let m = existing, let id = m.id {
            var patch: [String: Any] = [
                "name": name.trimmingCharacters(in: .whitespaces),
                "strength": strength as Any,
                "form": form as Any,
                "route": route as Any,
                "frequency": frequency as Any,
                "instructions": instructions as Any,
                "startDate": Timestamp(date: startDate),
                "endDate": endDate.map { Timestamp(date: $0) } as Any,
                "prescribedBy": prescribedBy as Any,
                "notes": notes as Any
            ]
            onFinish(.update(id: id, patch: patch))
        } else {
            let uid = Auth.auth().currentUser?.uid ?? ""
            let med = Medication(
                id: nil,
                userId: uid,
                name: name.trimmingCharacters(in: .whitespaces),
                strength: strength.isEmpty ? nil : strength,
                form: form.isEmpty ? nil : form,
                route: route.isEmpty ? nil : route,
                frequency: frequency.isEmpty ? nil : frequency,
                instructions: instructions.isEmpty ? nil : instructions,
                startDate: startDate,
                endDate: endDate,
                prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy,
                notes: notes.isEmpty ? nil : notes,
                createdAt: Date(),
                updatedAt: Date()
            )
            onFinish(.create(med))
        }
        dismiss()
    }
}
