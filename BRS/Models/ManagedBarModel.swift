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
    let qrSecretHash: String // Тот самый хэш, который генерирует Flask
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, rate
        case qrSecretHash = "qr_secret_hash"
    }
    
    // 🌟 КАСКАДНАЯ ЗАЩИТА ОТ MISSING DATA / NULL ЗНАЧЕНИЙ В Postgres
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Обязательные ID и имя, которые железно есть в СУБД
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        // 🛡 Защита от мусорных NULL-значений в адресах и городах
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? "Адрес не указан"
        self.city = try container.decodeIfPresent(String.self, forKey: .city) ?? "Самара"
        
        // Защита от отсутствующего рейтинга бара
        self.rate = try container.decodeIfPresent(Double.self, forKey: .rate) ?? 0.0
        
        // 🛡 Самая частая причина падения: у старых баров нет сгенерированного qr_secret_hash в базе
        self.qrSecretHash = try container.decodeIfPresent(String.self, forKey: .qrSecretHash) ?? "no_secret_hash"
    }
}
