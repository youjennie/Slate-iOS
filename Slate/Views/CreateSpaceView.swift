import SwiftUI

// MARK: - [1] 공간 생성 화면 (CreateSpaceView)
struct CreateSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var spaceManager = SpaceManager.shared
    
    // MARK: - [상태 변수]
    @State private var selectedTag = "Daily"
    @State private var currentMomentText = ""
    @State private var futureSelfText = ""
    
    // ⭐️ 에러 해결 1: 단일 UIImage? 대신 [UIImage] 배열로 변경 (다중 선택 대응)
    @State private var selectedImages: [UIImage] = []
    
    @State private var showPhotoOptions = false
    @State private var showImagePicker = false
    
    // ⭐️ 에러 해결 2: Date? 대신 Date로 변경하여 ImagePicker 규격 일치
    @State private var photoDate: Date = Date()
    
    @State private var isEditingCustomTag = false
    @State private var customTagName = ""
    
    let tags = ["Daily", "Workout", "Project", "Reading", "Study", "Medicine", "Couple", "Baby", "Add Space"]
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // (A) 헤더 영역
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 타이틀 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Your Space")
                            .font(.system(size: 32, weight: .bold))
                        Text("What is this space about?")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    // 태그 그리드 섹션
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(tags, id: \.self) { tag in
                            if tag == "Add Space" {
                                customTagButton
                            } else {
                                TagButton(title: tag, isSelected: selectedTag == tag) {
                                    selectedTag = tag
                                    isEditingCustomTag = false
                                }
                            }
                        }
                    }
                    
                    inputSection
                    photoCaptureSection // ⭐️ 다중 이미지 프리뷰 적용됨
                    createButton
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        // ⭐️ 에러 해결 3: 최신 ImagePicker 규격에 맞춰 인자 전달 (sourceType 제거)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedImages, detectedDate: photoDate)
        }
    }
    
    // MARK: - [내부 서브 로직 뷰]
    
    private var customTagButton: some View {
        Group {
            if isEditingCustomTag {
                TextField("My Space", text: $customTagName, onCommit: {
                    isEditingCustomTag = false
                    if !customTagName.isEmpty { selectedTag = customTagName }
                })
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 10)
                .frame(height: 45)
                .background(RoundedRectangle(cornerRadius: 25).stroke(Color.green, lineWidth: 2))
                .multilineTextAlignment(.center)
            } else {
                Button(action: { isEditingCustomTag = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                        Text(customTagName.isEmpty ? "Name" : customTagName)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(RoundedRectangle(cornerRadius: 25).stroke(selectedTag == customTagName ? Color.green : Color.gray.opacity(0.3)))
                    .foregroundColor(selectedTag == customTagName ? .green : .gray)
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What does your present moment look like? (*)")
                    .font(.system(size: 15, weight: .semibold))
                TextField("At the moment, I'm...", text: $currentMomentText, axis: .vertical)
                    .padding()
                    .frame(minHeight: 80, alignment: .top)
                    .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.3)))
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("What does your next phase look and feel like? (*)")
                    .font(.system(size: 15, weight: .semibold))
                TextField("In the future, I'll...", text: $futureSelfText, axis: .vertical)
                    .padding()
                    .frame(minHeight: 80, alignment: .top)
                    .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.3)))
            }
        }
    }

    private var photoCaptureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capture your starting point")
                .font(.system(size: 16, weight: .semibold))
            Button(action: { showImagePicker = true }) {
                VStack(spacing: 12) {
                    if let firstImage = selectedImages.first {
                        // ⭐️ 다중 선택 시 첫 번째 이미지를 보여주고 뱃지 표시
                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                Group {
                                    if selectedImages.count > 1 {
                                        Text("\(selectedImages.count)")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(5)
                                            .background(Color.black.opacity(0.6))
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                            .padding(8)
                                    }
                                }, alignment: .bottomTrailing
                            )
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera").font(.system(size: 30)).foregroundColor(.gray)
                            Text("This is for you, not for anyone else").font(.system(size: 14)).foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(RoundedRectangle(cornerRadius: 15).stroke(style: StrokeStyle(lineWidth: 1, dash: [5])).foregroundColor(.gray.opacity(0.5)))
            }
        }
    }

    private var createButton: some View {
        Button(action: handleCreateSpace) {
            Text(isFormValid ? "Create New Space" : "Go to Calendar")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(RoundedRectangle(cornerRadius: 15).fill(isFormValid ? Color(red: 186/255, green: 206/255, blue: 156/255) : Color.gray.opacity(0.4)))
        }
        .padding(.vertical, 10)
    }

    private var isFormValid: Bool {
        !currentMomentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !futureSelfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleCreateSpace() {
        if isFormValid {
            let finalTag = customTagName.isEmpty ? selectedTag : customTagName
            spaceManager.addNewSpace(finalTag)
        }
        dismiss()
    }
}

// MARK: - [7] 독립 컴포넌트: 태그 버튼 (TagButton)
struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if isSelected {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                }
            }
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(RoundedRectangle(cornerRadius: 25).stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1))
            .foregroundColor(isSelected ? .green : .gray)
        }
    }
}

// MARK: - [8] 프리뷰
struct CreateSpaceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateSpaceView()
        }
    }
}
