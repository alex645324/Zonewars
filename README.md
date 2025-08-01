
# WaterWars

A personal, built-for-fun multiplayer water balloon fight game.  
We got **30 players** into real games before campus RAs shut it down — still proud of how real it felt.

## Problem

Real-world group play is hard to organize, track, and score without stealing attention. Water balloon fights are chaotic and disappear too fast.

## What It Does

- Lets people “battle” in virtual water balloon fights with real-time scoring.
- Uses **QR codes** to identify players quickly.
- Tracks lives/hits and keeps game state synced across devices via Firebase.
- Supports up to 4 simultaneous players per match.
- Persists game data and sessions in Firestore so you can replay or analyze.

## How to Play

1. Launch the app and create your player profile.
2. Scan other players’ QR codes to add them to the match.
3. Start the battle — lives and hits update live.
4. Last player standing wins.

## Quick Setup (for someone who wants to revive it)

### Requirements
- Flutter SDK (3.7+)
- Firebase project with Firestore & Authentication enabled
- Android Studio / VS Code

### Steps
```bash
git clone <your-repo>
cd waterwars
flutter pub get
