# WaterWars 🎈💦

A Flutter-based mobile game for water balloon fights! WaterWars is an interactive multiplayer game where players can engage in virtual water balloon battles using QR codes for player identification and real-time gameplay.

## 🎮 Game Overview

WaterWars is a fun, interactive water balloon fight game that combines:
- **QR Code Integration**: Scan QR codes to identify players and start battles
- **Multiplayer Support**: Play with up to 4 players simultaneously
- **Real-time Gameplay**: Track lives, hits, and game progress in real-time
- **Firebase Backend**: Cloud-based data storage and authentication
- **Cross-platform**: Works on iOS, Android, and web

## 🚀 Features

- **Player Management**: Create and manage player profiles with custom names
- **QR Scanner**: Built-in QR code scanner for player identification
- **Life System**: Each player starts with 3 lives
- **Hit Tracking**: Real-time hit detection and life deduction
- **Game Dashboard**: Centralized game management and statistics
- **Firebase Integration**: Cloud Firestore for data persistence
- **Authentication**: Secure player login and registration

## 🛠️ Technology Stack

- **Framework**: Flutter 3.7.0+
- **State Management**: Provider pattern
- **Backend**: Firebase (Firestore, Authentication)
- **QR Scanning**: mobile_scanner package
- **Local Storage**: Shared Preferences
- **UI**: Material Design with Google Fonts
- **Assets**: SVG support for scalable graphics

## 📱 Screenshots

The game includes several key screens:
- **Welcome Screen**: Game introduction and player setup
- **Dashboard Screen**: Main game interface with player management
- **QR Scanner Screen**: Player identification via QR codes

## 🎯 How to Play

1. **Setup**: Launch the app and create your player profile
2. **Scan**: Use the QR scanner to identify other players
3. **Battle**: Engage in water balloon fights with other players
4. **Track**: Monitor lives and hits in real-time
5. **Win**: Be the last player standing!

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd WaterWars/waterwars
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Firestore and Authentication

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── Storage.dart           # Local storage utilities
├── models/
│   └── player.dart        # Player data model
├── screens/
│   ├── welcome_screen.dart    # Welcome/landing screen
│   ├── dashboard_screen.dart  # Main game dashboard
│   └── qr_scanner_screen.dart # QR code scanner
└── state/
    └── game_state.dart    # Game state management
```

## 🎨 Assets

The game includes various assets for enhanced gameplay:
- Player avatars (Player_1.png through Player_4.png)
- UI elements (Heart.png, Hit_button.png, How_to.png)
- Background graphics (Background.png)

## 🔧 Configuration

### Dependencies

Key packages used:
- `shared_preferences`: Local data storage
- `provider`: State management
- `mobile_scanner`: QR code scanning
- `firebase_core`, `cloud_firestore`, `firebase_auth`: Firebase integration
- `google_fonts`: Custom typography
- `flutter_svg`: SVG graphics support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
