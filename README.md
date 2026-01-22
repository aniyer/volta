# VOLTA 🎡

> **"Spin the chore. Own the turn."**

A self-hosted, gamified household mission center that transforms domestic friction into a high-energy competition.

## ✨ Features
- **Gamified Chores**: Earn points for completing missions.
- **Leaderboards**: Compete with family members for top ranks.
- **Profile Customization**: Choose from fun "Big Smile" avatars or upload your own.
- **Real-time Sync**: Points and updates sync instantly across devices.
- **Parent/Child Roles**: Secure parents mode for mission approval.

## 🏠 Homelab Quick Start

### Prerequisites
- Docker & Docker Compose installed
- A home server (Raspberry Pi 4+, Synology NAS, mini-PC, etc.)

### 1. Clone & Start

```bash
git clone https://github.com/yourusername/volta.git
cd volta

# Start the backend first
docker compose up -d volta-backend

# Wait for PocketBase to be healthy
docker compose logs -f volta-backend
```

### 2. Configure PocketBase Admin

1. Open `http://<your-server-ip>:8090/_/` in your browser
2. Create your admin account (first-time setup)
3. The collections will be auto-created from migrations

### 3. Build & Deploy Flutter Web

```bash
# Build the Flutter PWA (runs in Docker, no local Flutter needed!)
docker compose --profile build run --rm flutter-build

# Start the frontend
docker compose up -d volta-frontend
```

### 4. Access VOLTA

- **App**: `http://<your-server-ip>:8080`
- **Admin**: `http://<your-server-ip>:8090/_/`

---

## 📦 PocketBase Collections

VOLTA uses the following collections (auto-created via migrations):

| Collection | Purpose |
|------------|---------|
| `users` | Player accounts with points & roles |
| `missions` | Chore pool with point values |
| `history` | Mission completion log |
| `bazaar` | Reward shop items |

---

## 🎨 Environment Variables

Create a `.env` file in the project root:

```env
# PocketBase URL (used by Flutter app)
PB_URL=http://localhost:8090

# Your household name (shown on splash screen)
HOUSEHOLD_NAME=The Smith Family
```

---

## 🛠️ Development

### Rebuild Frontend
```bash
docker compose --profile build run --rm flutter-build
docker compose restart volta-frontend
```

### View Logs
```bash
docker compose logs -f
```

### Stop Everything
```bash
docker compose down
```

---

## 📱 PWA Installation

VOLTA is a Progressive Web App! On mobile:
1. Open `http://<your-server-ip>:8080` in Chrome/Safari
2. Tap "Add to Home Screen"
3. Enjoy the native app experience

---

## 🔧 Tech Stack

- **Frontend**: Flutter Web (PWA)
- **Backend**: PocketBase (Go)
- **Database**: SQLite
- **Infrastructure**: Docker Compose

---

Built with ⚡ by the VOLTA team