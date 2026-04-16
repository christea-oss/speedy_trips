# speedy_trips

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 🚗 SpeedyTrips

SpeedyTrips is a black & gold themed rideshare mobile application built with Flutter.

The app is designed to provide a streamlined airport transportation experience using:
- Zone-based flat pricing
- Scheduled and on-demand rides
- Real-time rider ↔ driver connection

Initial launch focus: **Birmingham Airport (BHM)**

---

## 🧱 Tech Stack

### Frontend (Mobile App)
- Flutter
- Dart

### Development Tools
- Visual Studio Code
- Android Studio (Emulator & SDK)
- Git + GitHub

### Backend (Planned)
- Firebase (Firestore + Authentication + Real-time updates)

### Prototype Source
- Base44 (used only for early UI/logic reference — NOT part of production backend)

---

## 📱 Platforms

- iOS (in progress)
- Android (in progress)
- Web (for testing/debugging only)

---

## 🎨 Design System

- Primary Color: Black
- Accent Color: Gold
- UX Style: Clean, minimal, premium ride experience

---

## ✅ Current Progress (MVP)

### Rider Side (Completed)
- Pickup location fixed to BHM Airport
- Zone selection system
- Dynamic pricing by zone
- Ride type selection:
  - Ride Now
  - Scheduled Ride
- Date & time picker for scheduled rides
- Live trip summary
- Ride confirmation flow
- "My Rides" (ride history UI)
- Navigation between screens

---

### Driver Side (Completed UI)
- Online / Offline toggle
- Incoming ride request UI
- Ride details display:
  - Pickup
  - Zone
  - Ride type
  - Price
- Accept / Decline functionality

---

## 🔄 In Progress

- Connecting Rider → Driver data flow
- Passing real ride data between screens
- Navigation cleanup and structure
- UI polish (consistent black & gold styling)

---

## 🚧 Next Development Phase

### Core System
- [ ] Connect rider booking to driver screen (real data model)
- [ ] Implement full ride status lifecycle:
  - Searching
  - Accepted
  - Arrived
  - In Progress
  - Completed

---

### Driver Flow
- [ ] Add "Arrived at Pickup"
- [ ] Add "Start Trip"
- [ ] Add "Complete Trip"

---

### Rider Flow
- [ ] Driver assigned screen
- [ ] Live ride tracking UI
- [ ] Real-time ride updates

---

### Backend (Firebase Integration)
- [ ] Create booking collection (Firestore)
- [ ] Store ride data
- [ ] Fetch ride history dynamically
- [ ] Sync rider ↔ driver state
- [ ] Implement real-time updates
- [ ] Add authentication (rider / driver roles)

---

## 📂 Project Structure

lib/
│
├── main.dart
│
├── screens/
│ ├── rider/
│ │ ├── rider_home.dart
│ │ ├── my_rides.dart
│ │
│ ├── driver/
│ │ ├── driver_home.dart
│
├── widgets/ (planned reusable UI components)
├── services/ (Firebase + backend logic)
├── state/ (shared app state)


---

## ▶️ Running the Project

### 1. Clone repository
git clone https://github.com/christea-oss/speedy_trips.git


### 2. Open in VS Code

### 3. Install dependencies
flutter pub get


### 4. Run app
flutter run


---

## 🤝 Team Workflow

### Branching
Never work directly on `main`

Create a branch:
git checkout -b feature/your-feature-name

Push your branch:
git push origin feature/your-feature-name


---

### Contribution Areas

#### Frontend (Flutter)
- Rider UI improvements
- Driver UI improvements
- Navigation + UX

#### Backend (Firebase)
- Firestore structure
- Real-time updates
- Ride synchronization

#### UI/UX
- Black & gold styling
- Layout polish
- User flow improvements

#### Testing
- Rider flow testing
- Driver flow testing
- Edge case validation

---

## 🎯 Vision

SpeedyTrips is being built into a scalable rideshare platform focused on:

- Airport transportation
- Scheduled rides
- Zone-based pricing
- Fast and reliable UX
- Real-time driver matching

---

## ⚡ Status

🚧 Active Development  
🔥 MVP UI Completed  
🚀 Backend + Real-Time System Next Phase