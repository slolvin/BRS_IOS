//
//  QRScannerCameraView.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import SwiftUI

struct QRScannerCameraView: UIViewControllerRepresentable {
    var onCodeFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        QRScannerViewController(onCodeFound: onCodeFound)
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}
