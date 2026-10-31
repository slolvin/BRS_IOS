//
//  OpeningHoursExtension.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI

extension OpeningHours {
    
    var isOpenNow: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let currentDayOfWeek = getDayKey(for: now)
        let yesterday = now.addingTimeInterval(-86400)
        let yesterdayDayOfWeek = getDayKey(for: yesterday)
        
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        if checkTimeInterval(timeString: timeString(for: currentDayOfWeek), currentMinutes: currentMinutes, isMidnightCheck: false) {
            return true
        }
        
        if checkTimeInterval(timeString: timeString(for: yesterdayDayOfWeek), currentMinutes: currentMinutes, isMidnightCheck: true) {
            return true
        }
        
        return false
    }
    
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
    
    private func getDayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func checkTimeInterval(timeString: String, currentMinutes: Int, isMidnightCheck: Bool) -> Bool {
        let components = timeString.components(separatedBy: "-")
        guard components.count == 2 else { return false }
        
        let startParts = components[0].components(separatedBy: ":")
        let endParts = components[1].components(separatedBy: ":")
        guard startParts.count == 2, endParts.count == 2 else { return false }
        
        let startMin = (Int(startParts[0]) ?? 0) * 60 + (Int(startParts[1]) ?? 0)
        var endMin = (Int(endParts[0]) ?? 0) * 60 + (Int(endParts[1]) ?? 0)
        
        if endMin < startMin {
            if !isMidnightCheck {
                return currentMinutes >= startMin
            } else {
                return currentMinutes <= endMin
            }
        } else {
            if isMidnightCheck { return false }
            return currentMinutes >= startMin && currentMinutes <= endMin
        }
    }
}
