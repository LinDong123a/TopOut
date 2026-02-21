import Foundation

struct HolidayInfo {
    let name: String
    let emoji: String
    /// SF Symbol for decoration
    let symbol: String
}

enum HolidayDetector {
    /// Returns current holiday if date falls in a known range, nil otherwise
    static var current: HolidayInfo? {
        detect(Date())
    }
    
    static func detect(_ date: Date) -> HolidayInfo? {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let md = month * 100 + day // e.g. 214 for Feb 14
        
        switch md {
        // 春节 roughly Jan 20 – Feb 15
        case 120...215:
            return HolidayInfo(name: "春节", emoji: "🧧", symbol: "lantern.fill")
        // 元宵节 ~Feb 15 (overlaps end of spring festival, keep separate check)
        // Already covered above; we treat 元宵 as part of spring festival range
        
        // 情人节
        case 214:
            return HolidayInfo(name: "情人节", emoji: "💕", symbol: "heart.fill")
            
        // 国际攀岩日 (Aug 8 – International Climbing Day varies, use Aug)
        case 808:
            return HolidayInfo(name: "国际攀岩日", emoji: "🧗", symbol: "figure.climbing")
        
        // 万圣节 Oct 25-31
        case 1025...1031:
            return HolidayInfo(name: "万圣节", emoji: "🎃", symbol: "moon.stars.fill")
            
        // 圣诞节 Dec 20-25
        case 1220...1225:
            return HolidayInfo(name: "圣诞节", emoji: "🎄", symbol: "snowflake")
            
        default:
            return nil
        }
    }
}
