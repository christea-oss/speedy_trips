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

# SpeedyTrips App

SpeedyTrips is a black & gold themed rideshare mobile application built with Flutter.

The goal is to create a streamlined airport-focused ride experience with zone-based pricing, scheduled rides, and real-time driver/rider connection.

---

## Tech Stack

- Flutter (UI + App Logic)
- Dart (Programming Language)
- Visual Studio Code (Development Environment)
- GitHub (Version Control)
- Base44 (Backend Integration - in progress)

---

## Platforms

- iOS (in progress)
- Android (in progress)
- Web (used for testing/debugging)

---

## Design Theme

- Primary: Black
- Accent: Gold
- Style: Clean, minimal, luxury ride experience

---

## Current Progress (MVP)

### Rider Side (COMPLETE)
- Pickup selection (BHM Airport)
- Zone selection dropdown
- Ride type (Ride Now / Schedule)
- Date & Time picker for scheduled rides
- Live Trip Summary UI
- Navigation to Driver screen
- "My Rides" screen created
- Basic ride history UI structure

### Driver Side (COMPLETE UI)
- Online / Offline toggle
- Incoming ride request UI
- Ride details display:
  - Pickup
  - Zone
  - Ride type
  - Price
- Accept / Decline ride buttons

---

## In Progress

- Connecting Rider → Driver data flow
- Passing real booking data between screens
- Cleaning navigation structure
- UI polish (black & gold consistency)

---

## TODO (Next Development Phase)

### Core Functionality
- [ ] Connect rider booking to driver screen (real data)
- [ ] Add ride status system:
  - Searching
  - Accepted
  - Arrived
  - In Progress
  - Completed

### Driver Flow
- [ ] Add "Arrived" button
- [ ] Add "Start Trip" button
- [ ] Add "Complete Trip" button

### Rider Flow
- [ ] Show driver assigned screen
- [ ] Show live trip tracking UI

### Backend (Base44 Integration)
- [ ] Create booking entity
- [ ] Store ride data
- [ ] Fetch ride history dynamically
- [ ] Sync driver + rider state

---

## Project Structure

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
├── widgets/ (planned)
├── services/ (planned for backend)


---

## How to Run the Project

1. Install Flutter:
https://docs.flutter.dev/get-started/install

2. Clone the repository:
https://github.com/YOUR_USERNAME/speedy_trips.git


3. Navigate into project:
cd speedy_trips


4. Get dependencies:
flutter pub get


5. Run the app:
flutter run


---

## Contributing (Team Instructions)

- Pull latest changes before starting work
- Create a new branch for features:
git checkout -b feature/your-feature-name


- Commit clearly:
git commit -m "Added driver trip status buttons"


- Push your branch:
git push origin feature/your-feature-name


---

## Vision

SpeedyTrips will evolve into a full rideshare platform focused on:

- Airport transportation
- Scheduled rides
- Zone-based pricing
- Clean and reliable UX
- Fast driver matching

---

## Status

Actively in development  
MVP UI completed  
Backend + real-time features coming next

