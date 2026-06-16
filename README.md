# FAHAD (Deepfake Image Verification Application)

FAHAD is an offline, AI-powered mobile application designed to detect AI-generated and manipulated images (deepfakes). By leveraging a locally deployed Vision Transformer (ViT) model converted to TensorFlow Lite (TFLite), FAHAD performs high-accuracy image verification directly on the user's device—requiring zero cloud interaction or internet connectivity.

In an era of rising digital misinformation and cloud privacy vulnerabilities, FAHAD provides a secure, fast, and privacy-preserving shield against visual manipulation.

---

## Key Features

*   **100% Offline Verification:** Analyze images anytime, anywhere—even in zero-connectivity environments. 
*   **Privacy-First Architecture:** No cloud dependencies. Images never leave your device; all processing occurs locally in a sandboxed environment.
*   **AI-Powered Analysis:** Utilizes an optimized Vision Transformer (ViT) to deliver a Credibility Score (%), a clear Classification (Authentic vs. Manipulated), and a detailed breakdown.
*   **Local History Dashboard:** Automatically saves verification history (scores, metrics, and timestamps) locally using SQLite for quick review.
*   **Universal Formats:** Supports standard image formats, including `.jpg`, `.jpeg`, and `.png`.

---

## Tech Stack

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Frontend UI** | Flutter | Cross-platform mobile development (iOS/Android) |
| **Languages** | Dart & Python | Dart for application workflow; Python for model optimization |
| **Core AI Model** | Vision Transformer (ViT) | Advanced deep learning architecture for image classification |
| **Inference Runtime** | TensorFlow Lite (TFLite) | Embedded engine for lightning-fast on-device execution |
| **Local Storage** | SQLite | Light relational database for offline report logging |

---

## System Architecture

FAHAD is built on a linear pipeline designed for minimal latency and maximum data isolation:

```text
[User Interface (Flutter)] 
          │ (Image Upload / Camera Input)
          ▼
[Application Logic] ──► [Image Preprocessing] ──► [ViT Model (TFLite)]
                                                          │
          ┌───────────────────────────────────────────────┘
          ▼
[Verification Results] ──► [SQLite Local Storage]
