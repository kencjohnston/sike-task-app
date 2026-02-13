# Backend Integration Plan (Firebase)

This plan outlines the steps to integrate Firebase (Authentication and Firestore) into the Flutter Task App to enable data synchronization across devices.

## 1. Project Setup & Configuration

- [ ] **Create Firebase Project**: Set up a new project in the Firebase Console.
- [ ] **Register Apps**: Register Android and iOS apps in the Firebase project.
    -   Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
- [ ] **Add Dependencies**:
    -   `firebase_core`
    -   `firebase_auth`
    -   `cloud_firestore`
    -   `provider` (already exists, but ensure compatibility)
- [ ] **Configure Native Files**:
    -   Android: Update `build.gradle` files.
    -   iOS: Update `Podfile` and `AppDelegate.swift`.
- [ ] **Initialize Firebase**: Update `main.dart` to initialize Firebase before running the app.

## 2. Data Model Updates (Serialization)

Update existing models to support JSON serialization for Firestore.

- [ ] **Task Model**: Add `toMap()` and `fromMap()` methods.
    -   Handle `DateTime` <-> `Timestamp` conversion.
    -   Handle `Enum` <-> `String` conversion.
- [ ] **RecurrenceRule Model**: Add `toMap()` and `fromMap()`.
- [ ] **Enums**: Ensure all enums (`TaskType`, `RequiredResource`, etc.) have consistent string representations.

## 3. Authentication Service

Implement user authentication to secure data.

- [ ] **Create `AuthService`**:
    -   Methods: `signInAnonymously()`, `signInWithEmailAndPassword()`, `signUp()`, `signOut()`.
    -   Stream: `authStateChanges` to listen for login status.
- [ ] **UI Implementation**:
    -   Create `LoginScreen` / `SignUpScreen`.
    -   Add "Profile" or "Settings" section to manage account (link anonymous account to email).

## 4. Firestore Service & Data Migration

Implement the core data logic.

- [ ] **Create `FirestoreService`**:
    -   Collection Reference: `users/{userId}/tasks`.
    -   Methods: `getTasksStream()`, `addTask()`, `updateTask()`, `deleteTask()`.
- [ ] **Migration Logic (Hive to Firestore)**:
    -   Create a one-time migration function.
    -   On first authenticated launch:
        1.  Check if Hive has data.
        2.  Check if Firestore is empty for this user.
        3.  Upload all Hive tasks to Firestore.
        4.  Mark migration as complete (preference flag).
        5.  (Optional) Clear Hive or keep as backup.

## 5. State Management Updates

Update `TaskProvider` to use Firestore.

- [ ] **Refactor `TaskProvider`**:
    -   Inject `FirestoreService` and `AuthService`.
    -   Switch from `Hive.box` to `FirestoreService.getTasksStream()`.
    -   Update CRUD methods to call `FirestoreService`.
    -   Handle loading states and error states.

## 6. Security Rules

Secure the database.

- [ ] **Configure Firestore Rules**:
    ```
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        match /users/{userId}/tasks/{taskId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
    ```

## 7. Testing & Validation

- [ ] **Unit Tests**: Test serialization logic.
- [ ] **Integration Tests**: Test Auth flow and CRUD operations with Firestore emulator (optional but recommended).
- [ ] **Manual Testing**:
    -   Verify offline support (Firestore handles this automatically).
    -   Verify sync between two devices (simulator + physical device).
