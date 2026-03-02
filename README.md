# Alray App - Real Estate Budget Management

Alray is a modern, feature-rich real estate budget management application built with Flutter and Firebase. It allows users to track project budgets, manage expenses, record revenues, and handle team contacts seamlessly.

## 🚀 Key Features

* **Secure Authentication**: User login and sign-up powered by Firebase Authentication with proper routing and state persistence.
* **Projects Dashboard**: 
  * Create, view, and manage multiple real estate projects.
  * Define project budgets and track remaining balances.
  * View high-level summaries including all-time expenses, monthly returns, and yearly returns.
* **Detailed Transaction Tracking**: Add categorised expenses and revenues to specific projects.
* **Team Contacts Management**: 
  * Add and manage team members and contractors.
  * Direct dialing support right within the app.
  * Track team-related calls and interactions.
* **Modern UI/UX**: 
  * Premium, glassmorphism-inspired design system.
  * Smooth animations using `flutter_animate`.
  * Proper Indian Currency formatting (₹ Lakhs and Crores).
* **Cloud Sync**: Real-time data storage and synchronization using Firebase Cloud Firestore.

## 🛠️ Tech Stack & Architecture

* **Framework**: Flutter (Dart)
* **State Management**: `provider` (MultiProvider with `ChangeNotifierProxyProvider`)
* **Navigation**: `go_router` (Stateful nested routing with Authentication guards)
* **Backend**: Firebase (Authentication, Cloud Firestore)
* **Environments**: Configured with Dev and Prod Android flavors using separate Firebase environments (`alray-dev` / `alray-prod`).

## 📁 Project Structure highlights
* `lib/models/`: Data classes for `Project`, `Expense`, `Revenue`, `Contact`.
* `lib/providers/`: State managers (`AuthProvider`, `BudgetProvider`, `ContactsProvider`).
* `lib/screens/`: App screens including `DashboardScreen`, `LoginScreen`, `ProjectDetailsScreen`, etc.
* `lib/routes/`: Centralized GoRouter configuration handling auth redirects.
* `lib/services/`: Background & external integrations (`CallService`).

## ⚙️ Running and Building the App

The application uses Android Flavors to separate Development and Production environments.

### Development

**Run:**
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

**Build APK:**
```bash
flutter build apk --flavor dev -t lib/main_dev.dart
```

### Production

**Run:**
```bash
flutter run --flavor prod -t lib/main_prod.dart
```

**Build APK:**
```bash
flutter build apk --flavor prod -t lib/main_prod.dart
```

**Note:** The generated `.apk` files will be output to your `build/app/outputs/flutter-apk/` directory automatically.
