# Roll & Rumble 3D (Godot 4)

> **Genre:** 3D Physics Bumper Sumo Party Game  
> **Target Engine:** Godot Engine 4.x (Forward+ / Mobile Renderer, 3D Physics)  
> **Inspired by:** *Hamsterball* (Raptisoft, 2004 – Rodent Rumble Arena Mode) & *Super Monkey Ball*  
> **Development Standard:** Spec-Driven Intent-Engineering nach Vorlesung *07: Agentic Game Development*

---

## 🎮 High Concept
Roll, boost and knock opponents off the floating arena into the abyss!  
Ein rasantes 3D-Bumper-Sumo-Partyspiel für 2 bis 4 Spieler an einem Bildschirm mit Newtonscher Starrkörperphysik (`RigidBody3D`), dynamischer *Shared Arena Camera* und Mausefallen-Hazards.

---

## 🕹️ Steuerung (Local 2-Player Couch Mode)

| Aktion | Spieler 1 (Rot) | Spieler 2 (Blau) | Gamepad |
| :--- | :--- | :--- | :--- |
| **Rollen ($X/Z$)** | `W`, `A`, `S`, `D` | Pfeiltasten (`↑`, `←`, `↓`, `→`) | Linker Analogstick |
| **Boost / Rammen** | `Space` | `Enter` | Button A |
| **Neustart** | `R` | `R` | Start-Button |

---

## 🏗️ Projekt-Architektur

- **`docs/gdd/MICRO_GDD.md`:** 5-Punkte-Spezifikation (High Concept, Core Loop, Controls, State Space, Scoring).
- **`scripts/config.gd` (`RollConfig`):** Zentral isolierte Physik-, Arena- und Timer-Parameter.
- **`scripts/state_manager.gd` (`RollStateManager`):** Deterministische State Machine (`Warmup` $\to$ `Playing` $\to$ `SuddenDeath` $\to$ `MatchOver`).
- **`scripts/player_ball.gd` (`PlayerBall`):** `RigidBody3D` mit Impuls-Steuerung, Boost-Cooldown, Comic-Augen und Out-of-Bounds-Erkennung.
- **`scripts/mousetrap.gd` (`MousetrapHazard`):** Physikalische Mausefalle mit Katapult-Impuls.
- **`scripts/shared_camera.gd` (`SharedArenaCamera`):** Dynamische Kamera für Bounding-Box & Schwerpunkt aller Spieler.
- **`scenes/main.tscn`:** Hauptszene mit Arena, Beleuchtung, HUD und Match-Ablauf.

---

## 🧪 Headless CI/CD & Unit Tests

Das Spiel verfügt über einen vollständig headless lauffähigen Test-Runner:

```bash
godot --headless -s test_gameplay.gd
```
Exits mit `0` bei Erfolg.
