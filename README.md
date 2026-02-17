Project Overview
This project is a Flutter chat application that uses Firebase for backend functionality. It allows users to sign up, log in, and chat with each other in real time. The app is meant for learning and development purposes (Group 5 project).

🎯 Features
✔ User Sign Up & Login
✔ Firebase Authentication (Email/Password)
✔ Real-Time Messaging with Firestore
✔ User Profiles
✔ Message Time Stamps
✔ Works on Android, iOS, Web
🛠️ Technologies Used
Flutter (Dart)
Firebase Authentication
Cloud Firestore
Firebase Storage (optional)
Flutter packages (state management, UI enhancements)

📦 Prerequisites
Make sure you have:
✔ Flutter installed
✔ Firebase project created
✔ Android Studio / VS Code setup

📁 Installation & Setup
1. Clone the repository
git clone https://github.com/joelpaulo033/chat_app.git

3. Setup Firebase
Go to the Firebase Console

Create a new project
Add Android & iOS apps
Download:
google-services.json → place in android/app/

GoogleService-Info.plist → place in ios/Runner/
Enable:

Authentication
Cloud Firestore
Firebase Storage (if using image upload)

▶️ Run the App
Connect a device/emulator and run:
Copy code
Bash
flutter run

lib/
 ├── models/
 ├── screens/
 ├── services/
 ├── widgets/
 └── main.dart

Author
Group 5 — Chat App Developers
GitHub: https://github.com/joelpaulo033�
