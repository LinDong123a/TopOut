import Foundation
import SwiftUI

final class CheckInStore: ObservableObject {
    @Published var records: [CheckInRecord] = []
    
    /// Last check-in key for dedup: "gymName|yyyy-MM-dd"
    @AppStorage("lastCheckInKey") private var lastCheckInKey: String = ""
    
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("checkin_records.json")
    }()
    
    init() { load() }
    
    // MARK: - Public API
    
    var streakDays: Int {
        let cal = Calendar.current
        let uniqueDays = Set(records.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard let first = uniqueDays.first else { return 0 }
        var check = cal.startOfDay(for: Date())
        // Allow today or yesterday as start
        if first < cal.date(byAdding: .day, value: -1, to: check)! { return 0 }
        var streak = 0
        for d in uniqueDays {
            if d == check {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else if d < check { break }
        }
        return max(streak, 1)
    }
    
    var uniqueGymCount: Int {
        Set(records.map(\.gymName)).count
    }
    
    func hasCheckedInToday(gymName: String) -> Bool {
        let cal = Calendar.current
        return records.contains { $0.gymName == gymName && cal.isDateInToday($0.date) }
    }
    
    func totalCheckIns(gymName: String) -> Int {
        records.filter { $0.gymName == gymName }.count
    }
    
    func checkIn(gymName: String) {
        let holiday = HolidayDetector.current
        let record = CheckInRecord(
            gymName: gymName,
            isHoliday: holiday != nil,
            holidayName: holiday?.name
        )
        records.insert(record, at: 0)
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        lastCheckInKey = "\(gymName)|\(fmt.string(from: Date()))"
        
        save()
    }
    
    func shouldShowAlert(gymName: String) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let key = "\(gymName)|\(fmt.string(from: Date()))"
        return lastCheckInKey != key
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: fileURL)
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CheckInRecord].self, from: data) else { return }
        records = decoded
    }
}
