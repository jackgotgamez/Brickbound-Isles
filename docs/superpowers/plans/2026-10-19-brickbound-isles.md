# Brickbound Isles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the approved single-player Brickbound Isles game, a tested Apple Silicon `.app`/`.dmg`, and a public GitHub release.

**Architecture:** Godot generates the island, toy characters, resources, and HUD from small reusable scenes and GDScript. An autoloaded `GameState` owns inventory, quest state, rewards, achievements, and the local save; world objects emit changes through that API.

**Tech Stack:** Godot 4.7.2 stable, GDScript, Godot's built-in headless runner, macOS `hdiutil`, `lipo`, Xcode command line tools, and the authenticated GitHub CLI.

**Spec:** `docs/superpowers/specs/2026-10-19-brickbound-isles-design.md`

## Global Constraints

- Use Godot 4.7.2 stable, GDScript, and built-in engine features only.
- Keep the first release single-player, with one seamless starter island and one local save slot.
- Award 100 points and 10 Imagination Tokens for the timber quest.
- Include the first-pickup, first-tree, and first-quest achievements.
- Create original procedural visuals; ship no third-party game assets, LEGO marks, or commercial-game characters.
- Publish the source repository publicly under the MIT license.
- Export a macOS app whose main executable contains an ARM64 slice; build a `.dmg` on this Mac.
- If Developer ID signing and notarization are unavailable, state the Gatekeeper first-open step in the release notes.

## Review Focus

- Missing or malformed save data must start from safe defaults without crashing.
- Repeated hits must not break a tree twice or award duplicate pickups.
- The quest must not pay out before five timber are collected or pay out more than once.
- Achievement and token state must survive saving and relaunching.
- A packaged app must have an ARM64 executable and accurate first-open instructions.

---

### Task 1: Project foundation and game state

**Files:**
- Create: `project.godot`
- Create: `scripts/game_state.gd`
- Create: `tests/run_tests.gd`
- Create: `tests/game_state_test.gd`
- Create: `.gitignore`

**Interfaces:**
- `GameState.collect_item(item_id: String, amount: int = 1) -> void`
- `GameState.start_timber_quest() -> bool`
- `GameState.try_complete_timber_quest() -> bool`
- `GameState.unlock_achievement(achievement_id: String) -> void`
- `GameState.update_player_position(position: Vector3) -> void`
- `GameState.save_progress(path: String = SAVE_PATH) -> bool`
- `GameState.load_progress(path: String = SAVE_PATH) -> bool`
- Signals: `progress_changed` and `notification_requested(message: String)`.

- [ ] **Step 1: Create a minimal Godot project and the game-state checks** for default values, a rejected quest completion below five timber, the exact 100-point/10-token reward, no duplicate payout, and achievement uniqueness.
- [ ] **Step 2: Run the checks and confirm they fail** because the autoload and methods do not exist.
- [ ] **Step 3: Implement the `GameState` autoload** with typed inventory, quest stage, player position, points, tokens, achievements, and the listed public methods. `start_timber_quest()` transitions once from not-started to active; `try_complete_timber_quest()` succeeds only while active with at least five timber, consumes five timber, marks the quest complete, and adds exactly 100 points and 10 tokens.
- [ ] **Step 4: Run the state checks and confirm they pass.**
- [ ] **Step 5: Commit** as `feat: add game state and quest progression`.

### Task 2: Player controls and the starter island

**Files:**
- Create: `scenes/main.tscn`
- Create: `scenes/player.tscn`
- Create: `scripts/player_controller.gd`
- Create: `scripts/world_builder.gd`
- Modify: `project.godot`

