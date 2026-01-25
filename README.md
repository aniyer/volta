# Volta ⚡

Volta is a gamified chore and mission tracking application built for families. It combines a Flutter web frontend with a PocketBase backend to create an engaging experience where kids earn "Volts" (points) for completing tasks, which can be redeemed for rewards.

## 🚀 Features

-   **Gamified Missions**: Kids spin a wheel to get assigned missions.
-   **Real-time Updates**: Instant notifications for parents (approvals) and kids (redos).
-   **Review System**: Parents can approve or reject (send for redo) missions with photo proof.
-   **Redo Workflow**: 
    -   Missions sent back for redo appear in a dedicated "Inbox".
    -   Kids receive a **visual pulse** notification and can resubmit directly.
-   **Celebrations**: **Electrifying** custom lightning spark effects when points are earned.
-   **Leaderboard**: Track progress and compete.
-   **Bazaar**: Redeem Volts for real-world rewards.

## 🛠️ Tech Stack

-   **Frontend**: Flutter (Web)
    -   `confetti`: Custom particle effects
    -   `provider`: State management
    -   `pocketbase`: Dart SDK
-   **Backend**: PocketBase (Go)
    -   Host: `0.0.0.0:8090`
    -   Data persistence via Docker volume
-   **Infrastructure**: Docker Compose
    -   Nginx: Reverse proxy for serving the Flutter web build.
    -   Make: Simplified command interface.

## 📦 Setup & Run

### Prerequisites
-   Docker & Docker Compose
-   Make (optional, but recommended)

### Commands

**Start everything:**
```bash
make up
```
*Access the app at `http://localhost` (or your configured domain).*

**Rebuild Frontend:**
```bash
make deploy
```

**Stop services:**
```bash
make down
```

**View Logs:**
```bash
make logs
```

## 🔐 Accounts (Default)

-   **Parent**: `parent@example.com` / `12345678`
-   **Child**: `child@example.com` / `12345678`

## 🎨 Theme
The app uses a "Cyber Vibrant" theme with neon colors (Electric Teal, Magma Orange, Neon Violet) and a dark, modern interface.