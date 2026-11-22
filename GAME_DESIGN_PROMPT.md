# Agent Brief: Tower of Babel (Godot 4.6)

You are extending a fast first-person action game in Godot 4.6 (Jolt physics) in the spirit of ULTRAKILL and Doom Eternal. Read this whole brief before writing anything. It explains what the game wants to feel like and how every system is built, so that new work looks like it was written by the same person.

## 1. Game design ideology

**Speed is the verb.** The player is fast, fragile and rewarded for staying in motion. Movement is the core mechanic and combat is built on top of it, never the other way around. Standing still should feel like a mistake.

**Skill expression through movement.** Run, jump, crouch, slide, wall run, strafe and backpedal all exist so the player can chain them. Momentum carries between states. Never add friction, delays or locks that punish chaining. Coyote time and input buffering exist to forgive the player, not to hold them back.

**Easy to use, hard to master.** Every move works the first time you press it: run, jump, slide, dash. Mastery comes from what chaining them does. Momentum is never reset by landing, and every technique is a small, learnable multiplier:
- Chained jumps add a little speed each hop, up to a cap, so landing with a buffered jump keeps the player faster than running.
- A slide boosts speed, speeds up downhill and can be steered. Jumping out of it launches further than a normal jump.
- A dash keeps most of the speed the player entered with and makes them immune while it lasts, so it is both an escape and a way to redirect.
- Crouching in the air slams the player down and damages everything around the landing. Landing from a slam into a jump launches very high, and landing into a held crouch slides.
- Hitting a wall in the air either vaults a reachable ledge or starts a wall run, and a wall jump keeps the run's speed.
- Speed is carried on the ground and bled off slowly, steering never snaps, and extreme air speed slowly drags back to a soft cap so the game stays controllable.
New movement should follow the same pattern: simple input, a clear payoff, and a small reward for chaining it into something else.

**Aggression is rewarded.** Enemies pressure the player instead of waiting politely. The safest place is always the one the player is moving toward. Design encounters so that retreating is slower than pushing forward.

**Readable danger.** Every attack has a visible and audible windup, a short active window and a cooldown. The player should die because they chose wrong, never because they could not read it. Telegraph first, hurt second.

**Diegetic UI over HUD.** Information lives in the world or on the player's body: a lamp that dims, a viewmodel that reacts, wind lines that show speed, a flash that shows a hit. Avoid bars and numbers. If a value matters, find a physical object that can express it. A new UI element is justified only if the player needs the information mid-fight and nothing in the world can carry it.

**Enemies are fair and a little dumb in the right ways.** They chase, surround and attack, but they must never get visibly stuck on geometry. A stuck enemy breaks the fantasy faster than a weak one.

**Death is a moment, not a menu.** Dying is a short physical sequence that the player can read: the body collapses, the camera tips over, control is lost, and only then does the game reset. Enemies stop thinking, keep obeying physics, and disappear after a beat. No instant cuts to a game over screen.

**Builds come from data.** Power comes from items, upgrades and abilities the player (or an enemy) picks up, not from hardcoded cases. Adding a new upgrade should mean creating a resource file, never editing a script. The same system powers the player, enemies and bosses, so an enemy can carry an item the player can also find.

**Bosses are encounters, not stat sponges.** A boss is a sequence of phases, each one asking the player to use a different part of their movement kit. See section 5.

## 2. Code methodology

These rules apply to every file you write or edit.

**Small, single-purpose scripts.** Target around 200 counted lines per file. Exports, constants, signals and blank lines do not count. Up to roughly 10 percent over is fine. If a file is larger, condense first (remove redundancy, extract helpers) and split only when condensing cannot get under the limit. Never split just for tidiness.

**Composition over inheritance.** Behavior lives in small components attached to a scene, such as `HealthComponent`, `HurtboxComponent`, `HitboxComponent`, `KnockbackComponent`, `HitFlash` and `EnemySteering`. A scene gains a behavior by adding a node, not by subclassing.

**Signals decouple everything.** A component announces what happened and never reaches into another object. Listeners subscribe. Prefer `health.died.connect(...)` to polling or direct calls. A signal is cheap, so add one whenever another system might care.

**Inspector wiring.** Every dependency is an `@export` variable assigned in the editor: nodes, resources, action names, tuning values. No `get_node` with string paths, no `$` shortcuts for dependencies, no hardcoded node names in code.

**No nodes created in code.** Never write `Node.new()` or `add_child` to build structure. Instead, give the user the exact node tree to build in the editor, with the script on each node and every export to assign. Scene files (`.tscn`) you produce must follow the same tree. (Runtime helpers that are not nodes, such as `Tween`, `KinematicCollision3D` and `RefCounted` data, are fine.)

**State machines for anything with modes.** Each state is its own script extending a shared state base class, assigned to a node under the state machine through the inspector. States do not call each other. They emit a signal or ask the machine to transition. Adding a new state means adding one script and one node, with no edits to the existing states.

**Data-driven and tunable.** Everything a designer might want to change is an exported variable with a sensible default, grouped with `@export_group`. Prefer tables, curves and resources over `match` ladders.

**No magic numbers.** Every literal is either an exported variable, a named `const`, or derived with math. Even `0.5` and `1.0` should be named when they carry meaning.

**Hits are data.** A `HitData` object carries damage, knockback and source. Hitboxes create it, hurtboxes scale it, health consumes it, and other components (knockback, flash, sound, UI) react to the `damaged` signal. To add a new property to a hit, add a field to `HitData` and change nothing else. Collision layers separate who can hurt whom.

**Stats, items, upgrades and abilities are resources, with no exceptions.** Anything a designer might create is a `Resource` file made from the inspector's "New ..." menu and dragged into an array. Content never needs a script edit, and a new script is needed only for a brand new kind of effect.
- `StatDefinition` names a stat and its limits. `StatModifier` pairs a stat with a flat and a percent bonus.
- `AbilityEffect` is the base for one atomic effect (`HealEffect`, `ImpulseEffect`, `StatBuffEffect`). Effects override `can_apply(context)` and `apply(context)`.
- `AbilityData` is a concrete resource, never subclassed: cooldown, input action, `automatic` flag and an array of `effects`. A new ability is a new file that combines effects, such as a dash that also heals.
- `ItemData` is the base for anything an owner can carry: stat `modifiers` plus `abilities` it grants. `UpgradeData` adds `max_stacks` and is a stackable passive. `EquipmentData` adds a `SlotDefinition` and replaces whatever occupies that slot. Both kinds can carry modifiers and grant abilities.
- `SlotDefinition` is a resource too, so slots are dragged in rather than typed. An inventory's `allowed_slots` decides which equipment it accepts.
- Resources hold configuration only. All runtime state (stack counts, cooldowns, equipped slots) lives in components, because one resource is shared by many owners.

Components bring the resources to life, and any entity gets them by adding nodes:
- `StatsComponent` stores modifiers by source and computes `(base + flat) * (1 + percent)`, clamped to the stat's limits. It emits `stat_changed`.
- `InventoryComponent` equips and removes items. It checks `allowed_slots`, handles stacking and slot replacement, and applies or withdraws each item's modifiers and abilities. It emits `item_added`, `item_removed`, `item_equipped` and `item_rejected`. `starting_items` equips items on spawn.
- `AbilityComponent` holds granted abilities, runs cooldowns, listens for an ability's `input_action` when `accepts_input` is on (the player), and fires `automatic` abilities by itself (enemies and bosses). It emits `ability_used` and `ability_ready` and exposes `cooldown_ratio` for diegetic UI.
- `StatBinder` points one stat at one property of one node. It reads that property's current value as the base, so existing tuning stays in the inspector and upgrades layer on top. To make something upgradeable, add a binder and never edit the target script.
- `ItemPickup` hands its item to any body that carries an inventory. Bodies are found through a meta key the inventory registers.

**Spawning is placement, not logic.**
- `PlayerSpawn` is a `Marker3D` that registers in a group. `PlayerRespawn` finds the active one, so there are no cross-scene node paths. Several spawns can exist, and `activate()` makes one the active spawn, which a checkpoint trigger can call through a signal. With no spawn in the level, the player's starting transform is used.
- `EnemySpawner` is a `Marker3D` that instances an enemy scene near itself, with limits (`maximum_alive`, `total_limit`, `spawn_interval`, `initial_count`). It can equip `bonus_items` on whatever it spawns, so enemy builds are data too. Spawners do not know what enemies do.

**Death is a signal chain.** `HealthComponent.died` triggers `DeathComponent`, which emits `dying` immediately and `death_finished` after `death_delay`. Everything else listens:
- The player enters a `Dead` state through a `dying` connection in the scene. That state coasts to a stop under gravity and shrinks the capsule so the camera drops. `DeathRoll` tips the camera and the punch input is switched off.
- On `death_finished`, `PlayerRespawn` moves the player to the active `PlayerSpawn`, clears velocity and camera tilt, revives health, returns the state machine to its initial state, grants a short protection window and emits `respawned` (which turns the punch input back on). The level is not reloaded, so the player keeps their items and upgrades.
- Enemies call `deactivate()` on `dying` and `queue_free()` on `death_finished`.
- Dead things ignore further hits inside `HealthComponent`, so knockback, flashes and damage all stop with no extra checks.
- New reactions (sound, particles, drops, boss phase triggers) connect to `dying` or `death_finished`. They never edit the death code.

## 3. Style rules

- A short high-level comment sits directly above each function and says what it does and why. No line-by-line narration.
- No decorative separators such as `# ----------`.
- Group code with `#region Name` and `#endregion`.
- Use full-word names for variables and functions (`drift_velocity`, not `dv`). Never use one- or two-letter names, including loop indexes (`probe_index`, not `i`) and lambda parameters.
- Early returns and small functions beat nested branches.
- If logic appears twice, extract a helper and reuse it.
- Prefer math (`lerp`, `clamp`, `remap`, trig, ratios) over branching when the result is the same.
- Prefer computing and returning new values over mutating state.
- When delivering code, give the complete file for each file you changed, and only the files you changed. Do not repeat unchanged files.

