# MedIntel

## What the app is doing
MedIntel is a cross-platform Flutter mobile app (iOS & Android) that helps users upload prescription images, detects medicines from the image (mocked), shows interaction warnings and recommendations, and lets users find nearby pharmacies and place mock orders. It includes profile, cart and order flows and a polished Material 3 UI.

## Features used
- Firebase: Authentication, Cloud Firestore, Messaging (push notifications)
- Provider: state management (present in pubspec.yaml)
- Image capture & selection: image_picker
- Networking: http for REST requests and mock backends
- Location & maps: geolocator and google_maps_flutter (nearby pharmacy flows)
- Deep links / external actions: url_launcher
- Mock services: `lib/services/mock_data.dart` provides sample data flows

> Note: GraphQL, Hive (local DB) and WebSocket-based chat are not included in the current codebase.

---

Author: tahatahirbutt-dev — https://github.com/tahatahirbutt-dev