**Interfaces:**
- `PlayerController` reads `move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `interact`, and `hit_resource` input actions.
- `WorldBuilder.build(parent: Node3D) -> void` creates the island landscape and static geometry.

- [ ] **Step 1: Add input and scene smoke checks** for the main scene root, player body, camera, and required input actions.
- [ ] **Step 2: Run the checks and confirm they fail** while the scene and controller are absent.
- [ ] **Step 3: Implement the `CharacterBody3D` controller** with WASD movement, jumping, mouse-orbit camera, and a visible block-built toy avatar.
- [ ] **Step 4: Build one continuous island** with village, forest, shoreline, paths, landmarks, and player spawn using original low-poly meshes and materials.
- [ ] **Step 5: Run Godot headless import and scene smoke checks; manually launch the game and verify movement, camera orbit, and jumping.**
- [ ] **Step 6: Commit** as `feat: add third-person island exploration`.

### Task 3: Gatherable trees, pickups, and the NPC mission

**Files:**
- Create: `scenes/tree.tscn`
- Create: `scenes/pickup.tscn`
- Create: `scenes/quest_giver.tscn`
- Create: `scripts/tree.gd`
- Create: `scripts/pickup.gd`
- Create: `scripts/quest_giver.gd`
- Create: `tests/world_loop_test.gd`
- Modify: `scripts/world_builder.gd`

**Interfaces:**
- `TreeResource.hit() -> void` counts hits, breaks once after three hits, then creates five timber pickups.
- `Pickup` calls `GameState.collect_item(item_id, amount)` once when the player enters its collection area.
- `QuestGiver.interact() -> void` starts the quest or completes it when five timber are available.

- [ ] **Step 1: Write checks** for a tree breaking after three hits, exactly five pickups, one-time pickup collection, quest refusal below five timber, and a one-time reward.
- [ ] **Step 2: Run the checks and confirm they fail** before the resource scenes and scripts exist.
- [ ] **Step 3: Implement the tree, timber pickup, and quest giver** using the `GameState` interfaces.
- [ ] **Step 4: Place the interactables in the island** and show an interaction prompt when the player is in range.
- [ ] **Step 5: Run the world-loop checks and manually complete the five-timber mission.**
- [ ] **Step 6: Commit** as `feat: add timber gathering and quest loop`.

### Task 4: HUD, achievements, and persistent progress

**Files:**
- Create: `scripts/hud.gd`
- Create: `tests/save_progress_test.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/game_state.gd`
- Modify: `scripts/tree.gd`
- Modify: `scripts/pickup.gd`
- Modify: `scripts/quest_giver.gd`

**Interfaces:**
- `HUD.refresh() -> void` displays the active quest, timber count, points, and Imagination Tokens.
- Notifications use `GameState.notification_requested` for quest and achievement toasts.
- The save stores player location, inventory, points, tokens, achievements, and quest stage in `user://brickbound_save.json`.

- [ ] **Step 1: Write save checks** for successful round-trip, missing-file defaults, and malformed-file recovery.
- [ ] **Step 2: Run the checks and confirm they fail** before save/load behavior is implemented.
- [ ] **Step 3: Implement validated JSON save/load** and connect progress changes to the HUD.
- [ ] **Step 4: Unlock and display** the first-pickup, first-tree, and first-quest achievements exactly once each.
- [ ] **Step 5: Run all headless checks; manually collect items, complete the quest, close and relaunch the game, and verify that all progress remains.**
- [ ] **Step 6: Commit** as `feat: add game HUD achievements and saves`.

### Task 5: macOS export, documentation, and public release

**Files:**
- Create: `export_presets.cfg`
- Create: `scripts/build_macos.sh`
- Create: `README.md`
- Create: `MAC_INSTALL.md`
- Create: `LICENSE`
- Create: `docs/release-notes/0.1.0.md`

**Interfaces:**
- `scripts/build_macos.sh` accepts `GODOT_BIN`, imports the project, runs checks, exports `Brickbound Isles.app`, verifies its ARM64 slice, and creates `dist/Brickbound-Isles-0.1.0.dmg`.
- `README.md` documents controls, local run, test, and build commands.
- `MAC_INSTALL.md` documents the precise first-open behavior for signed/notarized or unsigned downloads.

- [ ] **Step 1: Add export settings, build script, README, Mac install instructions, MIT license, and release notes.**
- [ ] **Step 2: Run the build script's headless checks and confirm the app and DMG are built.**
- [ ] **Step 3: Inspect the app executable with `lipo -info`, launch it from the exported bundle, and copy it into a temporary Applications folder from the DMG to verify installation.**
- [ ] **Step 4: Run the game loop once from the packaged app and confirm save/relaunch behavior.**
- [ ] **Step 5: Create the public `jackgotgamez/Brickbound-Isles` repository, push the source, and publish a `v0.1.0` GitHub Release with the DMG attached.**
- [ ] **Step 6: Open the public repository and release URL, verify the DMG is attached and downloadable, then record the URLs.**
