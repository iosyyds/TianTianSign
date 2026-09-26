//
//  FilePicker.swift
//  TianTianSign
//  包装 UIDocumentPickerViewController
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    var types: [UTType]
    var onPick: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick([])
        }
    }
}

extension UTType {
    static var ipaFile: UTType {
        UTType(filenameExtension: "ipa", conformingTo: .data) ?? .data
    }
    static var p12File: UTType {
        UTType(filenameExtension: "p12", conformingTo: .data) ?? .data
    }
    static var mobileprovisionFile: UTType {
        UTType(filenameExtension: "mobileprovision", conformingTo: .data) ?? .data
    }
}
