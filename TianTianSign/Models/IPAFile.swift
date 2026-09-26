//
//  IPAFile.swift
//  TianTianSign
//

import Foundation

struct IPAFile: Identifiable, Hashable {
    let id: UUID
    var fileName: String
    var fileURL: URL
    var appName: String
    var bundleID: String
    var sizeBytes: Int64

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}
