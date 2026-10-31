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

struct ManagedBar: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let rate: Double
    let qrSecretHash: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, rate
        case qrSecretHash = "qr_secret_hash"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? "Адрес не указан"
        self.city = try container.decodeIfPresent(String.self, forKey: .city) ?? "Самара"
        
        self.rate = try container.decodeIfPresent(Double.self, forKey: .rate) ?? 0.0
        
        self.qrSecretHash = try container.decodeIfPresent(String.self, forKey: .qrSecretHash) ?? "no_secret_hash"
    }
}
