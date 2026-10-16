# ReadRabbit 🐰
### An AI-Powered, Dyslexia-Friendly Reading Companion

ReadRabbit is an accessible reading companion designed to support people who experience reading difficulties, particularly people with dyslexia. It combines reading assistance, speech, AI-powered explanations, interactive learning, and customizable reading settings in one mobile application.

Our goal is to make reading more approachable, interactive, and inclusive for users with different reading needs.

> **Project status:** Working Flutter prototype. Core features have been tested on an Android emulator using a release APK.

## 1. Problem Statement

Reading can be challenging for people with dyslexia and others who experience reading difficulties. Dense text, unfamiliar vocabulary, limited reading support, and difficulties expressing ideas in writing can make reading and learning frustrating.

Conventional reading applications may not provide all the tools a learner needs in one place. Users may need to switch between reading tools, dictionaries, text recognition, and speech applications.

ReadRabbit explores how accessible design and AI-assisted learning tools can bring these capabilities together in a single application.

## 2. Target Users

- People with dyslexia and other reading difficulties.
- Students who need support understanding written content.
- Learners who benefit from listening while reading.
- Users who want help understanding unfamiliar words and sentences.
- Bahasa Melayu and English learners who need language support.

ReadRabbit is designed as a supportive learning tool, not a diagnostic or medical application.

## 3. Proposed Solution

ReadRabbit provides a mobile reading environment with customizable text presentation, read-aloud support, AI-generated stories, text recognition, speech-to-text input, vocabulary saving, and an AI assistant.

By combining these features, the prototype aims to help users engage with text in ways that better suit their individual preferences.

## 4. Key Features

### 📖 AI Story Adventure
- Generate stories from a topic.
- Read stories aloud.
- Follow spoken text with word highlighting.
- Use a reading ruler and customizable reading settings.
- Answer comprehension questions and review quiz results.
- Reopen saved stories and continue reading.

### ♿ Dyslexia-Friendly Reading
- Adjustable font size, letter spacing, and line spacing.
- Reading ruler to help track text.
- High-contrast reading mode.
- Text-to-speech support with word highlighting.

### 📷 Scan Text (OCR)
- Capture text using the camera or select an image.
- Extract text using optical character recognition (OCR).
- Open recognized text in the reading interface.

### 🎙️ Speak & Write
- Convert spoken input into text using speech recognition.
- Provide an alternative way to enter ideas without typing everything manually.

### 🌱 Word Garden
- Save unfamiliar words and their meanings.
- Review saved vocabulary.
- Retain saved words between app restarts.

### 🇲🇾 ReadRabbit Buddy
- Ask questions about unfamiliar words and concepts.
- Receive AI-assisted explanations.
- Request simpler explanations and contextual follow-up answers.
- Support Bahasa Melayu and English interactions.

### 📚 Story History
- Reopen saved stories.
- Review reading progress and quiz scores.
- Continue learning from previous sessions.

## 5. Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application framework |
| Dart | Mobile application programming language |
| Node.js | Backend runtime for the AI assistant |
| HTTP API | Communication between the mobile app and backend |
| AI service integration | Story generation and conversational assistance |
| Flutter TTS | Text-to-speech functionality |
| Speech recognition | Spoken input for Speak & Write |
| Google ML Kit Text Recognition | OCR text extraction |
| Android SDK | Android build and testing environment |

The specific AI provider, model, and service configuration should be documented in the backend configuration if applicable.

## 6. Project Structure

The repository contains the Flutter application and its supporting Android project files. The backend is maintained separately in the local development folder `readrabbit_backend`.

