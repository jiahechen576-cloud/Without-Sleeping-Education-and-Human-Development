# ReadRabbit — Proposed Solution

## 1. Solution Overview

ReadRabbit is an AI-powered reading companion designed to support people who experience difficulties with reading, including learners with dyslexia. The application combines AI-assisted reading, accessibility customisation, speech technologies, text recognition, and interactive learning activities in one mobile application.

The goal is to make reading more accessible, engaging, and manageable by allowing users to interact with text in different ways instead of relying only on conventional reading.

ReadRabbit is a learning-support tool, not a diagnostic or medical application.

## 2. Proposed Solution Objectives

The main objectives of ReadRabbit are to:

1. **Improve reading accessibility** by offering adjustable text presentation, reading rulers, and text-to-speech support.
2. **Support reading comprehension** through AI-generated stories, simplified explanations, and an interactive Bahasa Melayu assistant.
3. **Provide alternative ways to interact with text** through optical character recognition (OCR) and speech-to-text (STT).
4. **Encourage consistent learning** through interactive activities, word collection, and story history.
5. **Support bilingual learning** by including Bahasa Melayu alongside English-oriented reading experiences.

## 3. Key Features

### 3.1 AI Story Adventure

Users can explore AI-assisted stories designed to make reading more engaging. The reading experience includes read-aloud support and reading assistance features.

**Problem addressed:** Conventional reading materials may feel difficult or unengaging for some learners.

**Expected benefit:** Users can explore stories with additional support and practise reading at their own pace.

### 3.2 Read Aloud and Dyslexia-Friendly Reading

ReadRabbit provides text-to-speech functionality and customisable reading presentation. Supported settings include font size, letter spacing, line spacing, reading ruler, and high-contrast display options.

**Problem addressed:** Dense text and fixed visual layouts may make reading uncomfortable or difficult to follow.

**Expected benefit:** Users can adjust the reading experience to suit their individual preferences.

### 3.3 Scan Text (OCR)

Users can scan printed text using the device camera or select an image for text recognition. Recognised text can then be used in the reading workflow.

**Problem addressed:** Printed material may be difficult to access through a digital reading interface.

**Expected benefit:** Users can convert supported text in images into text that can be read and processed within the application.

### 3.4 Speak & Write (STT)

The speech-to-text feature allows users to express their thoughts verbally and convert speech into written text.

**Problem addressed:** Typing and written expression can be challenging for some learners.

**Expected benefit:** Users have an alternative way to input their ideas.

### 3.5 ReadRabbit Buddy — Bahasa Melayu Assistant

ReadRabbit Buddy is an AI-powered chat assistant that allows users to ask questions about words, sentences, or stories in Bahasa Melayu. It supports follow-up questions and a feature for simplifying explanations.

**Problem addressed:** Learners may encounter unfamiliar vocabulary or struggle to understand explanations written in complex language.

**Expected benefit:** Users can ask questions in Bahasa Melayu and receive contextual explanations that are intended to be easier to understand.

### 3.6 Word Garden

Word Garden provides a way for users to save words and their meanings for later reference.

**Problem addressed:** Learners may forget unfamiliar words or find it difficult to keep track of vocabulary they have encountered.

**Expected benefit:** Users can build a personal collection of words and revisit their meanings during future learning sessions.

### 3.7 Story History

Story History allows users to revisit previously generated or accessed stories.

**Problem addressed:** Users may want to return to earlier reading material rather than start again each time.

**Expected benefit:** Users can continue engaging with previously accessed content.

## 4. Target Users

ReadRabbit is designed primarily for:

- Learners with dyslexia or reading difficulties.
- Students who benefit from additional reading and vocabulary support.
- Bahasa Melayu learners who need help understanding unfamiliar words or sentences.
- Users who prefer listening, speaking, or scanning text instead of relying exclusively on typing and conventional reading.

The application may also be useful to educators and families who want to explore additional ways to support reading practice.

## 5. How the Solution Works

A typical user journey is as follows:

