//
//  ContentView.swift
//  AIChat
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    
    @StateObject private var history = HistoryService()
    @StateObject private var gemini = GeminiService()
    
    
    @State private var currentPersona: AIPersona = .helpful
    @State private var showPDFPreview = false
    @State private var pdfData: Data? = nil
    @State private var customPrompt: String = ""
    @State private var showPersonaPicker = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var lastInputWasVoice: Bool = false
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var currentTask: Task<Void, Never>? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showAttachmentOptions = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isMenuOpen = false
    @State private var showSettings = false
    @State private var currentConversationID: UUID? = nil
    @FocusState private var isInputFocused: Bool
    @StateObject private var voiceService = VoiceInputService()
    @StateObject private var speechService = SpeechService()
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("aiPersonality") var aiPersonality = "Helpful"
    @Namespace private var bottomID
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // MARK: - Main chat area
            VStack(spacing: 0) {
                
                // MARK: - Header
                HStack {
                    // Menu button
                    Button {
                        isInputFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isMenuOpen.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(currentTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // New chat button
                    HStack(spacing: 16) {
                        
                        // Share button
                        if !messages.isEmpty {
                            Button {
                                shareConversation()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // PDF export button
                            Button {
                                exportAsPDF()
                            } label: {
                                Image(systemName: "doc.richtext")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        
                        // Persona shows current persona emoji
                        Button {
                            showPersonaPicker = true
                        } label: {
                            Text(currentPersona.emoji)
                                .font(.system(size: 22))
                        }
                        
                        // New chat button
                        Button {
                            startNewChat()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                // MARK: - Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            
                            if messages.isEmpty {
                                EmptyStateView { suggestion in
                                    inputText = suggestion
                                    sendMessage()
                                }
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(
                                    message: message,
                                    speechService: speechService
                                )
                            }
                            
                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.vertical, 12)
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    .onChange(of: isLoading) { _ in
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    .onChange(of: keyboardHeight) { _ in
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }
                
                // MARK: - Image preview
                if let image = selectedImage {
                    HStack(alignment: .top, spacing: 10) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Image selected")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Add a message or send as is")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation { selectedImage = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // MARK: - Input bar
                HStack(spacing: 10) {
                    
                    // Attachment button
                    Button {
                        isInputFocused = false
                        showAttachmentOptions = true
                    } label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .confirmationDialog(
                        "Choose image source",
                        isPresented: $showAttachmentOptions
                    ) {
                        Button("Photo Library") { showImagePicker = true }
                        Button("Camera") { showCamera = true }
                        Button("Cancel", role: .cancel) {}
                    }

                    // Voice input button
                    VoiceButton(voiceService: voiceService) { transcribedText in
                        inputText = transcribedText
                        lastInputWasVoice = true
                        sendMessage()
                    }
                    .onAppear {
                        // Sync voice input language with speech output language
                        voiceService.selectedLanguage = speechService.selectedLanguage
                    }
                    .onChange(of: speechService.selectedLanguage) { newLanguage in
                        // When user changes language in settings
                        // update voice input language too
                        voiceService.selectedLanguage = newLanguage
                    }
                    
                    TextField(
                        "Type a message...",
                        text: $inputText,
                        axis: .vertical
                    )
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .onSubmit {
                        if !inputText.isEmpty { sendMessage() }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isInputFocused = false
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if isLoading {
                        Button { stopGeneration() } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        .transition(.scale)
                    } else {
                        Button { sendMessage() } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(
                                    inputText.isEmpty && selectedImage == nil
                                    ? .gray : .blue
                                )
                        }
                        .disabled(inputText.isEmpty && selectedImage == nil)
                        .transition(.scale)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isLoading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: -2)
            }
            // Shift up when keyboard appears
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            // Dim and slide right when menu opens
            .offset(x: isMenuOpen ? 280 : 0)
            .scaleEffect(isMenuOpen ? 0.92 : 1)
            .opacity(isMenuOpen ? 0.4 : 1)
            .allowsHitTesting(!isMenuOpen)
            
            // MARK: - Side menu overlay (tap to close)
            if isMenuOpen {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isMenuOpen = false
                        }
                    }
                    .offset(x: 280)
            }
            
            // MARK: - Side menu
            SideMenuView(
                history: history,
                selectedConversationID: Binding(
                    get: { currentConversationID },
                    set: { id in
                        if let id = id {
                            loadConversation(id: id)
                        }
                    }
                ),
                isMenuOpen: $isMenuOpen,
                onNewChat: { startNewChat() },
                onSettingsTapped: { showSettings = true }
            )
            .frame(width: 280)
            .offset(x: isMenuOpen ? 0 : -280)
            .shadow(
                color: .black.opacity(isMenuOpen ? 0.15 : 0),
                radius: 10,
                x: 5,
                y: 0
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillShowNotification
            )
        ) { notification in
            guard let frame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect else { return }
            let safeBottom = UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?
                .safeAreaInsets.bottom ?? 0
            keyboardHeight = frame.height - safeBottom
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification
            )
        ) { _ in
            keyboardHeight = 0
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(history: history)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPickerView(
                selectedPersona: $currentPersona,
                customPrompt: $customPrompt,
                onSave: {
                    // Update system prompt in gemini service
                    let prompt = currentPersona == .custom
                        ? customPrompt
                        : currentPersona.systemPrompt
                    gemini.updateSystemPrompt(prompt)
                }
            )
        }
        .sheet(isPresented: $showPDFPreview) {
            if let data = pdfData {
                PDFPreviewView(pdfData: data)
            }
        }
    }
    
    // MARK: - Current title
    var currentTitle: String {
        if let id = currentConversationID,
           let conv = history.conversations.first(where: { $0.id == id }) {
            return conv.title
        }
        return messages.isEmpty ? "AI Assistant" : "New chat"
    }
    
    // MARK: - Start new chat
    func startNewChat() {
        stopGeneration()
        speechService.stop()
        messages = []
        inputText = ""
        selectedImage = nil
        currentConversationID = nil
        currentPersona = .helpful
        customPrompt = ""
    }
    
    // MARK: - Load conversation
    func loadConversation(id: UUID) {
        guard let conv = history.conversations.first(
            where: { $0.id == id }
        ) else { return }
        stopGeneration()
        messages = conv.messages.map { $0.toChatMessage() }
        currentConversationID = id
    }
    
  
    // MARK: - Send message
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || selectedImage != nil else { return }
        
        // Cancel any existing task first
        currentTask?.cancel()
        currentTask = nil
        
        // Stop any ongoing speech
        speechService.stop()
        
        isInputFocused = false
        
        // Create conversation if first message
        if currentConversationID == nil {
            let conv = history.createConversation()
            currentConversationID = conv.id
        }
        
        let userMessage = ChatMessage(
            role: .user,
            text: text,
            image: selectedImage
        )
        messages.append(userMessage)
        inputText = ""

        // Capture voice flag then reset it
        let wasVoiceInput = lastInputWasVoice
        lastInputWasVoice = false
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation { selectedImage = nil }
        
        isLoading = true
        
        // Add empty AI message
        let aiMessage = ChatMessage(role: .assistant, text: "")
        messages.append(aiMessage)
        
        // Store message ID instead of index
        // ID never changes even if array shifts
        let aiMessageID = aiMessage.id
        
        currentTask = Task {
            await gemini.sendMessage(
                messages: Array(messages.dropLast()),
                onToken: { token in
                    // Find message by ID — safe even if array changes
                    guard !Task.isCancelled else { return }
                    if let index = messages.firstIndex(
                        where: { $0.id == aiMessageID }
                    ) {
                        messages[index].text += token
                    }
                },
                onComplete: {
                    guard !Task.isCancelled else { return }
                    isLoading = false
                    currentTask = nil
                    
                    // Save to history
                    if let id = currentConversationID {
                        history.updateConversation(
                            id,
                            messages: messages
                        )
                    }
                    
                    // ONLY if user used voice input
                    if wasVoiceInput,
                       let aiMsg = messages.first(
                        where: { $0.id == aiMessageID }
                       ),
                       !aiMsg.text.isEmpty {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 0.5
                        ) {
                            speechService.speak(
                                text: aiMsg.text,
                                messageID: aiMsg.id
                            )
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - Stop generation
    func stopGeneration() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
        if let last = messages.last,
           last.role == .assistant,
           last.text.isEmpty {
            messages.removeLast()
        }
    }
    
    // MARK: - Share conversation
    func shareConversation() {
        var text = "AI Chat Conversation\n"
        text += "========================\n\n"
        
        for message in messages {
            if message.role == .user {
                text += "You:\n\(message.text)\n\n"
            } else {
                text += "AI:\n\(message.text)\n\n"
            }
            text += "------------------------\n\n"
        }
        
        text += "Shared from AIChat App"
        
        shareText = text
        
        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        showShareSheet = true
    }
    
    // MARK: - Export as PDF
    func exportAsPDF() {
        let title = currentConversationID.flatMap { id in
            history.conversations.first { $0.id == id }?.title
        } ?? "AI Conversation"
        
        guard let data = PDFExportService.generatePDF(
            messages: messages,
            title: title
        ) else { return }
        
        pdfData = data
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        showPDFPreview = true
    }
    
    
}

// MARK: - Image picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) { parent.dismiss() }
    }
}

// MARK: - Empty state view
struct EmptyStateView: View {
    let onSuggestionTapped: (String) -> Void
    
    let suggestions = [
        "Explain how AI works in simple terms",
        "Write a short poem about Mumbai",
        "Give me 5 productivity tips",
        "What should I learn after Swift?"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            VStack(spacing: 8) {
                Text("AI Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Ask me anything — I am here to help")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestionTapped(suggestion)
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.circle")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Typing indicator
struct TypingIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(i) * 0.15),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animate = true }
    }
}

// MARK: - Share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

#Preview {
    ContentView()
}
