import SwiftUI

struct DoctorsView: View {
    @StateObject private var vm = DoctorsViewModel()
    @State private var search = ""
    @State private var showingAdd = false
    @State private var editingDoctor: Doctor?

    var body: some View {
        List {
            ForEach(filtered) { d in
                NavigationLink {
                    DoctorDetailView(doctor: d)
                } label: {
                    DoctorRow(doctor: d)
                }
                .swipeActions {
                    Button {
                        editingDoctor = d
                    } label: { Label("Edit", systemImage: "pencil") }
                    .tint(.blue)

                    Button(role: .destructive) {
                        if let idx = vm.items.firstIndex(where: { $0.id == d.id }) {
                            Task { await vm.delete(at: IndexSet(integer: idx)) }
                        }
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .overlay {
            if vm.loading { ProgressView() }
            else if let e = vm.error {
                Text(e).foregroundColor(.red).padding()
            } else if vm.items.isEmpty {
                ContentUnavailableView("No doctors yet",
                                       systemImage: "stethoscope",
                                       description: Text("Tap + to add your doctor’s contact."))
            }
        }
        .searchable(text: $search)
        .navigationTitle("Doctors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus") } }
            ToolbarItem(placement: .topBarTrailing) { Button { Task { await vm.load() } } label: { Image(systemName: "arrow.clockwise") } }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingAdd) {
            AddEditDoctorView { input in
                Task {
                    do { try await vm.add(input) }
                    catch { vm.error = error.localizedDescription }
                }
            }
        }
        .sheet(item: $editingDoctor) { existing in
            AddEditDoctorView(existing: existing) { input in
                Task {
                    if let id = existing.id {
                        do { try await vm.update(id, with: input) }
                        catch { vm.error = error.localizedDescription }
                    }
                }
            }
        }
    }

    private var filtered: [Doctor] {
        guard !search.isEmpty else { return vm.items }
        let q = search.lowercased()
        return vm.items.filter {
            $0.fullName.lowercased().contains(q) ||
            $0.specialty.lowercased().contains(q) ||
            ($0.clinicName?.lowercased().contains(q) ?? false)
        }
    }
}

struct DoctorRow: View {
    let doctor: Doctor
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "stethoscope")
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green))
            VStack(alignment: .leading, spacing: 2) {
                Text(doctor.fullName).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(doctor.specialty).foregroundColor(.gray)
                    if let clinic = doctor.clinicName, !clinic.isEmpty {
                        Text("·").foregroundColor(.gray)
                        Text(clinic).foregroundColor(.gray)
                    }
                }
                .font(.caption)
            }
            Spacer()
            if let phone = doctor.phone, !phone.isEmpty {
                Image(systemName: "phone.fill").foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

struct DoctorDetailView: View {
    let doctor: Doctor
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Doctor") {
                LabeledContent("Name", value: doctor.fullName)
                LabeledContent("Specialty", value: doctor.specialty)
                if let clinic = doctor.clinicName { LabeledContent("Clinic", value: clinic) }
            }
            Section("Contact") {
                if let phone = doctor.phone, !phone.isEmpty {
                    Button { openURL(URL(string: "tel://\(phone.filter { $0.isNumber })")!) } label: {
                        Label(phone, systemImage: "phone.fill")
                    }
                }
                if let email = doctor.email, !email.isEmpty {
                    Button { openURL(URL(string: "mailto:\(email)")!) } label: {
                        Label(email, systemImage: "envelope.fill")
                    }
                }
                if let addr = doctor.address, !addr.isEmpty {
                    Button {
                        let q = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL(URL(string: "http://maps.apple.com/?q=\(q)")!)
                    } label: {
                        Label(addr, systemImage: "mappin.and.ellipse")
                    }
                    .lineLimit(2)
                }
            }
        }
        .navigationTitle("Doctor")
    }
}
