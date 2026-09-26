//
//  AppState.swift
//  TianTianSign
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var certificates: [SigningCertificate] = []
    @Published var profiles: [ProvisioningProfile] = []
    @Published var importedIPAs: [IPAFile] = []

    @Published var selectedCertID: UUID?
    @Published var selectedProfileID: UUID?

    var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    lazy var certsDir = documents.appendingPathComponent("Certificates", isDirectory: true)
    lazy var profilesDir = documents.appendingPathComponent("Profiles", isDirectory: true)
    lazy var ipaDir = documents.appendingPathComponent("ImportedIPAs", isDirectory: true)
    lazy var outputDir = documents.appendingPathComponent("SignedOutput", isDirectory: true)

    var selectedCert: SigningCertificate? {
        guard let id = selectedCertID else { return nil }
        return certificates.first { $0.id == id }
    }
    var selectedProfile: ProvisioningProfile? {
        guard let id = selectedProfileID else { return nil }
        return profiles.first { $0.id == id }
    }

    private init() {
        [certsDir, profilesDir, ipaDir, outputDir].forEach {
            try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
        }
        load()
    }

    // MARK: - Persistence (JSON)
    private struct Stored: Codable {
        var certs: [SigningCertificate]
        var profiles: [ProvisioningProfile]
        var selCert: UUID?
        var selProfile: UUID?
    }

    private var stateURL: URL { documents.appendingPathComponent("state.json") }

    func save() {
        let s = Stored(certs: certificates, profiles: profiles, selCert: selectedCertID, selProfile: selectedProfileID)
        if let data = try? JSONEncoder().encode(s) {
            try? data.write(to: stateURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: stateURL),
              let s = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        certificates = s.certs
        profiles = s.profiles
        selectedCertID = s.selCert
        selectedProfileID = s.selProfile
    }

    // MARK: - CRUD
    func addCert(_ c: SigningCertificate) {
        certificates.append(c)
        if selectedCertID == nil { selectedCertID = c.id }
        save()
    }

    func addProfile(_ p: ProvisioningProfile) {
        profiles.append(p)
        if selectedProfileID == nil { selectedProfileID = p.id }
        save()
    }

    func deleteCert(at offsets: IndexSet) {
        for i in offsets {
            try? FileManager.default.removeItem(at: certificates[i].p12URL)
        }
        certificates.remove(atOffsets: offsets)
        save()
    }

    func deleteProfile(at offsets: IndexSet) {
        for i in offsets {
            try? FileManager.default.removeItem(at: profiles[i].fileURL)
        }
        profiles.remove(atOffsets: offsets)
        save()
    }
}
