//
//  AppState.swift
//  TianTianSign
//  Persistent app state.
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var certificates: [SigningCertificate] = []
    @Published var profiles: [ProvisioningProfile] = []
    @Published var library: [IPAFile] = []
    @Published var recentTasks: [SigningTask] = []

    @Published var selectedCertificateID: UUID?
    @Published var selectedProfileID: UUID?

    var selectedCertificate: SigningCertificate? {
        guard let id = selectedCertificateID else { return nil }
        return certificates.first { $0.id == id }
    }
    var selectedProfile: ProvisioningProfile? {
        guard let id = selectedProfileID else { return nil }
        return profiles.first { $0.id == id }
    }

    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    lazy var certsDir = documents.appendingPathComponent("Certificates", isDirectory: true)
    lazy var profilesDir = documents.appendingPathComponent("Profiles", isDirectory: true)
    lazy var libraryDir = documents.appendingPathComponent("IPALibrary", isDirectory: true)
    lazy var outputDir = documents.appendingPathComponent("Output", isDirectory: true)

    private init() {
        [certsDir, profilesDir, libraryDir, outputDir].forEach {
            try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
        }
        load()
    }

    // MARK: - Persistence
    private struct StoredState: Codable {
        var certificates: [SigningCertificate]
        var profiles: [ProvisioningProfile]
        var selectedCertificateID: UUID?
        var selectedProfileID: UUID?
    }

    private var stateURL: URL { documents.appendingPathComponent("state.json") }

    func save() {
        let state = StoredState(
            certificates: certificates,
            profiles: profiles,
            selectedCertificateID: selectedCertificateID,
            selectedProfileID: selectedProfileID
        )
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: stateURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else { return }
        certificates = state.certificates
        profiles = state.profiles
        selectedCertificateID = state.selectedCertificateID
        selectedProfileID = state.selectedProfileID
    }

    // MARK: - Helpers
    func addCertificate(_ cert: SigningCertificate) {
        certificates.append(cert)
        if selectedCertificateID == nil {
            selectedCertificateID = cert.id
        }
        save()
    }

    func addProfile(_ profile: ProvisioningProfile) {
        profiles.append(profile)
        if selectedProfileID == nil {
            selectedProfileID = profile.id
        }
        save()
    }

    func deleteCertificate(at offsets: IndexSet) {
        for index in offsets {
            let cert = certificates[index]
            try? FileManager.default.removeItem(at: cert.p12URL)
        }
        certificates.remove(atOffsets: offsets)
        save()
    }

    func deleteProfile(at offsets: IndexSet) {
        for index in offsets {
            let p = profiles[index]
            try? FileManager.default.removeItem(at: p.fileURL)
        }
        profiles.remove(atOffsets: offsets)
        save()
    }
}
