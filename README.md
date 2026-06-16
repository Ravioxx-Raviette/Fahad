
OVERVIEW

FAHAD (Deepfake Image Verification Application) is an offline, AI-powered mobile application designed to detect AI-generated and manipulated images (deepfakes). The application uses a locally deployed Vision Transformer (ViT) model converted to TensorFlow Lite (TFLite) to perform image verification directly on the user's device without requiring an internet connection.

The system aims to address the growing problem of digital misinformation and privacy concerns associated with cloud-based verification tools by providing a secure, fast, and privacy-preserving solution.

OBJECTIVES
- Detect AI-generated and manipulated images offline.
- Protect user privacy by processing all images locally.
- Generate credibility scores and detailed verification reports.
- Store verification history locally for future reference.
- Provide an accessible verification tool even in low-connectivity environments.
  
FEATURES
- Offline Image Verification
- Upload and verify images without an internet connection.
- Support:
JPG (.jpg)
JPEG (.jpeg)
PNG (.png)

<img width="235" height="447" alt="result3" src="https://github.com/user-attachments/assets/81d32587-9629-4230-8cde-2b0c9a4283d8" />
<img width="254" height="499" alt="mainscreen" src="https://github.com/user-attachments/assets/6ad3358e-bea1-4ec4-8fa6-1dc312c64230" />
<img width="268" height="503" alt="result1" src="https://github.com/user-attachments/assets/560ef902-10ef-4256-bdb5-c19f640c0263" />
<img width="257" height="503" alt="result2" src="https://github.com/user-attachments/assets/5de0aace-1c27-4c3b-88a3-5d8c0f1a14bd" />

AI-POWERED DETECTION
- Utilizes a Vision Transformer (ViT) model.
- Performs on-device inference using TensorFlow Lite.
- Generates:
  Credibility Score (%)
  Classification Result (Authentic / Manipulated)
  Detailed Verification Report

DISPLAYS:
- Credibility score
- Classification result
- Verification date and time
- Metadata information (if available)
- AI analysis summary
  
VERIFICATION HISTORY:
- Stores previous verification results locally using SQLite.
- Allows users to review past reports through an interactive dashboard.
  
PRIVACY-FIRST ARCHITECTURE:
- Fully offline operation.
- No image uploads to external servers.
- No cloud dependency.
- All data remains on the user's device.
  
SYSTEM ARCHITECTURE:
- User Interface (Flutter) -> Application Logic -> Image Preprocessing -> Vision Transformer (TensorFlow Lite) -> Verification Result Generation -> SQLite Local Database

TECH STACK
- Frontend:	Flutter
- Programming Language:	Dart/Python
- Machine Learning Model:	Vision Transformer (ViT)
- AI Inference Engine:	TensorFlow Lite
- Local Database:	SQLite
- Development Environment:	Visual Studio Code / Android Studio
- Version Control:	Git & GitHub
