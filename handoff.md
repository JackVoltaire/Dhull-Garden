# Handoff: Dhull Garden

Notes for picking up this project in a local Claude Code chat, after the cloud session that set
it up (October 2026). Read `CLAUDE.md` and `README.md` first: they hold the rules and the
project layout. This file covers what those don't: where things stand, what the user decided,
what's still open, and what was learned along the way.

## Where things stand

Everything is merged into `main` (pull requests #1 to #8). There is no CI; see Workflow below.

- **Core systems** (autoloads, in `systems/`):
  - `Settings`, `Clock` (real-world time with debug time travel), `Calendar` (dated events and
    seasons).
  - `Saves` (versioned slots, backups, migrations, time away), `Audio`, `Scenes` (fading scene
    changes).
  - `Minigames` (launch, return results, put the player back), `Game` (pause, quit).
  - `PauseMenu` and an F3 `DebugMenu`.
  - 27 unit tests in `tests/unit/`, all passing.
- **Player and interaction.** A third-person character, an `Interactable`/`Interactor` pair with
  "[E] Dig"-style prompts, and `MinigameSpot` (the shiny spot prop) that opens a minigame.
  Sample 2D and 3D minigames exist as placeholders.
- **Dream island** (`scenes/levels/dream_island/`). A look-test level, and the scene the game
  starts in. It has:
  - the floating island, goth trees, rock shards and a ruined arch, all modelled in Blender
  - a stream, and a waterfall with jagged lines and splash puffs
  - a sea of clouds, and the locked spooky and chilly islands in the distance
  - a day/night sky (`SkyCycle`), and a film-grain screen overlay (`ScreenTexture`)
- **Look** (PR #8, the latest):
  - a dark base palette with TADC-bright magenta and cyan accents, and thin ink outlines
  - 2D "cardboard cutout" tree tops, clouds, sun and moon, animated in 4 stepped frames
  - a grinning sun and moon in the spirit of Soul Eater
  - all the drawings are placeholders for the user's own art

## The user's decisions

The design lives in the Claude Doc "Dhull — Design Notes" (link in `CLAUDE.md`). If the docs
tools aren't available locally, the summary at the end of this file covers it.

- **Names.** The creatures are Dhulls (one Dhull). Never "creature", "pet" or "Chao" in code, data
  or game text.
- **Workflow.**
  - No CI: don't add GitHub Actions.
  - Commit and push as you go, with a pull request open. Merge it yourself after a few commits
    (not every change), without waiting for a review.
  - Run lint and tests before merging.
- **Modelling.** 3D models are made in Blender. The `.blend` is the source; the `.glb` next to it
  is what Godot uses.
- **Art direction:**
  - Goth and OMORI vibes, bridging Wind Waker and Sonic Adventure 2 Battle.
  - The goth feel comes from shapes and effects, such as jagged swirls on water and splash clouds
    like Okami.
  - TADC leads the bright parts; OMORI and Don't Starve lead the dark parts.
- **Faces.** Zelda-era swappable face images (eyes, mouths) make anime expressions on the 3D
  characters. Reaction symbols pop up as in Animal Crossing.
- **2D vs 3D.**
  - Things on the ground are 3D: when ground props were drawn as 2D cutouts, the user said they
    were "better in 3d".
  - Clouds, tree tops, the sun and the moon are 2D cutouts, animated in steps with only 3 or 4
    frames.
  - "3/4" in the user's words meant 3 or 4 frames, not a 3/4 view.
- **Drawing style.** Drawings should be jagged and edgy, not basic. For the sun and moon, the
  reference is Soul Eater.

## Open questions for the user

The user merged PR #8 without answering these, so the current look stands until they say
otherwise:

1. Is the midday sky too grey? A deeper violet or indigo was offered instead.
2. The design doc still says the palette "stays free and pastel", but the look is now a dark base
   with bright accents. Should that line change? Don't edit the user's words without asking.
3. Should the ink outlines and the film grain/scanlines/vignette stay as they are, get subtler,
   or go?

Offered but not started:
- 3D gravestones and flowers for the island.
- The face-swap expression and reaction-symbol system. Moodboard motifs: zigzag grins, spiral or
  glowing eyes, star/spiral/eye symbols.
- The Dhull model itself.

## Working locally

- **Godot 4.7.2**, Forward+.
  - `tools/godot.sh` downloads and verifies Godot only on 64-bit x86 Linux. Elsewhere, set
    `GODOT` to your Godot binary.
  - The script needs bash: on Windows, use Git Bash or WSL, or just use the editor.
- **Blender 5.2.3 LTS.** Same idea with `tools/blender.sh` and `BLENDER`.
- **Lint and format:** `pipx install "gdtoolkit==4.*"`, then `gdlint . && gdformat --check .`.
- **Tests:** `tools/godot.sh --headless --path . res://tests/test_runner.tscn`. A test fails on
  any error logged while it runs, not just failed assertions.
- **First open.** The first time the editor opens the project it may regenerate `*.import` and
  `*.uid` files; commit them.

## Things learned the hard way

- **Scene files** use `[gd_scene format=3]` without `load_steps`. A node-typed export set in a
  `.tscn` needs `node_paths=PackedStringArray(...)` in the node header, or it loads as null.
- **JSON.** `JSON.parse_string()` logs an engine error on bad input, which fails tests. `Saves`
  uses `JSON.new().parse()` instead. Use `push_warning` for expected problems.
- **Models.** Godot's own `.blend` import is off. A Blender material named after a palette file
  (`toon_grass`, ...) is linked to `assets/materials/` by `tools/link_model_materials.py`.
  Collision comes from name suffixes (`-col`, `-convcol`, `-colonly`, `-convcolonly`).
- **Blender files.** Blender writes `.blend1` backups; they're ignored by git.
- **Cutout shader** (`assets/shaders/cardboard_cutout.gdshader`):
  - **Pivot.** Full billboards (floating things) need the QuadMesh centered on its middle;
    Upright ones on their bottom edge.
  - **Shadow offset.** Set `shadow_offset` to about half the mesh's width, or the drawing
    shadows itself. The caster is pushed back along the light, which doesn't move its shadow.
  - **Lighting.** Cutouts are lit as if facing the sky, so they match the ground and dim at night.
  - **The sun and moon** use `sky_cutout.gdshader` (unlit, no fog). They hang 400 m out along the
    Sun light's +Z axis, and `SkyCycle` swaps them by time of day.
- **Generated files.**
  - Scripts in the cloud session generated `dream_island.tscn`, the Blender models, the tree
    scenes (tree-top positions come from where the old Blender leaf clumps were) and the
    placeholder SVGs.
  - Those scripts are not in the repo. Edit the results directly now: scenes in the editor,
    models in Blender.
- **Renders.** Screenshots in the cloud were rendered with the Compatibility renderer, without a
  GPU, so volumetric fog and some Forward+ shading never showed. Check the look in the editor.
- **Moodboard.** The images include copyrighted art (OMORI, a TADC-style jester by Akiione).
  They live only in the private design doc: never commit them.

## Design notes, summarized

- **Concept.** An expanded spiritual successor to the Sonic Adventure 2 Battle Chao Garden. There
  is no outside action game: resources come from many small, satisfying 2D minigames (Cooking
  Mama; Pokémon Diamond/Pearl fossil digging).
- **Pacing.** It should feel like Animal Crossing: you can't speedrun it. Some things take real
  time, players can still sink in as much time as they like, and the game runs on a real-world
  clock.
- **Player.** A 3D third-person avatar walks the island. Interacting with some things opens a 2D
  or 3D minigame. Most 2D minigames gather resources: a shiny spot on a wall or rock opens a
  Pokémon-style mining minigame.
- **The island.** A big floating dream island with gated areas. Locked areas (spooky, chilly) are
  visible in the distance. Unlocks may depend on how many Dhulls you have (not settled).
- **Dhulls.** The name is ironic, as Chao aren't chaotic: these won't be dull.
  - **Look.** Neutral, smooth and almost clay-like; baby-like and cute, but anime and non-human.
  - **Head.** Detached, dullahan-style, but not spooky in the base form; a literal skull dullahan
    is the spooky evolution. The simple head floats in a fuzzy, nebula-like mist close to the
    body.
  - **Mood as weather.** Rain when sad, a storm when angry, a small sun when happy.
  - **Body.** Featureless, with chunky nubs for limbs, narrowing into a short lightning-shaped
    J tail.
- **Moodboard.** Creepy-cute: cute shapes with something wrong underneath.
  - **Bright parts:** bold reds, blues, purples and gold, heavy outlines, glowing pastel eye-rings.
  - **Dark parts:** near-black and slate, scratchy ink and crayon, moonlit greys.
  - **Faces:** zigzag-tooth grins, spiral or glowing eyes, too many eyes.
  - **Symbols:** spirals, stars, eye glyphs.
  - **Motifs:** coffins, crosses, stitches, thorny curls, graveyard stones.
  - **Texture:** scanlines, glitch blocks, halftone, paper grain.
- **"Idea bits"** in the doc are brainstorm suggestions, not decisions. Don't build them unless
  asked.
