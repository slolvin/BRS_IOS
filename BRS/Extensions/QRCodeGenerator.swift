//
//  QRCodeGenerator.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    private static let context = CIContext()
    private static let filter = CIFilter.qrCodeGenerator()
    
    /// Генерирует нативный QR-код из секретного хэша заведения
    static func generate(from hash: String) -> UIImage {
        let data = Data(hash.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // Устанавливаем высокий уровень коррекции ошибок (H), чтобы код читался даже при бликах
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            // Масштабируем до четких пикселей, чтобы QR не превратился в «мыло»
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        // Возвращаем системную заглушку-ошибку, если генерация сорвалась
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
