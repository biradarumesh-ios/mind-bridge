# AIChat — AI Assistant iOS App

AIChat is a powerful AI-powered chat application for iOS built using SwiftUI. The app supports real-time AI streaming, voice conversations, image analysis, multilingual speech, and persistent chat history — all inside a modern native iOS experience.

---

## Features

### Core Features

- Real-time streaming AI responses
- Multi-turn conversation memory
- Local chat history persistence
- Side menu with previous conversations
- New chat and clear chat support
- Dark mode support

### AI Capabilities

- AI chat using Nvidia Nemotron model via OpenRouter
- Image analysis using Vision AI
- Markdown rendering support
- Context-aware conversations

### Voice Features

- Voice input with speech recognition
- Auto silence detection
- Automatic AI voice playback
- Multilingual text-to-speech
- Support for:
  - English
  - Hindi
  - Marathi
  - Tamil
  - Telugu
  - French
  - Spanish
  - German
  - Japanese
  - Arabic

### User Experience

- Streaming typing animation
- Copy messages with long press
- Haptic feedback
- Keyboard dismissal button
- Stop AI generation button
- Suggested prompts
- Swipe to delete chats
- Auto scrolling chat

---

## Settings

- Dark mode toggle
- AI personality selection
- Voice language picker
- User profile customization
- Chat statistics
- Clear history support

---

## Tech Stack

- Swift
- SwiftUI
- MVVM Architecture
- URLSession
- AVFoundation
- Speech Framework
- Vision Framework
- UserDefaults

---

## AI Services

- OpenRouter API
- Nvidia Nemotron Vision Model
- Apple Neural Text-to-Speech
- Apple Speech Recognition

---

## Architecture

The project follows MVVM architecture:

- View → UI rendering
- ViewModel → business logic
- Service Layer → API communication
- Managers → speech, audio, persistence handling

---

## Future Improvements

- Firebase sync
- User authentication
- Cloud chat backup
- iPad optimization
- Offline AI caching

## Screenshots

### Home Screen

![Home](Screenshots/home.png)

### Chat Screen

![Chat](Screenshots/chat.png)

### Voice Mode

![Voice](Screenshots/voice.png)

### Settings

![Settings](Screenshots/settings.png)
