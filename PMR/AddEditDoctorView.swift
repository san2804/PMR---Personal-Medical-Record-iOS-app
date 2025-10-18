import SwiftUI

struct AddEditDoctorView: View {
    var existing: Doctor? = nil
    var onSave: (DoctorInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = DoctorInput()

    init(existing: Doctor? = nil, onSave: @escaping (DoctorInput) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _input = State(initialValue: DoctorInput(
            fullName: existing?.fullName ?? "",
            specialty: existing?.specialty ?? "",
            clinicName: existing?.clinicName,
            phone: existing?.phone,
            email: existing?.email,
            address: existing?.address
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic info") {
                    TextField("Full name", text: $input.fullName)
                    TextField("Specialty (e.g., Cardiologist)", text: $input.specialty)
                    TextField("Clinic/Hospital", text: optBinding(\.clinicName))
                }
                Section("Contact") {
                    TextField("Phone", text: optBinding(\.phone))
                        .keyboardType(.phonePad)
                    TextField("Email", text: optBinding(\.email))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Address", text: optBinding(\.address))
                }
            }
            .navigationTitle(existing == nil ? "Add Doctor" : "Edit Doctor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(input); dismiss() }.disabled(!input.isValid)
                }
            }
        }
    }

    private func optBinding(_ keyPath: WritableKeyPath<DoctorInput, String?>) -> Binding<String> {
        Binding(
            get: { input[keyPath: keyPath] ?? "" },
            set: { input[keyPath: keyPath] = $0 }
        )
    }
}
