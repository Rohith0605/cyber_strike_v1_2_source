# CYBER STRIKE
## Flutter Space Shooter — Project Documentation

**Live demo:** https://rohith0605.github.io/cyber_strike_v1_2_source/  
**Source code:** https://github.com/Rohith0605/cyber_strike_v1_2_source  
**Technology:** Flutter, Dart, Flutter CustomPainter, GitHub Actions, GitHub Pages  
**Project type:** Browser-playable 2D arcade space shooter

---

## 1. Project Overview

Cyber Strike is a neon-styled science-fiction space shooter built with Flutter and Dart. The player pilots a spacecraft through a scrolling space battlefield, automatically fires at incoming enemies, collects temporary weapon and shield upgrades, and tries to survive while earning points and progressing through increasingly difficult levels.

The game uses Flutter's custom canvas painting to draw the ship, enemies, bullets, pickups, star field, nebula effects, particles, and battlefield grid. Its interface includes an in-game HUD showing key gameplay information and status messages.

## 2. Objectives

- Build an interactive arcade game using Flutter and Dart.
- Demonstrate real-time game updates and collision detection.
- Create a distinctive sci-fi visual style using custom vector drawing and animation.
- Support keyboard play on desktop browsers and pointer/touch movement.
- Implement score-based level progression, multiple enemy classes, and temporary power-ups.
- Publish the game as a website that can be opened from a browser.

## 3. Technology Stack

| Technology | Role |
|---|---|
| Flutter | UI framework and cross-platform application toolkit |
| Dart | Game logic, entities, input handling, and update loop |
| CustomPainter / Canvas | Rendering spacecraft, enemies, projectiles, particles, and background effects |
| Timer | Periodic game-state update at approximately 16 ms intervals |
| KeyboardListener / HardwareKeyboard | Keyboard events and held-key movement |
| GestureDetector | Pointer/touch drag movement |
| GitHub | Source-code version control and collaboration |
| GitHub Actions | Automated Flutter web build and deployment pipeline |
| GitHub Pages | Static website hosting |

No external game engine or third-party runtime package is declared in the current `pubspec.yaml`; gameplay is implemented with Flutter/Dart primitives.

## 4. Main Features

### 4.1 Gameplay
- Player spacecraft with automatic shooting.
- Moving enemies with horizontal drift.
- Bullet/enemy collision detection and enemy health.
- Score awards when enemies are destroyed.
- Three health points at the start of a run.
- Game-over state when health reaches zero.
- Pause, resume, and restart controls.

### 4.2 Level Progression

Level progression depends on score:

| Level | Score threshold | Enemy behaviour/classes |
|---|---:|---|
| 1 | 0 | Scout enemies |
| 2 | 20 | Scouts and interceptors |
| 3 | 50 | Interceptors, tanks, and scouts; asteroid effects appear |
| 4 | 100 | Phantom, tank, and interceptor enemies |

The game announces level changes and adds stronger or more varied enemy types as the player advances.

### 4.3 Enemy Classes

| Enemy | Visual identity | Health | Score |
|---|---|---:|---:|
| Scout | Small, fast angular fighter | 1 | 10 |
| Interceptor | Winged angular fighter | 2 | 15 |
| Tank | Heavier armoured unit | 4 | 25 |
| Phantom | Gold-toned, flickering unit | 3 | 30 |

### 4.4 Power-ups
Power-ups fall into the playfield and activate when collected by the player:
- **Twin lasers:** raises weapon output to two shots.
- **Spread shot:** fires a wider three-projectile pattern.
- **Overdrive cannon:** uses a rapid five-projectile pattern.
- **Shield:** temporarily protects the ship from collision damage.

Weapon upgrades last for a limited duration and then return to the base weapon. A shield also expires after a limited time or can absorb an enemy collision.

### 4.5 Visual Design
- Dark deep-space background with cyan and magenta accents.
- Parallax star field, nebula gradients, and perspective grid.
- Custom-drawn spacecraft and enemy silhouettes.
- Glowing projectiles, explosion particles, and pickup effects.
- Level-based atmosphere changes.
- Small screen-shake effect on heavy impacts.
- Heads-up display for score, health, level, and status.

## 5. Controls

| Input | Action |
|---|---|
| Enter or Space | Start a run from the menu; resume when paused |
| Arrow keys or WASD | Move the ship |
| P or Esc | Pause or resume |
| R | Restart the current run |
| Mouse/touch drag | Move the ship horizontally |
| Automatic | Weapons fire while the game is running |

For keyboard movement, the game needs focus in the browser. Click the game area if keys are not responding.

## 6. Game Architecture

The current application is organized in `lib/main.dart` and uses the following main types:

- **CyberStrikeApp:** configures the Flutter application theme and opens the game screen.
- **GameScreen / _GameScreenState:** owns the game state, update timer, input handling, spawning, collisions, scoring, levels, and pickup effects.
- **Enemy:** stores enemy position, type, speed, radius, drift, health, and lifecycle state.
- **Bullet:** stores projectile position, velocity, radius, and lifecycle state.
- **Pickup:** stores power-up position, type, movement speed, rotation, and lifecycle state.
- **Particle:** stores position, velocity, colour, and remaining lifetime for visual effects.
- **GamePainter:** renders the current game state on Flutter's canvas, including the background and game entities.

