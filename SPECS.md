# specs.md: VOLTA

> **"Spin the chore. Own the turn."**

## 1. Project Vision

**VOLTA** is a self-hosted, gamified household mission center designed to transform domestic friction into a high-energy competition. By combining a "randomizer" mechanic with a vibrant, neon-heavy UI, VOLTA encourages children to "generate energy" (earn points) that can be spent in the family Bazaar.

---

## 2. Technical Stack

| Component | Technology | Reasoning |
| --- | --- | --- |
| **Frontend** | **Flutter (Web/PWA)** | Single codebase for iOS/Android/Web with native feel and easy PWA "installability." |
| **Backend** | **PocketBase** | Lightweight, single-binary Go backend; includes Auth, DB, and Real-time syncing in one Docker container. |
| **Database** | **SQLite (via PocketBase)** | Lean, maintenance-free, and perfect for household-scale data. |
| **Infrastructure** | **Docker Compose** | Simplifies deployment on a home lab (Raspberry Pi, Synology, or mini-PC). |

---

## 3. Architecture & Deployment

### Docker Compose Configuration

```yaml
services:
  # Backend: Database, Auth, and API
  volta-backend:
    image: mujo/pocketbase:latest
    container_name: volta_pb
    restart: unless-stopped
    ports:
      - "8090:8090"
    volumes:
      - ./pb_data:/pb_data
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8090/api/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Frontend: Flutter Web App
  volta-frontend:
    image: nginx:alpine
    container_name: volta_ui
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./build/web:/usr/share/nginx/html
    depends_on:
      - volta-backend

```

---

## 4. Database Schema (PocketBase Collections)

### `users`

* `username`: string (unique)
* `avatar`: file (image)
* `points`: number (default: 0)
* `role`: select (parent, child)

### `missions` (Chore Pool)

* `title`: string
* `description`: text
* `base_points`: number
* `icon`: string (Material Icon key)
* `is_active`: bool

### `history` (The Mission Log)

* `user_id`: relation (users)
* `mission_id`: relation (missions)
* `status`: select (pending, review, completed)
* `photo_proof`: file (image)
* `timestamp`: datetime

### `bazaar` (The Reward Shop)

* `item_name`: string
* `cost`: number
* `stock`: number
* `claimed_by`: relation (users, multiple)

---

## 5. Functional Requirements

### R1: The Volta Wheel

* A randomized selection UI that "spins" through active missions.
* Logic must ensure a balanced distribution so kids don't get the "Heavy Duty" chores too many times in a row.

### R2: Verification Loop

* **The "Proof":** Children must take a photo through the app to submit a mission.
* **The "Stamp":** Parent accounts see a "Review" queue. Approving a mission triggers a real-time point injection to the child's account.

### R3: Progressive Web App (PWA) Features

* **Manifest:** `manifest.json` configured for `standalone` display.
* **Service Worker:** Cache the UI and icons for instant loading on local Wi-Fi.
* **App Icon:** High-contrast neon "V" logo for the home screen.

---

## 6. UI/UX Design (2026 "Cyber-Vibrant")

* **Theme:** Dark Mode by default (`#0F172A`).
* **Accents:** * **Neon Violet (`#8B5CF6`)** for primary interactions.
* **Electric Teal (`#2DD4BF`)** for point gains.
* **Magma Orange (`#F43F5E`)** for the "Spin" action.


* **Gamification Elements:** * `flutter_confetti` on mission approval.
* Progress bars for "Leveling Up" (based on total lifetime points).



---

## 7. Configuration & Customization

* **Admin Dashboard:** A "Parent-only" view to add/edit chores and rewards.
* **Environment Variables:**
* `PB_URL`: Pointing to the Docker backend address.
* `HOUSEHOLD_NAME`: Custom name displayed on the splash screen.



---

## 8. Development Roadmap

1. **Sprint 1:** PocketBase setup + Collection definitions.
2. **Sprint 2:** Flutter-PocketBase Auth integration.
3. **Sprint 3:** Build "The Wheel" UI and Mission submission logic.
4. **Sprint 4:** Build the "Bazaar" and Parent Approval dashboard.
5. **Sprint 5:** Dockerization and PWA manifest fine-tuning.

