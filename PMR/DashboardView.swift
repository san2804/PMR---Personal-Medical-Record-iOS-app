import SwiftUI

struct DashboardView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RecordsView()
                .tabItem {
                    Label("Records", systemImage: "doc.text.fill")
                }

            ShareView()
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.blue)
    }
}

// MARK: - Home Dashboard
struct HomeDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with logo
                    HStack(spacing: 12) {
                        Image("PMRLogo") // Your logo in Assets
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Back,")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Sandil 👋")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Quick Summary
                    HStack(spacing: 16) {
                        SummaryCard(icon: "heart.fill", title: "Health Score", value: "82")
                        SummaryCard(icon: "doc.text.fill", title: "Records", value: "12")
                    }
                    .padding(.horizontal)

                    // Dashboard Sections
                    Text("Quick Access")
                        .font(.headline)
                        .padding(.horizontal)
                        .foregroundColor(.black)

                    VStack(spacing: 16) {
                        DashboardCard(
                            title: "Medical Records",
                            subtitle: "View, upload, and organize your files",
                            icon: "folder.fill",
                            color: Color.blue.opacity(0.9)
                        )
                        DashboardCard(
                            title: "Doctors",
                            subtitle: "Your connected healthcare professionals",
                            icon: "stethoscope",
                            color: Color.green.opacity(0.8)
                        )
                        DashboardCard(
                            title: "Appointments",
                            subtitle: "Upcoming consultations & reminders",
                            icon: "calendar.badge.clock",
                            color: Color.orange.opacity(0.8)
                        )
                        DashboardCard(
                            title: "Medications",
                            subtitle: "Track your prescriptions & schedules",
                            icon: "pills.fill",
                            color: Color.purple.opacity(0.8)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.white)
        }
    }
}

// MARK: - Cards
struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(12)
                .background(Circle().fill(Color.blue))
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(color))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemNam
