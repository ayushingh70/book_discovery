# Book Discovery

A Flutter app to browse and discover books, search with filters, view details, manage contacts, analyze demo trends with charts, and manage a user profile with Firebase Auth.

> **Note (assignment context):**  
> This repository was created as part of a company assignment. It implements only the features and UI from the recruiter’s Figma and the written task spec in Document. The Figma file cannot be shared for security reasons.

---

## Table of Contents

1. [Screens & Features](#screens--features)  
2. [Tech Stack](#tech-stack)    
3. [State Management](#state-management)  
4. [Firebase Setup](#firebase-setup)  
5. [Google Books API Key](#google-books-api-key)
6. [Screenshots](#screenshots)
7. [Build a Release APK](#build-a-release-apk)   

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

## Firebase Setup

The app uses **Firebase Authentication** and optionally **Realtime Database** for persisting profile changes.

### 1) Create a Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/) → “Add project” → follow the steps.

### 2) Enable Authentication
- In Firebase Console: **Authentication → Get started**
- Enable **Email/Password**  
- Enable **Google Sign-In** if you want Google login (requires SHA-1 for Android).

### 3) Add Your Apps & Download Config Files

#### 🔹 Android
1. Firebase Console → Project settings → **General** → “Your apps” → **Android** → *Add app*.
2. Use your Android app ID (package name):  
   Example: `com.ayush.book_discovery` (check in `android/app/src/main/AndroidManifest.xml`).
3. Download **`google-services.json`** and place/replace it in: android/app/google-service.json
4. Update Gradle:
- In `android/build.gradle` (project-level):
  ```gradle
  dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
  }
  ```
- In `android/app/build.gradle` (module-level), add at the bottom:
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
```rules
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

4. Example stricter rules for per-user docs:
```rules
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