### Game loop

A periodic timer calls the update method approximately every 16 milliseconds (around 60 updates per second in ideal conditions). During an active, unpaused run, the update step:
1. Samples keyboard movement.
2. Updates player motion and visual effects.
3. Updates the level based on score.
4. Fires projectiles when the weapon cooldown reaches zero.
5. Spawns enemies and periodically spawns pickups.
6. Advances bullets and enemies.
7. Detects bullet/enemy collisions and awards score for destroyed enemies.
8. Detects enemy/ship collisions and updates health, shields, and hit cooldowns.
9. Moves pickups and particles and removes expired entities.
10. Enters the game-over state if health reaches zero.

Rendering reads the current state through `GamePainter`, which draws the battlefield and visible objects.

## 7. Collision and Health Rules

- A projectile damages an enemy when the distance between their centres is less than the sum of their collision radii.
- An enemy is destroyed when its health reaches zero.
- The player loses health only when an enemy directly collides with the ship, provided there is no active shield or damage grace period.
- Enemies that move past the bottom edge are removed without damaging the player.
- A short post-hit grace period prevents rapid repeated damage from overlapping collisions.
- When health reaches zero, the game stops and displays the game-over state.

## 8. Repository Structure

```text
cyber_strike_v1_2_source/
├── .github/
│   └── workflows/
│       └── deploy.yml       # Automated Flutter web build and Pages deployment
├── lib/
│   └── main.dart            # Game logic, UI, input, entities, and rendering
├── web/
│   └── index.html           # Flutter web entry HTML/template
├── .gitignore
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml             # Package metadata and dependencies
├── README.md
└── DOCUMENTATION.md         # This document
```

The generated `build/web/` directory is created by the build workflow and uploaded as the Pages artifact; it does not need to be committed to the source repository.

## 9. Run Locally on Windows

### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK supplied with Flutter
- Visual Studio Code or another code editor
- Google Chrome or another supported browser

Verify the installation in PowerShell:

```powershell
flutter --version
flutter doctor
```

From the root directory containing `pubspec.yaml`, run:

```powershell
flutter pub get
flutter run -d chrome
```

To create a release web build:

```powershell
flutter build web --release --base-href /cyber_strike_v1_2_source/
```

The generated static web files are written to `build/web/`.

## 10. Deployment

The repository includes a GitHub Actions workflow at `.github/workflows/deploy.yml`. On a push to `main` or a manual workflow run, it:
1. Checks out the repository.
2. Installs the Flutter stable SDK.
3. Retrieves Dart/Flutter dependencies.
4. Runs a release web build with the repository-specific base path.
5. Uploads `build/web` as a Pages artifact.
6. Deploys the artifact to GitHub Pages.

### GitHub Pages configuration
In the repository, navigate to **Settings → Pages → Build and deployment** and set the source to **GitHub Actions**. In **Actions**, verify that both the build and deploy jobs finish successfully.

**Published URL:** https://rohith0605.github.io/cyber_strike_v1_2_source/

A green deployment check means that the deployment job succeeded; gameplay should still be tested in the browser after each significant release.

## 11. Testing Checklist

Use this checklist before presenting a new version:
- [ ] Website opens at the published URL.
- [ ] Main menu and start action are visible and work.
- [ ] Keyboard controls move the ship in all directions.
- [ ] Pointer/touch drag moves the ship horizontally.
- [ ] Weapons fire automatically during play.
- [ ] Bullets destroy enemies and scores increase correctly.
- [ ] Level transitions occur at scores 20, 50, and 100.
- [ ] Different enemy classes appear at the intended levels.
- [ ] Pickups activate the correct temporary effects.
- [ ] Health decreases only on direct enemy/ship collision.
- [ ] Pause, resume, restart, and game-over flow work.
- [ ] No fatal errors appear in the browser console.
- [ ] The latest GitHub Actions build and deployment succeed.

## 12. Known Limitations

- Gameplay state is held in memory; a page refresh starts a new session.
- The current project does not include user accounts, cloud saves, leaderboards, or a backend service.
- Input and game balance may require tuning across different browsers, screen sizes, keyboards, and devices.
- The current timer is a simple periodic update loop; browser throttling and device performance can affect the effective frame rate.
- The testing checklist is provided for verification; it should not be treated as evidence that every case has already passed.

## 13. Future Improvements

Possible enhancements include:
- Sound effects, music, mute controls, and audio settings.
- Boss fights and unique level objectives.
- High-score storage and leaderboards.
- Game settings for difficulty, screen shake, and control sensitivity.
- Improved small-screen touch controls.
- Automated tests for level progression and collision rules.
- Performance profiling and accessibility improvements.
- Screenshots, a trailer, and a polished portfolio landing page.

## 14. Conclusion

Cyber Strike demonstrates how Flutter and Dart can be used to create a responsive, visually distinctive browser game without a separate game engine. It combines a real-time update loop, custom canvas rendering, keyboard and touch input, collision-based gameplay, score-driven levels, power-ups, and an automated static-web deployment pipeline. Future development can extend gameplay depth, accessibility, persistence, and test coverage while retaining the existing Flutter foundation.
