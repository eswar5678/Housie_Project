# Housie Multiplayer 🎮

A real-time, interactive, and premium multiplayer **Housie** (also known as *Tambola* or *Bingo*) mobile application built with **Flutter** and synchronized using **Firebase Realtime Database**. 

The app features a modern Material 3 dark-themed user interface, complete with smooth animations, dynamic ticket generation, live presence tracking, instant claim verification, and easy QR code-based lobby sharing.

---

## 📱 Features

### 🌟 Gameplay & Coordination
*   **Real-time Synchronization**: Every called number, player state change, and claim is synced instantly across all devices.
*   **Dynamic Ticket Selection**: Players can choose their ticket from a generated pool of options before the game starts.
*   **Automatic Claim Verification**: Claims are securely validated against the database list of called numbers.
*   **Presence Tracking**: Keeps track of whether players are online, offline, or disconnected.
*   **Room Hosting controls**: The host controls game startup, calling subsequent numbers, and monitoring live claims.

### 🔗 Connecting Made Easy
*   **QR Code Sharing**: Hosts can display a QR code representing the room details.
*   **QR Code Scanner**: Players can join rooms instantly by scanning the host's QR code.
*   **Shareable Room Codes**: Share room invitation links or codes easily via native sharing.

### 🎨 Visual & UI Highlights
*   **Modern Material 3 Dark Theme**: Sleek dark color palette utilizing deep purples and warm accents.
*   **Interactive Ticket Widget**: Tappable numbers with visual feedback when marked.
*   **Geometric Animated Background**: Custom-drawn canvas backgrounds for a premium look.
*   **Micro-animations**: Interactive feedback loaders and smooth state transition indicators.

---

## 🚀 Tech Stack

*   **Frontend**: Flutter (Dart) - cross-platform app framework.
*   **Backend / Database**: 
    *   **Firebase Core**: App configuration and initialization.
    *   **Firebase Realtime Database (RTDB)**: Fast real-time JSON-based sync.
    *   **Firebase Anonymous Authentication**: Seamless, friction-free login to avoid credential-related barriers.
*   **Hardware / Sharing Integrations**:
    *   `mobile_scanner`: QR code scanning using device camera.
    *   `qr_flutter`: High-performance QR code rendering.
    *   `share_plus`: Share-sheet triggers for sharing room codes.
    *   `shared_preferences`: Local persistence for saving settings and profiles.

---

## 📁 Codebase Directory Structure

```text
lib/
├── main.dart                      # App entry point & Firebase initialisation
├── firebase_options.dart          # Configuration mapping to Firebase project
├── models/
│   └── room.dart                  # Models for HousieRoom, Player, Ticket, and Claim
├── screens/
│   ├── home_screen.dart           # Dashboard (Join/Host selection, history)
│   ├── host_screen.dart           # Room configuration options
│   ├── join_screen.dart           # Screen to join a game via code or scanner
│   ├── lobby_screen.dart          # Players lobby list before host starts
│   ├── ticket_selection_screen.dart # Ticket generator & pool selector
│   ├── game_screen.dart           # Core game board with live ticket & scoreboard
│   └── results_screen.dart        # Final scoreboard listing all validated claims
├── services/
│   ├── game_service.dart          # Realtime Database write/read logic & validation
│   ├── persistence_service.dart   # Shared Preferences local history
│   ├── ticket_generator.dart      # Algorithmic Housie 9x3 ticket generator
│   └── version_check_service.dart # Remote configuration/version checking helper
└── widgets/
    ├── geometric_background.dart  # Canvas-based animated styling background
    ├── housie_ticket_widget.dart  # Custom interactive 9x3 grid ticket view
    └── star_loader.dart           # Custom star loading micro-animation
```

---

## 🛠️ Setup & Run

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.9.2` or later recommended)
*   Dart SDK (preloaded with Flutter)
*   A Firebase Project

### Firebase Integration Setup

1.  **Configure Firebase Project**:
    *   Create a project on [Firebase Console](https://console.firebase.google.com/).
    *   Enable **Anonymous Authentication** in the Authentication settings.
    *   Create a **Realtime Database** instance.
2.  **Deploy Database Rules**:
    Use the rules in `database.rules.json` to secure room reading/writing:
    ```json
    {
      "rules": {
        "rooms": {
          "$roomId": {
            ".read": "auth != null",
            ".write": "auth != null && !data.exists()",
            ...
          }
        }
      }
    }
    ```
3.  **Run Flutterfire CLI** (Optional, or setup platforms manually):
    ```bash
    flutterfire configure
    ```
    This will regenerate `lib/firebase_options.dart` with your project configurations.

### Running Locally

1.  Clone the repository:
    ```bash
    git clone https://github.com/eswar5678/Housie_Project.git
    cd Housie_Project
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    flutter run
    ```

---

## 🎮 How to Play

### Hosting a Game 👑
1.  Launch the app and tap **Host Game**.
2.  Fill in your Host Name and configure the game options.
3.  In the Lobby, share the Room Code or display the **QR Code** for other players to scan.
4.  Once all players have joined and selected their tickets, tap **Start Game**.
5.  Call numbers sequentially (the board will highlight them for you and sync them automatically to the players).

### Joining as a Player 👥
1.  Tap **Join Game**.
2.  Type the Room Code or tap the scanner icon to **scan the Host's QR Code**.
3.  Pick a ticket from the generated pool that you like.
4.  Wait for the host to start the match.
5.  Tap numbers on your ticket as they are called out to mark them.

### Supported Claims 🏆
*   **Early Five**: Any 5 numbers marked on your ticket.
*   **Top Line**: All numbers in the first row of your ticket.
*   **Middle Line**: All numbers in the second row of your ticket.
*   **Bottom Line**: All numbers in the third row of your ticket.
*   **Full House**: All 15 numbers marked on your ticket.

*Note: All claims are validated in real-time by the game server.*
