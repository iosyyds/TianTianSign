//
//  FilePicker.swift
//  TianTianSign
//  Exact copy of Feather's FileImporterRepresentableView.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    var allowedContentTypes: [UTType]
    var allowsMultipleSelection: Bool = false
    var onDocumentsPicked: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onDocumentsPicked: ([URL]) -> Void
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDocumentsPicked([])
        }
    }
}

extension UTType {
    static var ipa: UTType {
        UTType(filenameExtension: "ipa", conformingTo: .data) ?? .data
    }
    static var p12: UTType {
        UTType(filenameExtension: "p12", conformingTo: .data) ?? .data
    }
    static var mobileProvision: UTType {
        UTType(filenameExtension: "mobileprovision", conformingTo: .data) ?? .data
    }
}
