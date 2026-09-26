//
//  FilePicker.swift
//  TianTianSign
//
//  UIKit UIDocumentPickerViewController wrapper, like Feather/KSign.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let allowsMultiple: Bool
    let onPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultiple
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: ([URL]) -> Void
        init(onPicked: @escaping ([URL]) -> Void) { self.onPicked = onPicked }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onPicked(urls) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