## 4. Existing architecture to respect

- `player/`: `PlayerBody` (CharacterBody3D) plus a `StateMachine` with ground (run, walk, crouch), slide, jump variants (normal, slide jump, slam jump, wall jump), air, wall run, mantle, slam, dash and dead states. Immunity during a dash is a signal connection to `HealthComponent.set_immune`. A camera rig handles look, tilt and offsets. Viewmodel scripts drive the diegetic UI (lamp gauge, speed wind, viewmodel reactor).
- `combat/`: the hit and hurt system described above. Any scene that can be hurt gets `Health` plus `Hurtbox`. Any scene that can hurt gets a `Hitbox`, which `pulse()` opens for a short window.
- `stats/`, `items/`, `abilities/`: the resource-driven build system from section 2. Example resources live in `data/stats` and `data/items`.
- `combat/` also holds `DeathComponent`. The player has a `Dead` state in its state machine, a `PlayerRespawn` component and `PlayerSpawn` markers. `npc/enemy_spawner.gd` spawns enemies.
- `npc/`: `Enemy` chases, windups, strikes and cools down, steered by `EnemySteering`. `attack_dummy` is a static target with `invulnerable = true`.
- Bound properties must be floats. When adding a binder, the base value is whatever the property holds in the scene.
- Input actions used by abilities (such as `heal`) must exist in the Input Map. `AbilityComponent` ignores unknown actions instead of crashing.
- Collision layers: player body, world, player hitbox/hurtbox and enemy hurtbox are separate layers. Check `project.godot` and the scene files before choosing a layer, and never assume.

## 5. Boss system philosophy

A boss is built from reusable parts so a new boss is mostly configuration:

- **BossController** owns a list of **phases** and listens to the boss's `HealthComponent`. Crossing a health threshold emits `phase_changed(phase_index)`. It contains no attack logic.
- **BossPhase** is a node (or resource) holding a pool of **BossAttack** nodes, a movement style and tuning such as speed and attack cadence. Swapping phases swaps behavior, so each phase should feel like a different fight.
- **BossAttack** is a small component with a common contract: `telegraph`, `execute`, `recover`, each announced by signal. Attacks are interchangeable, and a new attack is one script plus one node.
- **Pattern, then punish.** Every attack has a telegraph the player can read and a recovery window in which the boss is vulnerable. Fights are a rhythm of dodge, then punish.
- **Make the player use the whole kit.** One attack forces a slide (low sweep), another a jump (shockwave), another wall running (floor goes dangerous), another constant strafing (projectiles). Escalate by combining and speeding up, not by adding hit points.
- **Arena as a participant.** Phases can change the arena through signals (pillars rise, floor sections become hazards), and arena objects listen for `phase_changed` rather than being driven directly.
- **Diegetic boss feedback.** Show phase and health through the body: cracks that spread, a glow that shifts color, a weakened limb. No health bar unless nothing else works.
- Adding a boss should need no edits to `BossController`. Adding a phase or attack should need no edits to existing ones.

## 6. Enemy AI philosophy

Enemies move through the world like a simplified player: they run, jump, climb, cross gaps and drop down, but never chain anything.

- Enemies steer by probing the world, not by following a fixed script. A fan of shape-casts scores each direction by how well it points at the goal, how open it is, how consistent it is with the current heading and how far it keeps from other enemies. The best direction wins.
- Obstacles the enemy can clear are treated as nearly open, and taller ones cost slightly more. When one is close, the enemy jumps exactly as high as it needs to, up to a configured climb height.
- Gaps are crossed with a jump when ground exists beyond them. Pits with no landing are avoided, unless the target is well below, in which case the enemy is willing to drop down.
- Enemies lead a fast target by aiming where it is heading, so sprinting in a straight line does not shake them.
- Stuck detection measures real progress on an interval. If the enemy barely moved, it sidesteps toward the more open side for a short time and tries a hop.
- Navigation meshes are optional. If a `NavigationAgent3D` is assigned and a baked path exists, steering follows its waypoints. Otherwise it heads straight for the goal. Both paths share the same obstacle logic.
- Behavior stays signal-driven. Steering emits `jump_requested` and `stuck_detected`, and the enemy decides what to do with them.

## 7. How to answer

1. Restate in one or two sentences what you are about to build and which files it touches.
2. If new nodes are needed, give the node tree, the script on each node and every export to assign. Do not create nodes in code.
3. Give the full contents of each changed or new file, and nothing else from the project.
4. Finish with a short checklist of editor steps (nodes to add, exports to assign, layers to set).
5. If a requirement conflicts with these rules, say so and ask before breaking the rule.
