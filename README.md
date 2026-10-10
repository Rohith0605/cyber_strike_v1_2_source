# Cyber Strike — upgraded Flutter space shooter (v1.2)

A neon sci-fi arcade shooter made with Flutter and Dart.

## What's new in v1.2
- **Health only decreases on a direct enemy/ship collision.** Enemies that pass the bottom of the screen are removed without causing damage.
- A short post-hit grace period prevents unfair rapid chain-damage; the ship flashes while temporarily protected.
- Keyboard support using modern Flutter `KeyboardListener`/`KeyEvent` handling.
- **WASD / Arrow keys:** move the ship in four directions.
- **P / Esc:** pause or resume.
- **R:** restart the current run.
- **Enter / Space:** start from the menu; resume when paused.
- Polished translucent cockpit HUD, level progress bar, sector badge, status labels, and keyboard guide.
- Four enemy classes, score-gated level progression, falling weapon pickups, shield, layered fighter art, particle effects, and auto-fire remain included.

## Run on Windows
1. Install Flutter and verify with `flutter --version`.
2. Extract this folder and open it in VS Code.
3. Run:
   ```powershell
   flutter pub get
   flutter run -d chrome
   ```
4. To build:
   ```powershell
   flutter build web
   ```
   Web files are generated in `build/web`.

## Controls
- Keyboard: WASD or arrows to move; P or Esc to pause; R to restart.
- Mouse/touch: drag to move horizontally.
- Weapons fire automatically.
