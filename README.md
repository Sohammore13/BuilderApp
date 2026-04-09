# BuilderPro

**BuilderPro** is a comprehensive Flutter-based construction company management application. It streamlines site operations, material procurement, and progress tracking through an intuitive, role-based architecture.

## 🏗️ Overview

Managing construction sites involves multiple stakeholders, from engineers on the ground to procurement teams and company owners. BuilderPro centralizes this workflow, offering tailored dashboards, permission-based access, and real-time synchronization through Firebase.

## 👥 Role-Based Access

The application features four distinct user roles, each with specialized capabilities:

1. **Owner**
   - Read-only access to all active construction sites.
   - Ultimate approval authority for material requests and purchase orders.
   - Comprehensive overview of all company operations and requests.

2. **Manager**
   - Full control over site management (create, view, and delete project sites).
   - Read-only tracking of material requests submitted for sites under their management.

3. **Site Engineer**
   - Ability to generate material requirements directly from the site by uploading requirement images.
   - Can monitor the status of their requests (Pending Quotation -> Pending Approval -> Approved/Rejected).

4. **Purchase Team**
   - Reviews requests submitted by Site Engineers.
   - Uploads PDF quotations and adds relevant notes for required materials.
   - Forwards quotations to the Owner for final approval.

## ✨ Key Features

- **End-to-End Material Request Flow:** Seamless progression from *Site Requirement* ➔ *Quotation Upload* ➔ *Final Approval*.
- **Firebase Integration:** Powered by Firebase Authentication for secure access and Cloud Firestore for real-time data sync.
- **PDF Viewer Support:** Built-in PDF loading allowing project owners and teams to inspect formal quotations directly within the app.
- **Modern UI/UX:** Built on Material Design 3, featuring a customized color scheme (defined in `constants.dart`), responsive card layouts, and branded typography.
- **Dynamic Routing:** A smart `AuthWrapper` continuously listens to Firebase auth state, automatically redirecting users to their proper dashboard upon login based on their role.

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (^3.11.1)
- **State Management & Backend:** Firebase Core, Firebase Auth, Cloud Firestore
- **Networking:** HTTP
- **Assets & Media:** Image Picker, File Picker, URL Launcher
- **Styling:** Google Fonts, Cupertino Icons

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
- An active Firebase project with Authentication and Firestore configured.

### Setup

1. **Clone the repository.**
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase:**
   Make sure you have your corresponding Firebase credentials set up (e.g., `google-services.json` for Android, `GoogleService-Info.plist` for iOS). This project utilizes the `firebase_options.dart` generated via FlutterFire CLI.
4. **Run the app:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── models/           # Data classes mapping to Firestore documents
├── screens/          # UI pages grouped by role (auth, owner, manager, site_engineer, purchase_team)
├── services/         # Business logic (e.g., AuthService, FirestoreService)
├── widgets/          # Reusable UI components
├── constants.dart    # Theme configurations, colors, fonts, and role constants
├── firebase_options.dart # Firebase configuration
└── main.dart         # Entry point and routing (AuthWrapper)
```

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
