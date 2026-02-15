import Foundation
import SwiftData

/// Slate 진행 상태를 실시간 계산하는 서비스
/// - totalDays: 사진을 1장 이상 기록한 고유 날짜 수
/// - currentStreak: 오늘 기준 연속 기록 일수
/// - longestStreak: 역대 최장 연속 기록 일수
/// - progressPercent: (totalDays / goalDays) × 100
struct SlateProgress {
    let totalDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let progressPercent: Double
    
    /// 기본 목표: 100일
    static let defaultGoalDays = 100
}

final class ProgressCalculator {
    
    /// PhotoRecord 배열로부터 진행 상태 계산
    /// - Parameters:
    ///   - records: 삭제되지 않은 PhotoRecord 배열
    ///   - goalDays: 목표 일수 (기본 100일)
    /// - Returns: SlateProgress
    static func calculate(from records: [PhotoRecord], goalDays: Int = SlateProgress.defaultGoalDays) -> SlateProgress {
        let calendar = Calendar.current
        
        // 1. 고유 기록 날짜 추출 (isDeleted == false인 것만)
        let activeRecords = records.filter { !$0.isDeleted }
        let uniqueDays = Set(activeRecords.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted()
        
        let totalDays = sortedDays.count
        
        // 2. 현재 연속 기록 (Streak) 계산 — 오늘부터 역순으로
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today
        
        // 오늘 기록이 있으면 오늘부터, 없으면 어제부터 체크
        if uniqueDays.contains(today) {
            currentStreak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        } else {
            // 오늘 아직 기록 안 했으면, 어제까지 연속인지 체크
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
            if !uniqueDays.contains(checkDate) {
                // 어제도 없으면 streak 0
                return SlateProgress(
                    totalDays: totalDays,
                    currentStreak: 0,
                    longestStreak: calculateLongestStreak(sortedDays: sortedDays, calendar: calendar),
                    progressPercent: min(100.0, Double(totalDays) / Double(goalDays) * 100.0)
                )
            }
            currentStreak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        while uniqueDays.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        // 3. 최장 연속 기록
        let longestStreak = calculateLongestStreak(sortedDays: sortedDays, calendar: calendar)
        
        // 4. Progress %
        let progressPercent = min(100.0, Double(totalDays) / Double(goalDays) * 100.0)
        
        return SlateProgress(
            totalDays: totalDays,
            currentStreak: currentStreak,
            longestStreak: max(longestStreak, currentStreak),
            progressPercent: progressPercent
        )
    }
    
    private static func calculateLongestStreak(sortedDays: [Date], calendar: Calendar) -> Int {
        guard sortedDays.count > 1 else { return sortedDays.count }
        
        var longest = 1
        var current = 1
        
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        
        return longest
    }
}
