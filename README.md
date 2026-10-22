# TripMate – Smart Travel Planner

TripMate is a smart travel planner built with Flutter and Firebase for **CS310 Mobile Application Development** at Sabancı University. Users plan multi-city trips together in travel groups, compare transport options between cities, log shared expenses and see who owes whom, and discover food places and activities sorted by distance to their hotel.

## Group 39

| Member | Student ID |
|---|---|
| Ada Derviş Sarabil | 34362 |
| Naz Zağlı | 33968 |
| Ata Balcı | 32218 |
| Emre Tutal | 34004 |
| Arda Koçulu | 34367 |

## Core Features

1. **User authentication** – sign up, log in and log out with email and password (Firebase Authentication).
2. **Multi-city trip planning** – add several cities, set dates per city, reorder the route and build a day-by-day itinerary.
3. **Transport between cities** – add bus, train or flight options for each leg with price and duration; the app highlights the cheapest option and the total route cost.
4. **Travel groups** – create a group for a trip and invite friends by username or invite code.
5. **Shared expenses and settle-up** – log who paid, how much and for whom; the app calculates who owes whom after the trip.
6. **Food place logging** – log restaurants and cafés with a rating, a short note and a location.
7. **Nearby recommendations** – food places and activities sorted by distance to the group's hotel.
8. **Persistent storage** – trip, group and log data is saved to the cloud and synced between group members.

### Optional Features (if time permits)

- Live transport prices from an external API
- Community feed with activities and food logs from other users in the same city
- City events listing (concerts, festivals)
- Map view of the route, hotel and recommended places
- Weather forecast per city and trip reminders

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Provider
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Location data:** Google Places API

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or Xcode with an emulator / simulator
- A Firebase project (config files are not committed to this repository)

### Setup

```bash
git clone https://github.com/adasarabil/TripMate.git
cd TripMate
flutter pub get
flutter run
```

Firebase configuration files (`google-services.json`, `GoogleService-Info.plist` and `lib/firebase_options.dart`) are listed in `.gitignore` and are not committed. Each member generates them locally once the Firebase project is set up:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

The Google Places API key goes in a local `.env` file, which is also ignored.

## Team Workflow

- `main` always holds a working version of the app.
- Each feature is developed on its own branch (e.g. `feature/expenses`) and merged through a pull request.
- At least one other member reviews a pull request before it is merged.
- Commit messages are short and describe what changed (e.g. `Add login form validation`).

## Course Information

- **Course:** CS310 Mobile Application Development, Sabancı University
- **Term:** Fall 2026