1. The user opens ReadRabbit and selects a feature from the home screen.
2. The user chooses a reading activity, scans printed text, or enters a question.
3. ReadRabbit processes the input using the relevant on-device capability or AI backend.
4. The user receives the available output, such as recognised text, spoken text, a story, or an AI-generated explanation.
5. The user adjusts supported accessibility settings to suit their needs.
6. The user can continue practising, save vocabulary, or revisit reading material through the available features.

This workflow brings multiple reading-support tools together in one application.

## 6. Technology Stack

| Technology | Purpose |
|---|---|
| Flutter and Dart | Mobile application interface and application logic |
| Node.js and Express | Backend server for AI chat requests |
| Groq API | AI response generation through the backend |
| Flutter TTS | Text-to-speech functionality |
| Speech recognition package | Speech-to-text input |
| Google ML Kit Text Recognition | Text extraction from supported images |
| Local application state and storage | Supporting app settings and relevant user features |

The exact storage mechanism depends on the implementation of each feature.

## 7. System Architecture

ReadRabbit uses a mobile application with a separate backend for AI-assisted interactions.

**Mobile application:** The Flutter frontend provides the interface, reading controls, camera and speech interactions, and feature navigation.

**Backend server:** A Node.js and Express server receives chat requests from the mobile application and communicates with the AI service.

**AI service:** The Groq API generates responses used by AI-assisted features such as ReadRabbit Buddy.

**Device capabilities and supporting libraries:** Text-to-speech, speech recognition, and OCR provide additional ways for users to interact with reading content.

The API key is stored in the backend environment rather than embedded directly in the public source code. A deployed version should use a securely hosted backend endpoint instead of relying on an Android emulator's local development address.

## 8. Accessibility Considerations

ReadRabbit aims to offer flexibility rather than assuming every learner has identical needs.

Accessibility-related considerations include:

- Adjustable font size, letter spacing, and line spacing.
- A reading ruler to help users follow text.
- Read-aloud functionality for supported content.
- High-contrast display settings.
- Speech input as an alternative to typing.
- AI explanations intended to make unfamiliar content easier to understand.
- A Bahasa Melayu assistant to support bilingual learning.

These features are intended to provide additional support. Their effectiveness and suitability for individual learners should be evaluated through user testing.

## 9. Expected Impact

ReadRabbit is intended to:

- Make reading support more accessible through a single mobile application.
- Give learners more control over how text is presented and consumed.
- Encourage vocabulary exploration and repeated reading practice.
- Provide additional support for understanding Bahasa Melayu text.
- Reduce reliance on a single method of interacting with written content.

These are expected benefits, not yet proven educational outcomes. Further evaluation with target users, educators, and accessibility specialists would be needed to measure actual improvements in reading confidence, comprehension, and engagement.

## 10. Current Limitations

The current prototype has several limitations:

- AI responses depend on backend availability and the external AI service.
- AI-generated explanations may occasionally be inaccurate and should be checked when necessary.
- OCR and speech recognition accuracy may vary with image quality, pronunciation, background noise, and device conditions.
- Accessibility preferences differ between users, so the available settings may not meet every individual's needs.
- The prototype has undergone functional testing, but broader user testing and formal accessibility evaluation remain necessary.

## 11. Future Improvements

Possible future improvements include:

1. Conduct usability testing with learners with dyslexia and educators.
2. Evaluate the clarity and accuracy of AI-generated explanations in both English and Bahasa Melayu.
3. Improve personalisation based on user preferences and reading progress.
4. Expand language support and provide more flexible reading voices.
5. Add more structured reading exercises and progress reports.
6. Strengthen backend deployment, privacy controls, and production security.
7. Evaluate accessibility against recognised guidelines and feedback from target users.

## 12. Conclusion

ReadRabbit proposes a practical, technology-assisted approach to reading support by combining AI explanations, customisable reading presentation, text-to-speech, OCR, speech-to-text, vocabulary saving, and bilingual assistance.

By bringing these capabilities into one application, ReadRabbit aims to give learners more flexible ways to access text, explore unfamiliar vocabulary, and practise reading. Its next stage should focus on user feedback, accessibility evaluation, and evidence of educational benefit.