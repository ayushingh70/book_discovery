# Book Discovery

A Flutter app to browse and discover books, search with filters, view details, manage contacts, analyze demo trends with charts, and manage a user profile with Firebase Auth.

> **Note (assignment context):**  
> This repository was created as part of a company assignment. It implements only the features and UI from the recruiter’s Figma and the written task spec. The Figma file cannot be shared for security reasons.

---

## Table of Contents

1. [Screens & Features](#screens--features)  
2. [Tech Stack](#tech-stack)  
3. [Architecture](#architecture)  
4. [State Management](#state-management)  
5. [Project Setup](#project-setup)  
6. [Firebase Setup](#firebase-setup)  
7. [Google Books API Key](#google-books-api-key)  
8. [Build a Release APK](#build-a-release-apk)  
9. [Screenshots](#screenshots)  
10. [Assumptions & Limitations](#assumptions--limitations)

---

## Screens & Features

- **Onboarding**: swipeable intro with CTA to Sign Up / Log In  
- **Auth**: email/password (Google supported if enabled)  
- **Home (Courses/Books)**: search bar, discovery, filters (categories + price), list/grid view, details  
- **Search**: search with chips history, reusable filter bottom sheet, list/grid results  
- **Contacts**: reads device contacts (permission-gated), bottom sheet actions (call, SMS, email)  
- **Profile**: show name, email, avatar; change local avatar (gallery), edit name, manage Google account, logout  
- **Analytics**: **demo** charts (donut/pie, line, bar) using `fl_chart` with a floating card design

---

## Tech Stack

- **Framework:** Flutter (Dart)
- **Charts:** `fl_chart`
- **State:** Riverpod (`flutter_riverpod`)
- **Auth:** Firebase Authentication
- **Profile persistence:** Firebase Realtime Database
- **Permissions:** `permission_handler`
- **Images:** `image_picker`
- **Device info:** `package_info_plus`
- **URL intents:** `url_launcher`

---

## State Management

- **Riverpod** for state & DI:
  - `StateNotifierProvider` for favorites(Removed), etc. 
  - `Provider`/`ConsumerWidget`/`ConsumerStatefulWidget` patterns in UI
- **Why Riverpod?** Simple, testable, no global singletons, compile-time safety.

---

## Project Setup

### 1) Clone the repo
git clone https://github.com/ayushingh70/book_discovery.git
cd book_discovery
flutter pub get
flutter run
