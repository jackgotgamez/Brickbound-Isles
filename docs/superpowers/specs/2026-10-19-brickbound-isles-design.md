# Brickbound Isles: Design

## Intent

Create an original, open-source third-person toy-brick adventure for Jack's Apple Silicon Mac. The first release should let a player explore a continuous island, gather and break simple resources, complete a character's mission, and earn visible progress. Its purpose is to deliver a satisfying local game loop that can grow into a larger shared world later.

## First play session

The player arrives in a bright coastal village with a forest nearby. A friendly builder character has a visible quest marker and gives the player a mission to collect five pieces of timber. The player walks around the island, picks up loose items, and uses a simple swing action on nearby trees until they break into timber pickups. On return, the quest giver awards 100 points and 10 Imagination Tokens. A compact HUD shows the active mission, collected timber, points, and tokens. Achievement badges appear for the first pickup, first tree broken, and first quest completed.

Controls: WASD to move, mouse to orbit the third-person camera, Space to jump, E to talk or interact, and left click to hit a nearby resource. A gamepad is outside the first release. The camera follows smoothly and keeps the character visible while exploring.

## World and characters

The first release has one seamless starter island with a small village, forest, shoreline, paths, landmarks, collectible objects, and at least one quest character. “Open world” means a continuous area the player can freely explore, without level transitions; it does not promise a large streamed map. The player and non-player characters use original, colorful, block-built toy designs. The world is made from original procedural geometry and materials, with no extracted assets, logos, names, or characters from LEGO games or other commercial games.

## Progress and saving

One local save slot stores the player's location, inventory, points, Imagination Tokens, achievements, and quest progress. Collecting resources and completing a mission update the HUD immediately. Reloading the game restores saved progress. There is no account, cloud sync, live economy, or online multiplayer in this release.

## Technical and release choices

- Engine: Godot 4.7.2 stable, using GDScript and built-in engine features only.
- Art: code-generated low-poly meshes and materials; no external asset downloads are required.
- Source: public GitHub repository named `Brickbound-Isles`, licensed under MIT.
- Delivery: a macOS `.app` and `.dmg` with an ARM64 executable, plus a GitHub Release containing the downloadable build and source.
- Signing: the current Mac has Apple Development identities but no Developer ID identity. Unless Developer ID signing and notarization become available, the GitHub download may show Gatekeeper's first-open warning. The release notes must state the required first-open step accurately.

## Goals

- Make the first session playable from launch through a completed gathering quest.
- Give the player readable third-person movement and direct interaction with pickups, trees, and quest characters.
- Persist basic progression locally and make rewards and achievements visible.
- Provide a native Apple Silicon build that can be verified on Jack's Mac.
- Keep all game content original and the repository usable by other developers.

## Non-goals for the first release

- MMO servers, online sessions, matchmaking, accounts, chat, moderation, or a live-service economy.
- A large procedural world, building editor, combat system, or extensive quest campaign.
- Shipping LEGO branding, copied assets, or characters from LEGO, Fortnite, Minecraft, or TT Games releases.
- A notarized Mac download unless a Developer ID certificate and notarization credentials are available.

## Acceptance checks

- The project opens and runs in Godot without script or resource errors.
- A player can move, jump, collect an item, break a tree, accept and finish the gathering quest, receive the specified rewards, and see all three achievements.
- Saving and relaunching restores progression.
- The exported `.app` launches on the current Mac, and its executable contains an ARM64 slice.
- A `.dmg` installs or copies the app successfully, and the GitHub Release links to it and to the source.
- The repository includes controls, build instructions, license, and honest Gatekeeper guidance.
