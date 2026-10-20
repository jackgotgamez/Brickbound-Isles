# Brickbound Isles

Brickbound Isles is an original, single-player third-person toy-brick adventure for macOS. Explore a coastal island, gather timber, help Mira rebuild a trail, and earn points, Imagination Tokens, and achievements. The game is an early first release, not an online MMO.

All characters, meshes, materials, and world content are original and generated for this project. Brickbound Isles is not affiliated with LEGO Group, Epic Games, Mojang, or TT Games.

## Play

- **WASD** — move
- **Mouse** — orbit the camera
- **Space** — jump
- **Left click** — hit a nearby tree; it breaks after three hits
- **Walk into timber pieces** — collect them
- **E** — talk to Mira, start the mission, or turn in five timber
- **Esc** — release the mouse; left-click the game to capture it again

The first mission pays **100 points** and **10 Imagination Tokens**. The HUD shows mission progress, timber, rewards, and three achievements. Progress saves locally on this Mac.

## Run from source

Install Godot 4.7.2 and its matching export templates, then open `project.godot` in the Godot editor or run:

```sh
godot --path .
```

Run the headless checks with:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/run_tests.gd
```

## Build the macOS app and disk image

Install Godot 4.7.2, its matching macOS export templates, and Xcode command line tools. Then run:

```sh
GODOT_BIN="/path/to/Godot" ./scripts/build_macos.sh
```

The script runs the checks, exports and ad-hoc signs the app bundle, confirms its executable includes ARM64, launches it headlessly, creates and verifies a `.dmg`, then copies and launches the app from the mounted image. Outputs and the SHA-256 file go in `dist/`.

Godot's official macOS templates export a universal binary with both Apple Silicon ARM64 and Intel x86_64 slices. See the [macOS install notes](MAC_INSTALL.md) for the first-open step when Gatekeeper blocks a download that is not notarized under a Brickbound Isles Developer ID.

## License

Source code is available under the MIT License; see [LICENSE](LICENSE).
