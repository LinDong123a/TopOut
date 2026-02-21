import Foundation

struct CheckInRecord: Identifiable, Codable {
    let id: UUID
    let gymName: String
    let date: Date
    let isHoliday: Bool
    let holidayName: String?
    
    init(gymName: String, date: Date = Date(), isHoliday: Bool = false, holidayName: String? = nil) {
        self.id = UUID()
        self.gymName = gymName
        self.date = date
        self.isHoliday = isHoliday
        self.holidayName = holidayName
    }
}
