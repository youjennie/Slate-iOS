import SwiftUI

struct MonthSummaryView: View {
    let month: Date
    let records: [PhotoRecord]
    let category: String
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    let slateWhite = Color(red: 183/255, green: 194/255, blue:198/255)
    
    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: month)?.count ?? 30
    }
    
    var recordedDaysCount: Int {
        let uniqueDays = Set(records.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var body: some View {
        VStack(spacing: 0) { // 메인 간격 0으로 정밀 조정
            // (A) 로고 및 월 타이틀 섹션
            VStack(alignment: .leading, spacing: -60) {
                Image("name_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                    .padding(.leading, -27)
                
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 54, weight: .black))
                    .foregroundColor(Color(white: 0.3))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
            .padding(.bottom, 20)

            Text("\(SpaceManager.shared.userName.isEmpty ? "My" : SpaceManager.shared.userName) Slate Moments")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .padding(.leading, 5) // 월 이름과 정렬을 맞추기 위한 미세 조정
                    .offset(y: 20)
                    .padding(.bottom,20)
            
            // (B) 5열 그리드 이미지 요약
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    if let date = Calendar.current.date(byAdding: .day, value: day-1, to: month) {
                        let record = records.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                        SummaryCell(day: day, image: record?.imageData != nil ? UIImage(data: record!.imageData!) : nil)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 40)

            // (C) 하단 데이터 정보 & 프로그레스 바 뭉치
            VStack(spacing: 15) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text("\(recordedDaysCount)")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(Color(white: 0.5))

                    Text("/\(daysInMonth) Days with Slate")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                
                // 커스텀 프로그레스 바
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(Color(slateWhite))
                            .frame(width: geo.size.width * CGFloat(recordedDaysCount) / CGFloat(daysInMonth), height: 12)
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 60)
        }
        .frame(width: 400)
        .background(Color.white)
    }
}

// 요약 카드용 작은 셀 (수정 없음)
struct SummaryCell: View {
    let day: Int
    let image: UIImage?
    
    var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.05))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().fill(Color.gray.opacity(0.2)).frame(width: 4, height: 4))
            }
            
            Text("\(day)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(image == nil ? .gray.opacity(0.5) : .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(6)
        }
    }
}

// MARK: - [Preview] MonthSummaryView
#Preview {
    // 프리뷰를 위한 샘플 기록 생성
    let today = Date()
    let calendar = Calendar.current
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
    
    // 1일, 3일, 5일에 기록이 있는 것처럼 더미 생성
    let sampleRecords = [
        PhotoRecord(date: monthStart, memo: "Day 1", spaceTag: "Daily"),
        PhotoRecord(date: calendar.date(byAdding: .day, value: 2, to: monthStart)!, memo: "Day 3", spaceTag: "Daily"),
        PhotoRecord(date: calendar.date(byAdding: .day, value: 4, to: monthStart)!, memo: "Day 5", spaceTag: "Daily")
    ]
    
    return MonthSummaryView(
        month: monthStart,
        records: sampleRecords,
        category: "Daily"
    )
    .background(Color.gray.opacity(0.1)) // 배경 구분을 위해 살짝 색상 추가
}
