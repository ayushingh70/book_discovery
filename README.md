# Book Discovery

A beautifully crafted Flutter app for browsing and discovering books, searching with filters, viewing details, managing contacts, analyzing trends with charts, and handling user profiles via Firebase Auth.

> **Note (Assignment Context):**  
> This repository was created as part of a company assignment. It strictly implements features and UI based on the recruiter’s Figma and written task spec. The Figma file is confidential and cannot be shared.

---

## Table of Contents

1. [Screens & Features](#screens--features)  
2. [Tech Stack](#tech-stack)    
3. [State Management](#state-management)  
4. [Firebase Setup](#firebase-setup)  
5. [Google Books API Key](#google-books-api-key)
6. [Screenshots](#screenshots)
7. [Download APK](#download-apk)

---

## Screens & Features

- **Onboarding**: Swipeable intro with CTA to Sign Up / Log In  
- **Authentication**: Email/password login (Google Sign-In optional)  
- **Home (Courses/Books)**: Search bar, discovery, filters (category + price), list/grid view, book details  
- **Search**: Chip-based history, reusable filter bottom sheet, list/grid results  
- **Contacts**: Reads device contacts (permission-gated), bottom sheet actions (call, SMS, email)  
- **Profile**: Display name, email, avatar; change avatar (gallery), edit name, manage Google account, logout  
- **Analytics**: Demo charts (donut/pie, line, bar) using `fl_chart` with floating card UI

---

## Tech Stack

| Category         | Tools & Packages                     |
|------------------|--------------------------------------|
| Framework        | Flutter (Dart)                       |
| Charts           | `fl_chart`                           |
| State Management | Riverpod (`flutter_riverpod`)        |
| Auth             | Firebase Authentication              |
| Persistence      | Firebase Realtime Database           |
| Permissions      | `permission_handler`                 |
| Image Picker     | `image_picker`                       |
| Device Info      | `package_info_plus`                  |
| URL Intents      | `url_launcher`                       |
| APIs             | `Google Book APIs`                   |
---

## State Management

- **Riverpod** for state and dependency injection:
  - `StateNotifierProvider` for features like favorites (removed in current version)
  - `Provider`, `ConsumerWidget`, and `ConsumerStatefulWidget` patterns in UI

**Why Riverpod?**  
 Simple - Testable - No global singletons - Compile-time safety

---

## Firebase Setup

The app uses **Firebase Authentication** and optionally **Realtime Database** for profile persistence.

### 1. Create a Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/) → “Add project” → follow setup steps.

### 2. Enable Authentication
- Firebase Console → **Authentication → Get started**
- Enable **Email/Password**
- Enable **Google Sign-In** (requires SHA-1 for Android)

### 3. Add Your Apps & Download Config Files

#### 📱 Android
1. Firebase Console → Project settings → **General** → “Your apps” → **Android** → *Add app*
2. Use your Android app ID (e.g., `com.ayush.book_discovery`)
3. Download `google-services.json` → place in `android/app/`
4. Update Gradle files:

**Project-level `build.gradle`:**
```gradle
dependencies {
  classpath 'com.google.gms:google-services:4.4.2'
}
```
**App-level `build.gradle`:**
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```

#### 🔹 iOS
1. Firebase Console → Project settings → **General** → “Your apps” → **iOS** → *Add app*.
2. Use your iOS **Bundle Identifier** (Xcode → Runner target → *General* → *Identity*).
3. Download **`GoogleService-Info.plist`** and place/replace it in: ios/Runner/GoogleService-Info.plist
4. In Xcode, ensure the file is added to the Runner target.

### 4) Generate `firebase_options.dart`
We use the **FlutterFire CLI** to generate strongly-typed Firebase configs.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates or updates: lib/firebase_options.dart
Replace the existing file in the repo with this generated one (so it points to your Firebase project).

### 5) (Optional) Realtime Database

1. In Firebase Console → Build → Realtime Database → Create Database.
2. Start in test mode (recommended for local dev; secure later).
3. Example dev rules:
```Json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

4. Example stricter rules for per-user docs:
```Json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```
---

## Google Books API Key Setup

The app fetches book data using the **Google Books API**.  
You need your own API key to run the app without quota issues.

### 1) Get an API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or select an existing one).
3. From the left menu → **APIs & Services → Enabled APIs & services**.
4. Click **+ ENABLE APIS AND SERVICES** → search for **Books API** → Enable it.
5. Go to **APIs & Services → Credentials**.
6. Click **+ CREATE CREDENTIALS → API key**.
7. Copy the generated API key.

### 2) Add the Key in Code
The API key is used in `lib/core/books/books_repository.dart`.

Find this line:
```dart
const _apiKey = "YOUR_API_KEY_HERE"; // Replace it with your actual Key
```

### 3) Not related with Google Book API but still change
The supportive things is used in `lib/feature/profile/presentation/profile_screen.dart`.
```dart
path: 'aniketom70@gmail.com', // Change to your own support email
```
```dart
final uri = Uri.parse('https://example.com/privacy'); // Change to your privacy policy link
```

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/77122706-a9ce-4832-8bb7-f0b455da6d8c" alt="Onboarding" width="47%"/>
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/798c7c2d-8878-4f1f-8069-613d50508ca5" alt="Main" width="47%"/>
</p>

## 📱 Download APK

You can download the latest release APK here:  
[Download BookDisc.apk](https://github.com/ayushingh70/book_discovery/releases/tag/v1.0.0)

