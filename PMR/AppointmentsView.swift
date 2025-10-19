//
//  AppointmentsView.swift
//  PMR
//
//  Created by Sandil on 2025-10-19.
//


//
//  AppointmentsView.swift
//  PMR
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AppointmentsView: View {
    @StateObject private var vm = AppointmentsVM()
    @State private var showEditor = false
    @State private var editTarget: Appointment?

    var body: some View {
        List {
            Section("Upcoming") {
                ForEach(vm.filtered.filter { $0.startAt >= Date() }) { a in
                    AppointmentRow(appt: a)
                        .contentShape(Rectangle())
                        .onTapGesture { editTarget = a; showEditor = true }
                }
                .onDelete { idx in Task { await vm.delete(at: idx) } }
            }

            Section("Past") {
                ForEach(vm.filtered.filter { $0.startAt < Date() }) { a in
                    AppointmentRow(appt: a)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay { if vm.loading { ProgressView() } }
        .searchable(text: $vm.query)
        .navigationTitle("Appointments")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editTarget = nil; showEditor = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await vm.load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            Notifications.requestPermissionIfNeeded()
            await vm.load()
        }
        .sheet(isPresented: $showEditor) {
            AppointmentEditor(existing: editTarget) { result in
                switch result {
                case .create(let a): Task { await vm.add(a) }
                case .update(let id, let patch): Task { await vm.update(id, patch: patch) }
                }
            }
        }
    }
}

struct AppointmentRow: View {
    let appt: Appointment
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(.blue))
            VStack(alignment: .leading, spacing: 2) {
                Text(appt.title).font(.subheadline.weight(.semibold))
                if let p = appt.provider, !p.isEmpty {
                    Text(p).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(appt.startAt, style: .date).font(.caption)
                Text(appt.startAt, style: .time).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editor

enum ApptEditResult {
    case create(Appointment)
    case update(id: String, patch: [String: Any])
}

struct AppointmentEditor: View {
    let existing: Appointment?
    var onFinish: (ApptEditResult) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var provider = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var startAt = Date().addingTimeInterval(3600)
    @State private var endAt: Date? = nil
    @State private var isAllDay = false
    @State private var remindMinutesBefore: Int? = 60
    
    typealias Timestamp = FirebaseFirestore.Timestamp

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Provider", text: $provider)
                    TextField("Location", text: $location)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Time") {
                    Toggle("All-day", isOn: $isAllDay)
                    DatePicker("Start",
                               selection: $startAt,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])

                    if !isAllDay {
                        let endBinding = Binding<Date>(
                                                get: { endAt ?? startAt.addingTimeInterval(3600) },
                                                set: { endAt = $0 }
                                            )
                        DatePicker("End",
                                   selection: Binding(get: {
                                        endAt ?? startAt.addingTimeInterval(3600)
                                   }, set: { endAt = $0 }),
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Reminder") {
                    Picker("Alert", selection: Binding(
                        get: { remindMinutesBefore ?? -1 },
                        set: { remindMinutesBefore = ($0 == -1 ? nil : $0) }
                    )) {
                        Text("None").tag(-1)
                        Text("5 minutes before").tag(5)
                        Text("10 minutes before").tag(10)
                        Text("30 minutes before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("2 hours before").tag(120)
                        Text("1 day before").tag(1440)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Appointment" : "Edit Appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") {
                        if let existing, let id = existing.id {
                            // UPDATE payload (Firestore Timestamps added in VM)
                            var patch: [String: Any] = [
                                "title": title,
                                "provider": provider,
                                "location": location,
                                "notes": notes,
                                "startAt": Timestamp(date: startAt),
                                "isAllDay": isAllDay
                            ]
                            patch["endAt"] = endAt.map { Timestamp(date: $0) } as Any
                            patch["remindMinutesBefore"] = remindMinutesBefore as Any
                            onFinish(.update(id: id, patch: patch))
                        } else {
                            // CREATE new object (timestamps added by VM)
                            let uid = Auth.auth().currentUser?.uid ?? ""
                            let a = Appointment(
                                id: nil,
                                userId: uid,
                                title: title.trimmingCharacters(in: .whitespaces),
                                provider: provider.isEmpty ? nil : provider,
                                location: location.isEmpty ? nil : location,
                                notes: notes.isEmpty ? nil : notes,
                                startAt: startAt,
                                endAt: endAt,
                                isAllDay: isAllDay,
                                remindMinutesBefore: remindMinutesBefore,
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                            onFinish(.create(a))
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = existing {
                    title = e.title
                    provider = e.provider ?? ""
                    location = e.location ?? ""
                    notes = e.notes ?? ""
                    startAt = e.startAt
                    endAt = e.endAt
                    isAllDay = e.isAllDay
                    remindMinutesBefore = e.remindMinutesBefore
                }
            }
        }
    }
}
