# Air Time - Torchy's Endless Gravity Run

A Playdate game where Torchy runs through a pseudo-3D corridor of floating platforms. Flip gravity, dodge obstacles, and solve pipe puzzles in slow-mo Air Time segments.

## How to Play

### Controls
- **A Button**: Flip gravity (toggle floor/ceiling). Hold to lock on ceiling.
- **B Button**: Alternate gravity flip / boost.
- **D-Pad Up/Down**: Select pipe layers during Air Time puzzle.
- **Crank**: Rotate pipes during Air Time. Tap A as alternative.

### Core Loop
Run forward automatically through a 3D perspective corridor. The world gets faster, platforms get narrower, and obstacles multiply. Every ~500m, hit a ramp for **Air Time** - a slow-mo pipe-alignment mini-game using the crank. Solve it to unlock the next biome.

### Regions
| Distance | Region | Difficulty | Pipes |
|----------|--------|-----------|-------|
| 0-500m | The Spine | Intro | 3 |
| 500-1200m | The Breach | Normal | 4 |
| 1200-2200m | The Rift | Hard | 5 |
| 2200-4000m | The Void | Expert | 5+decoys |
| 4000m+ | The Endless | Infinite | 5+decoys |

### Obstacles
- Platform gaps, low ceilings, side walls, moving blocks
- Rail platforms, gravity fields, dual gaps, ramp combos

### Scoring
- Primary score = distance in meters
- Air Time bonus = +50m per pipe ring aligned
- Combo bonus for consecutive gravity flips

## Development

### Requirements
- [Playdate SDK](https://play.date/dev/)

### Build
```bash
pdc source/ AirTime.pdx
```

### Run
Open `AirTime.pdx` in the Playdate Simulator or sideload to a Playdate device.

## Project Structure
```
source/
  main.lua        - Entry point, game state machine
  game.lua        - Core game loop
  renderer.lua    - Pseudo-3D corridor rendering
  player.lua      - Torchy character + gravity flip
  obstacles.lua   - Obstacle generation & collision
  regions.lua     - Region/biome definitions
  airtime.lua     - Air Time pipe puzzle mini-game
  hud.lua         - HUD, scoring, distance display
  menu.lua        - Title screen, death screen
  highscore.lua   - High score persistence
  utils.lua       - Utility functions
  pdxinfo         - Playdate game metadata
```