```text
hackathon_app/
├── android/
├── assets/
├── lib/
├── test/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

The exact folders and files may vary as the project develops.

## 7. Prerequisites

To run the prototype from source, install:

- Flutter SDK and Dart SDK compatible with the project.
- Android Studio or another supported Android development setup.
- Android SDK and an Android emulator or compatible Android device.
- Node.js and npm for the ReadRabbit Buddy backend.
- Any API credentials required by the configured AI service.

Verify Flutter setup:

```bash
flutter doctor
```

## 8. Installation and Setup

### A. Clone the repository

```bash
git clone https://github.com/jiahechen576-cloud/ReadRabbit.git
cd ReadRabbit
```

### B. Install Flutter dependencies

From the Flutter project root:

```bash
flutter pub get
```

### C. Configure and start the backend

The ReadRabbit Buddy backend is included in the `readrabbit_backend/` directory.

Install Node.js and npm, then open a terminal in the repository root and run:

```bash
cd readrabbit_backend
npm install
```

Create your local environment file from the example:

**Windows PowerShell**
```powershell
Copy-Item .env.example .env
```

Open `readrabbit_backend/.env` and replace the placeholder with your own Groq API key:

```text
GROQ_API_KEY=your_actual_groq_api_key
```

Keep this key private. Never commit `.env` or share the key in screenshots, videos, or public repositories.

Start the backend:

```bash
node server.js
```

The development server listens on port `3000`.

### D. Configure backend connectivity

For the Android emulator, the Flutter app currently uses:

```text
http://10.0.2.2:3000
```

This address allows the emulator to connect to a backend running on the development computer. It is not a public endpoint.

For a physical phone or remote judge, configure a reachable backend endpoint and update the app's backend URL accordingly. Keep the backend and API key secure; do not expose a development server publicly without appropriate security controls.

Keep the backend running while testing ReadRabbit Buddy and other backend-dependent features.


### D. Configure backend connectivity

For the Android emulator, the Flutter app currently uses:

```text
http://10.0.2.2:3000
```

This address allows the Android emulator to reach a backend running on the development computer.

It is not a public server address. For a physical phone or remote judge, configure a reachable backend endpoint and the corresponding app URL. Do not expose a development server publicly without appropriate security controls.

### E. Run the Flutter application

Start an Android emulator or connect a device, then run:

```bash
flutter devices
flutter run
```

Keep the backend running while testing features that require it.

## 9. Building the Android APK

To create a release APK:

```bash
flutter build apk
```

The generated file is normally located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The current prototype has been built and tested using a debug signing configuration. This is suitable for demonstration and sideloading but is not a production Play Store signing setup.

## 10. Prototype Testing

The following areas have been tested on the release build:

- Application launch.
- AI Story Adventure.
- Read Aloud and accessibility controls.
- Story History, saved progress, and quiz results.
- Scan Text (OCR).
- Speak & Write.
- Word Garden.
- ReadRabbit Buddy.

AI responses and backend-dependent functions require a working backend and valid service configuration.

## 11. Expected Impact

ReadRabbit aims to:

- Make digital reading more adaptable to individual needs.
- Support understanding through speech and visual reading aids.
- Help learners explore unfamiliar vocabulary.
- Encourage independent reading and comprehension practice.
- Provide language support in both Bahasa Melayu and English.

These are intended benefits. Their effectiveness for different users would need to be evaluated through user testing and feedback.

## 12. Limitations and Future Improvements

Potential next steps include:

- Testing with users with dyslexia and accessibility specialists.
- Improving compatibility across physical Android devices.
- Deploying a secure, reliable backend for remote demonstrations.
- Expanding language and text-recognition support.
- Improving personalization based on user feedback.
- Preparing production-grade signing and deployment.

## 13. Source Code and Demonstration

- **GitHub repository:** https://github.com/jiahechen576-cloud/ReadRabbit
- **Demonstration video:** Add the publicly accessible three-minute video link before submission.
- **Submission documents:** Add the Problem Statement Analysis and Proposed Solution documents or link them here when finalized.

## 14. Acknowledgements

ReadRabbit was developed as a hackathon prototype exploring accessible reading experiences through mobile technology, AI-assisted learning, and multisensory interaction.
