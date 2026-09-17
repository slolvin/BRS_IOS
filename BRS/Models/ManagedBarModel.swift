//
//  ManagedBarModel.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import Foundation

struct ManagedBarsResponse: Decodable {
    let status: String
    let bars: [ManagedBar]
}

struct ManagedBar: Decodable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let rate: Double
    let qrSecretHash: String // Тот самый хэш, который мы научили Flask генерировать!
}
