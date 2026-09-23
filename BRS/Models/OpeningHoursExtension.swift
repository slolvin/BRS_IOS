//
//  OpeningHoursExtension.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI

extension OpeningHours {
    
    // Главное вычисляемое свойство: открыт ли прямо сейчас
    var isOpenNow: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Получаем текущий день недели и день, который был вчера (для ночных смен)
        let currentDayOfWeek = getDayKey(for: now)
        let yesterday = now.addingTimeInterval(-86400)
        let yesterdayDayOfWeek = getDayKey(for: yesterday)
        
        // Текущее время в минутах от начала суток (например, 14:30 -> 14*60 + 30 = 870)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        // 2. Проверка А: Открыты ли мы по расписанию СЕГОДНЯШНЕГО дня?
        if checkTimeInterval(timeString: timeString(for: currentDayOfWeek), currentMinutes: currentMinutes, isMidnightCheck: false) {
            return true
        }
        
        // 3. Проверка Б: Открыты ли мы ещё по расписанию ВЧЕРАШНЕГО дня (ночная смена ушла за полночь)?
        if checkTimeInterval(timeString: timeString(for: yesterdayDayOfWeek), currentMinutes: currentMinutes, isMidnightCheck: true) {
            return true
        }
        
        return false
    }
    
    // Хелпер: извлекает строку времени для конкретного дня
    private func timeString(for dayKey: String) -> String {
        switch dayKey {
        case "Mon": return mon
        case "Tue": return tue
        case "Wed": return wed
        case "Thu": return thu
        case "Fri": return fri
        case "Sat": return sat
        case "Sun": return sun
        default: return "12:00-02:00"
        }
    }
    
    // Хелпер: переводит дату в строковый ключ дня недели
    private func getDayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE" // Вернет Mon, Tue, Wed...
        return formatter.string(from: date)
    }
    
    // Сердце алгоритма: парсит строку "12:00-02:00" и проверяет вхождение минут
    private func checkTimeInterval(timeString: String, currentMinutes: Int, isMidnightCheck: Bool) -> Bool {
        let components = timeString.components(separatedBy: "-")
        guard components.count == 2 else { return false }
        
        // Разбираем часы и минуты старта/финиша
        let startParts = components[0].components(separatedBy: ":")
        let endParts = components[1].components(separatedBy: ":")
        guard startParts.count == 2, endParts.count == 2 else { return false }
        
        let startMin = (Int(startParts[0]) ?? 0) * 60 + (Int(startParts[1]) ?? 0)
        var endMin = (Int(endParts[0]) ?? 0) * 60 + (Int(endParts[1]) ?? 0)
        
        if endMin < startMin {
            // Если время закрытия меньше времени открытия, значит бар закрывается на следующий день (например 02:00)
            if !isMidnightCheck {
                // Если проверяем сегодня: интервал идет от startMin до конца суток (24:00)
                return currentMinutes >= startMin
            } else {
                // If вчерашняя ночная смена: интервал идет от 00:00 до endMin сегодняшнего дня
                return currentMinutes <= endMin
            }
        } else {
            // Обычная дневная смена (например 12:00 - 23:00)
            if isMidnightCheck { return false } // Вчерашний день не мог уйти за полночь
            return currentMinutes >= startMin && currentMinutes <= endMin
        }
    }
}
