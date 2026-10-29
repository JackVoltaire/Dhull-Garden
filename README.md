# Dhull Garden

A game about raising Dhulls in a garden, built with [Godot](https://godotengine.org), in the
spirit of the Sonic Adventure 2 Battle Chao Garden. The garden runs on the real-world clock,
with dated events like Animal Crossing, and has minigames in both 2D and 3D.

## Getting started

1. Install **Godot 4.7** (the standard build; the project uses GDScript, not C#).
2. In the Project Manager choose **Import**, then select this folder's `project.godot`.
3. Press **F5** to run. The game continues the save in slot 0 (or starts one) and drops you
   on the dream island, a look-test level, with a third-person character.

The first time the editor opens the project it generates `*.uid` files next to scripts and
`*.import` files next to assets. Commit both: Godot uses them to keep references intact when
files move. The `*.translation` files generated from `localization/strings.csv` are ignored.

## Controls

| Action     | Keyboard and mouse | Gamepad      |
| ---------- | ------------------ | ------------ |
| Move       | WASD / arrow keys  | Left stick   |
| Look       | Mouse              | Right stick  |
| Jump       | Space              | A / Cross    |
| Sprint     | Shift (hold)       | L3 (hold)    |
| Interact   | E                  | X / Square   |
| Phone      | Tab                | Back / Select |
| Pause      | Esc                | Start        |
| Debug menu | F3 (debug builds)  |              |

Bindings live in **Project > Project Settings > Input Map**. Code refers to actions by name
(`move_forward`, `jump`, …), never to physical keys.

## Project layout

```
systems/            Game-wide systems, one folder each. Most are autoloads.
  settings/         `Settings`: player preferences in user://settings.cfg
  clock/            `Clock`: real-world local time, day phases, debug time travel
  calendar/         `Calendar`: dated events and seasons; CalendarEvent resource
  saves/            `Saves`: save slots, backups, migrations, time away
  inventory/        `Inventory`: the player's pockets and money; ItemDefinition, one kind of item
  feed/             `Feed`: what Dhulls post and the player's reactions; DhullPosting, the rules
  dreamer/          `Dreamer`: how the player's dreamer looks; DreamerLook and DreamerColors
  garden/           `Garden`: every Dhull's life (needs, life stage, where it is) and the mess
                    in the garden, saved and moved on with the real-world clock; NewGarden, who a
                    new game starts with; MessRecord and MessTuning
  audio/            `Audio`: music crossfades and one-shot sounds
  scenes/           `Scenes`: fading scene changes with background loading
  minigames/        `Minigames`: launching minigames and returning results; MinigameSpot
  interaction/      Interactable things in the world and the player's Interactor
  looking/          Lookable: a spot that catches Dhulls' eyes
  game/             `Game`: pausing and quitting
  data/             ResourceDir: loads every resource in a data folder
data/               Game content as .tres resources
  events/           One CalendarEvent per file
  minigames/        One MinigameDefinition per file
  items/            One ItemDefinition per file: materials, food and drinks
  mining/           mining.tres, the mining minigame's tuning, and finds/, what can be dug up
  dhulls/           Dhull colorings; life.tres, how fast needs change and when moods show;
                    habits.tres, what Dhulls do in each mood
  garden/           new_garden.tres, the Dhulls a new game starts with; mess.tres, how fast the
                    young make a mess
scenes/
  main/             Entry scene: loads the save and enters the garden
  levels/           Level, the root script of walkable areas, and Ground (where the ground is)
  levels/dream_island/  Look-test floating island: art direction, sky and effects
  levels/sandbox/   Greybox garden for trying out movement and mechanics
  levels/dhull_gallery/  Every Dhull animation side by side, for checking them
  environment/      SkyCycle (sky and light by time of day), CutoutRing, InkOutlines,
                    ScreenTexture, and the drawn clouds/, sun_moon/, floating_eyes/ and doodles/
  player/           Player scene and its controller script; DreamerModel, the dreamer's model,
                    with its animations and face
  dhulls/           The Dhull scene, its genes (DhullGenome), DhullState (which animation and
                    face show each activity and mood), its animations, DhullFace, DhullColoring
                    and the face drawings in face/; DhullRecord and DhullLife (a Dhull's saved
                    life and the rules its needs follow), DhullHabits and DhullBrain (what it
                    does in each mood, and walking it there) and DhullSpawner
  minigames/mining/ The mining minigame: DigSite (the wall's rules), DigBoard (drawing it)
  props/            Reusable things placed in levels: waterfall/, shiny_spot/, goth_tree/, and
                    mess/ (a bit of mess, and the MessSpawner that shows an area's mess)
  minigames/        Minigame scenes. sample/ holds placeholder 2D and 3D minigames
  ui/pause_menu/    Pause overlay (autoload, so it works in every scene)
  ui/care_menu/     The menu for petting, feeding and picking up a Dhull
  ui/hud/           Bits of the player's HUD, like the money label
  ui/dialogue_box/  What characters say to the dreamer, a line at a time
  characters/       The island's characters, lulla/ and pebble/, with placeholder looks
  ui/shop_menu/     Pebble's shop: buy and sell, one at a time
  ui/phone/         The dreamer's phone: the feed and its post cards
  ui/name_prompt/   Naming a newly hatched Dhull
  ui/look_menu/     Where the dreamer picks their hair
  debug/            F3 developer menu (autoload, debug builds only)
localization/       strings.csv: every player-facing string, by key and language
tests/              Test runner and unit tests
assets/             Shared imported resources, by type
  models/           One folder per model: <name>.blend (the source) and <name>.glb
  materials/        The toon material palette (toon_*.tres)
  shaders/          stylized_water.gdshader and other shared shaders
  audio/ fonts/ models/ textures/
```

Scenes are grouped **by feature**: a scene, its script and any resources only it uses sit
together in one folder. `assets/` is for things shared across features.

## Systems

Autoloads load in the order listed in Project Settings > Globals; each may use the ones
above it.

- **Real-world time.** Read the time from `Clock` (`now_local()`, `phase()`,
  `day_fraction()`), never from `Time` directly, so time travel works everywhere. Connect to
  `minute_changed`, `hour_changed`, `phase_changed` and `day_changed` to react as time passes.
- **Events.** To add one, create a `CalendarEvent` resource in `data/events/`: a yearly date
  range (which may span New Year), the nth weekday of a month, or a weekday every week, plus
  optional hours. `Calendar` emits `event_started` and `event_ended`, and
  `get_active_events()` tells you what's on now. Seasons follow the
  `game/southern_hemisphere` setting. The four events in `data/events/` are examples.
- **Saving.** Persistent state lives in systems, not in scene nodes, because scenes are freed
  whenever the player switches between the garden and a minigame. A system registers with
  `Saves.register(id, self)` and implements `get_save_data() -> Dictionary` and
  `apply_save_data(data: Dictionary)`. Save files keep exact types (ints stay ints, Vector3s
  survive) and the previous save is kept as a backup. When the data layout changes, bump
  `Saves.VERSION` and add a migration step in `_migrate_step()`. `game_loaded` reports
  `seconds_away`, how long the game was closed, for things that should happen in the
  meantime.
- **Interaction.** The player walks up to things and presses Interact. Anything usable is an
  `Interactable` (an Area3D with a collision shape for its reach and a `prompt` verb); connect
  its `interacted` signal or extend it. The player's `Interactor` picks the nearest one and
  shows "[E] Dig"-style prompts.
- **Minigames.** Create a scene (2D, 3D or UI) and a `MinigameDefinition` in
  `data/minigames/`. To open it from the world, place a `MinigameSpot` (for example an
  instance of `scenes/props/shiny_spot/`) and set its `minigame` and `context`. The minigame
  reads `Minigames.context` and ends with `Minigames.finish({"score": ...})`, which returns the
  player to the exact spot they left from and emits `minigame_finished` with the result. Code
  can also call `Minigames.launch(definition, context)` directly. Running a minigame scene on
  its own with F6 restarts it when it finishes.
- **Mining.** Shiny spots open the mining minigame, a dig like Pokémon Diamond and Pearl's: a
  wall of cells under a few layers of rock, with crafting materials buried in it. The pick knocks
  two layers off a cell and one off its four neighbours; the hammer knocks two off a 3x3 patch
  but shakes the wall twice as hard. When the wall caves in or the player leaves, whatever is
  dug out completely goes into their pockets. `DigSite` holds the rules, with no engine calls;
  each find is a `DigFind` in `data/mining/finds/` (the item, the cells it covers, how common it
  is), and `data/mining/mining.tres` tunes the wall. The colors are placeholders.
- **Spots that refresh every day.** A `MinigameSpot` with `once_a_day` and a stable `spot_id`
  can be used once each real-world day: `Minigames` remembers which spots were used and on what
  local date, saves it, and the spot hides until the next day.
- **Scenes.** Change scenes with `Scenes.change_scene(path, params)`. If the new scene's root
  has `setup(params: Dictionary)`, it gets `params` before `_ready()`.
- **Settings.** `Settings.get_value("audio/music_volume")` and `set_value()`; every setting
  and its default is listed in `Settings.DEFAULTS`.
- **Audio.** `Audio.play_music(stream)` crossfades; `Audio.play_sfx(stream)` plays a one-off
  sound. Buses (Music, SFX, Ambience, UI) are in `default_bus_layout.tres`.
- **Text.** Put player-facing text in `localization/strings.csv` and use the key: Controls
  translate their `text` automatically, and in code use `tr("KEY")`. Add a column to add a
  language.
- **Look.** The art direction and moodboard are in the design notes. The toon materials live in
  `assets/materials/`; editing one recolors everything that uses it. They all use
  `toon_hatched.gdshader`: a hard edge between light and shade, ink hatching on the shady side
  and crayon streaks, laid out in world space; tune the marks per material. Instance
  `scenes/environment/ink_outlines.tscn` in a level for ink lines along silhouettes and sharp
  folds, the same width on screen at any distance; tune `line_width`, `silhouette_gap` and
  `crease_angle` on its material. `SkyCycle` colors the sky, sunlight, fog and shadow tint from
  gradients that run from midnight to midnight, and shows the drawn sun by day and the moon by
  night; in the editor, drag its **Preview Hour** to see any time of day. The sky itself is
  `stained_glass_sky.gdshader`, a speckled mosaic of broken stained glass: irregular shards of
  colored glass in thin dark lead, a few missing; tune the colors, shading and specks on the sky
  material. How the window is cut (shard sizes, lead width, missing shards) lives in
  `stained_glass.gdshaderinc`, shared with the drawings behind the glass.
  `stylized_water.gdshader` draws the jagged lines on water; tune its lanes, jaggedness, dashes
  and `line_glow` per material. Instance `scenes/environment/screen_texture.tscn` in a level for
  film grain, faint scanlines and a vignette over the whole screen.
- **Dhulls.** `scenes/dhulls/dhull.tscn` is a Dhull. Its model is put together from parts when
  it's ready, in the editor too: a body (`assets/models/dhull_body_*/`: the body, with arms,
  legs and a tail as its children, each with its origin at its joint) and a head
  (`assets/models/dhull_head_*/`) that floats and bobs above it in a nebula mist. The parts are
  separate, so each gets its own ink outline and can move on its own. To add a body or head
  shape, model it like the others, add it to `DhullGenome.BodyShape` or `HeadShape` with its
  dominance and commonness, and to `Dhull.BODY_MODELS` or `HEAD_MODELS`; tests check nothing is
  missing.
- **Dhull animations.** A Dhull's `activity` (standing, walking, sitting, sleeping, taking a selfie) and `mood`
  (content, happy, playful, sleepy, hungry, sad, grumpy) pick its animation and face from the
  tables in `DhullState`, never at random; its energy gene sets how fast they play. The
  animations are loops in `scenes/dhulls/dhull_animations.tres`, an AnimationLibrary you can
  edit in Godot's animation editor. Every animation keys every part in `Dhull.ANIMATED_TRACKS`
  (the model, body, limbs, tail, and the head holder that carries the head model and its mist),
  so blending from one into another never leaves a part behind; a test checks it, and that every
  activity and mood has an animation. Walk cycles play in place: moving the Dhull is up to
  whatever makes it walk. The Dhull gallery level (F3 menu) shows every activity and mood side
  by side, and the F3 menu can set every Dhull's activity and mood.
- **Dhull lives.** Dhulls live in the `Garden` autoload, not in level scenes: each is a
  `DhullRecord` with its genes, coloring, life stage (egg, young or adult), age, home area, needs
  and where it was last. A new garden starts empty: the first time the dreamer talks to Lulla she
  hands over an egg (`Garden.give_first_egg()`), which hatches about a day later and grows up
  after about a week as a kid (`hatch_after_hours` and `kid_phase_hours` in `life.tres`). An egg
  only shows its shell and can only be carried; eggs and kids never look after the young. A level shows the Dhulls living in it with a `DhullSpawner` (named after the area,
  like `dream_island`); Dhulls not placed yet appear at its Marker3D children. Needs (hunger,
  tiredness, happiness, each from 0 to 1) keep going on the real-world clock: the Garden moves
  them on a minute at a time with `DhullLife`'s rules, live, after a clock jump and for the time
  the game was closed (up to two weeks; needs have settled by then). Dhulls nap like cats when
  tired, the young much more; adults forage, so they get peckish but never starve; the young are
  fed and kept happy by the most nurturing adult at home, as well as its friendliness allows, and
  without one they starve, grow unhappy and make a mess of the garden: every few hours a bit of
  droppings, dirt, grime or clutter lands near them (`MessRecord`, tuned in
  `data/garden/mess.tres`). The Garden keeps the mess too; a level shows it with a `MessSpawner`,
  and the player cleans each bit up with Interact. A Dhull's mood comes from its needs
  (`DhullLife.mood_for`), and its activity and mood pick its animation and face as before. Tune
  it all in `data/dhulls/life.tres`. The F3 menu lists every Dhull's needs and can set them.
- **Dhull habits.** What an awake Dhull does comes from its mood's `DhullHabit` in
  `data/dhulls/habits.tres`: where it heads (nowhere, somewhere nearby, a spot away from the
  others, or up to another Dhull), whether it stands or sits once there, and how long it rests
  before heading out again (sooner for energetic Dhulls). A sad Dhull goes off alone and sits in
  a corner; a playful one keeps running up to the others. Adults rest by `adults_rest_by`
  instead, which can also be hanging out: scrolling their phone (`Model/Phone`, its screen
  glowing) when content, sad or grumpy, or sipping a drink when sleepy, to stay awake. Energetic
  Dhulls drink energy drinks, the rest coffee (`DhullHabits.drink_for`); the drink is the
  item's `prop`, held in the left nub. The young only stand or sit. The Dhull's `Brain`
  (`DhullBrain`) walks it there along the level's navigation mesh and keeps it on the ground. A level with
  Dhulls needs a `NavigationRegion3D`: its mesh is built from the static colliders of everything
  in the level root's `navigation_mesh_source_group`, so after changing the level, select the
  region and press **Bake NavigationMesh** in the editor.
- **Mood weather and reactions.** A Dhull's mood also shows as weather over its head
  (`DhullState.WEATHER`): a rain cloud when it's sad, a storm when it's grumpy, a small sun
  peeking out when it's happy or playful. Reaction symbols pop up beside its head, as in Animal
  Crossing: an eye when the player comes close (from farther away for curious Dhulls), a star
  when it cheers up and a spiral when it gets upset (`DhullReaction`). A mood's habit can also
  show a reaction now and then while the Dhull rests, like a sigh: sad and grumpy Dhulls get a
  spiral and gloomy blue lines down their foreheads, as in anime (`gloom` in
  `dhull_face.gdshader`). The weather and symbols are cutout drawings in
  `scenes/dhulls/weather/` and `scenes/dhulls/reactions/`, placeholders like the rest. The F3
  menu can pop any reaction.
- **The feed.** The phone button (Tab) opens the dreamer's phone. Its feed is the only way
  Dhulls talk to them: grown Dhulls post when their mood swings, when they doze off or wake up,
  when they eat, at 3am and in the morning, never more often than every 45 minutes
  (`data/feed/feed.tres`). Each post has a real selfie, taken right where the Dhull is: it strikes
  the `selfie` pose (activity `TAKING_SELFIE`), holding its phone out on a selfie stick in its
  right nub (`SelfieStick`, since nubs are far too short to frame a face) and what the post is
  about in its left (an item's `prop` mesh), and pulls a face that fits the post
  (`DhullPosting.selfie_face`: thrilled with its food, drowsy at 3am). The shot comes from the
  phone's front camera at its top edge, through the Dhull's `Selfie` SubViewport, which shares
  the level's world, so the stick shows in the picture as in any selfie-stick shot. Only the
  phone itself is hidden from it, on render layer 20, `selfie_phone`. A
  post made while the Dhull's area wasn't loaded gets its selfie the next time it is. The
  pictures are PNGs in a `slot_<n>_selfies` folder beside the save, and go with their posts. The player reacts once per
  post with a like, a heart, a sad face or an angry face, and `DhullPosting` decides how the
  Dhull takes it: bold Dhulls want a rise out of you, friendly ones sympathy, and the rest for
  you to match their vibe. The right reaction lifts its mood and bond; the wrong one stings. The
  words are translation keys `POST_<TOPIC>_<n>`, placeholders in a Dhull's voice. A hatched Dhull
  is named the first time the dreamer cares for it, the one thing they ever type.
- **The dreamer.** The player is the dreamer, modelled in `assets/models/dreamer/` like House of
  Decay's characters: a low-poly chibi with hard facets, in an oversized hoodie and platform
  boots, with a wide head whose flat face narrows to a small chin. Each hair length is one
  continuous mass, a shell over the head breaking into spikes and curls at its hem, with a short
  fringe and a lock of it over one eye. As in House of Decay, the face is a flat sheet standing
  straight in front of the head, like glasses (`Face`), painted by `dhull_face.gdshader` through
  `assets/materials/face_dreamer.tres` with the dreamer's own drawings in `scenes/player/face/`:
  thick blocky brows over tired eyes under a heavy lid, dull irises, smoky shadow and bags, in
  the order of `DreamerModel.Eyes`, and a tiny nose over a thin flat mouth (`DreamerModel.Mouth`).
  `eyes_apart` spaces the two eyes wider than the drawings without stretching them, and they
  blink. `DreamerModel` shows
  the hair of the chosen length (`HairShort`, `HairMedium`, `HairLong`) in the chosen color,
  colors the rest from `data/dreamer/colors.tres` (`DreamerColors`), and plays `idle` or `walk`
  (`scenes/player/dreamer_animations.tres`), the walk sped up to match how fast they go. The
  `Dreamer` autoload keeps their look (`DreamerLook`, saved by name) and whether they've picked
  it: a new game opens the look menu before the first dream, with the camera turned to their
  face, and **Change look** in the pause menu opens it again. Its lengths and swatches come from
  `DreamerLook`'s enums and the palette, so adding a choice is a data change plus its
  `UI_HAIR_<NAME>` string.
- **Characters.** A character is a scene in `scenes/characters/` with an `Interactable` for "[E]
  Talk to". What it says is translation keys in exported lists, shown with `Player.listen()` in
  the dialogue box; the dreamer only listens, and Interact moves on a line. Lulla's lines are
  placeholders in her voice.
- **Items and money.** Every kind of item is an `ItemDefinition` in `data/items/`: a stable `id`,
  a translated name, a kind (material, food or drink), what Pebble asks for it and pays for it,
  and for food and drink how much it fills, cheers and wakes a Dhull. The `Inventory` autoload
  counts what the player holds by id and keeps their money; `held()` lists it, `add()`,
  `take()`, `earn()` and `spend()` change it, and `changed` tells the HUD. A test checks every
  item has a name and that Pebble never pays more for an item than he asks. Pebble opens his
  shop on the garden's second day (`Garden.day_of_garden()`, counting from 1) and sells every
  item with a buy price; `ShopTrade` holds the buying and selling.
- **Caring in person.** Walking up to a Dhull shows "[E] Care for", which opens the care menu:
  pet it, feed it something edible from your pockets, or pick it up. There's nothing to say:
  words only go through the feed. `DhullCare` holds the rules. Most Dhulls love being petted,
  which cheers them and grows their `bond` with you, but not while they nap, when they're
  grumpy, when they're sad and don't trust you yet, or after too much fuss; they turn down food
  when full, and the young turn down coffee and energy drinks. A star or a spiral shows how it
  went. A picked-up Dhull rides on the dreamer's head until Interact puts it down. Tune it
  in the "Care from the player" group of `data/dhulls/life.tres`.
- **Genetics.** Every Dhull has a hidden `genome` (`DhullGenome`) that the game never shows.
  Each gene is a pair of alleles, one from each parent. Head shape, body shape, eye style and
  eye color show the more dominant of the two, so recessive variants can skip a generation;
  personality genes (energy, boldness, curiosity, friendliness) are levels from 0 to 100 and
  show the average. `DhullGenome.random()` makes genes from scratch, weighted by how common each
  variant is; `DhullGenome.bred()` gives a child one allele of each gene from each parent, with
  occasional mutations and a little drift in personality. `to_dict()` and `from_dict()` save and
  load genes by name, so saves survive new genes. A Dhull without a genome gets a random one
  when the game runs; the F3 menu's "New random genes" rerolls every Dhull in the level.
- **Dhull look.** Characters look like House of Decay's: PS1-era models with crunchy painted
  faces, while the world stays ink-drawn. Each part has its own ink outline, as wide on screen as
  the world's ink lines: `toon_character`'s next pass, `ink_hull`, draws the part's back faces in
  ink, pushed out from the part's middle (its `outline_center`, which the Dhull sets), since the
  screen-wide lines miss something as small as a Dhull standing on the ground. The part models are low-poly and flat-shaded, and
  `ps1_character.gdshader` (the `toon_character` material) lights them in a few dithered bands.
  The face is drawn on the head by `dhull_face.gdshader`, swapped like Wind Waker's faces: big
  eyes with a thick black border, big banded irises and a starburst round a tiny pupil, black
  wedge lashes, eye bags dithered under the eyes, and gritted teeth. The drawings are pixel-art
  PNG strips in `scenes/dhulls/face/`, edited in any pixel editor and shown with hard pixels;
  keep them lossless and with mipmaps in their import settings. The eyes are three strips laid
  over each other, so the irises can move: `dhull_eye_whites.png` (where an iris can show),
  `dhull_irises.png` (each iris whole and looking straight ahead, clear of its frame's edges and
  middle) and `dhull_eye_lines.png` (border, lashes, lids, bags and tears, and the shapes with no
  iris, like closed eyes, on top). The shader slides the irises a whole pixel at a time, up to
  `iris_reach` pixels, and clips them to the whites. A Dhull's genes give its everyday eyes
  (round, droopy, intense or dumb) and its eye color (teal, violet, amber, rose, mint or
  silver): the iris strip has a row per color, in the order of `DhullGenome.EyeColor`, and angry
  irises are red in every row; set its `emotion` to change its face. A Dhull's `Gaze`
  (`DhullGaze`) moves its irises: every few seconds it glances about for whatever catches its eye
  most nearby (`DhullLooking`), and its eyes follow it. What catches the eye is a `Lookable`, a
  marker placed where the eyes should land, with an `interest` from 0 to 1: the dreamer's face
  (1), Lulla's and Pebble's (0.8), other Dhulls' (0.6), the shiny spot (0.35) and mess (0.25);
  nearer things catch it more. Put one in any scene Dhulls should look at. A scrolling Dhull keeps
  its eyes on its phone, and one taking a selfie looks into the lens. `DhullFace` picks the eyes
  and mouth, and blinks; the mouth only shows when it's open. Frames follow the order of
  `DhullFace.Eyes` and `DhullFace.Mouth`; to add a shape, draw a frame at the end of its strip,
  add it to the enum and raise the frame count on `dhull_face.tres`, and a test checks they
  match. A Dhull's colors come from its `coloring`, a `DhullColoring` resource in
  `data/dhulls/colorings/`: a color per part, the color the nubs turn towards at their tips
  (painted into the model's vertex color, and stepped like the light), and an optional pattern,
  harlequin diamonds or spots. The Dhull sets them on its parts through the shader's instance
  uniforms, so every Dhull can differ while sharing one material; the character and face shaders
  keep their instance uniforms in separate slots, as a head carries both.
- **Cutouts.** Things on the ground are 3D models, but tree tops, clouds, the sun and the moon
  are 2D drawings, like cardboard cutouts, animated in steps with 3 or 4 frames. The drawings in
  the repo are placeholders. To make one, draw its frames side by side in one image (PNG, or SVG
  like the placeholders), all the same size, and turn on **Mipmaps > Generate** in its import
  settings. A strip can hold several drawings one after another (`variants`); each copy picks
  one. Next to the image, save a QuadMesh resource, shaped like one frame, whose material uses
  `cardboard_cutout.gdshader`, and set the material's `frames`, `frame_count`, `fps` and
  `variants`; raise `self_light` for drawings that should glow, and set `world_light` to 0 to
  keep their drawn colors in any light. Turn on `behind_glass` for drawings in the sky (the
  floating eyes and doodles): wherever the sky's lead or a missing shard covers them, they show
  as white line art on black. Place it with a MeshInstance3D (the tree tops in
  `scenes/props/goth_tree/`), or a `CutoutRing` to scatter many in a ring (the clouds, floating
  eyes and sky doodles). Cutouts face the camera and are lit as if they faced the sky; each copy
  starts on its own frame and may be mirrored. A cutout's shadow is its whole drawing, cast
  towards the light; set `shadow_offset` to about half the mesh's width so it doesn't shadow
  itself. The sun and moon use `sky_cutout.gdshader` instead, which ignores light and fog (raise
  `brightness` above 1 to make them shine) and is always behind the glass; they hang far out
  along the Sun light's +Z axis.
- **Debug menu.** F3 shows the date, day phase, season and active events, and has buttons to
  jump the clock forward, save, load, wipe the save, switch levels and launch any minigame.

## Conventions

- **Naming:** `snake_case` for files and folders, `PascalCase` for node names and
  `class_name`s, `snake_case` for functions and variables, `_leading_underscore` for private
  members. These follow the
  [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Static typing:** type every variable, parameter and return value (`:=` where the type is
  obvious). It catches errors in the editor and makes scripts faster.
- **Signals up, calls down:** a node may call methods on its children, but reports to its
  parent or siblings with signals. Cross-scene communication goes through an autoload.
- **Content is data:** events, minigames and similar content are `.tres` resources in `data/`,
  found automatically. Give each a stable `id`; it ends up in save files, so never rename it.
- **Pausing:** call `Game.set_paused()` and listen for `Game.paused_changed`; don't set
  `get_tree().paused` directly. Nodes that must keep running while paused (menus) set
  **Process > Mode** to *Always* or *When Paused*.
- **Physics layers** (named in Project Settings > Layer Names > 3D Physics):

  | Layer | Name   | Used by                                      |
  | ----- | ------ | -------------------------------------------- |
  | 1     | world  | Level geometry. The camera spring arm only collides with this layer. |
  | 2     | player | The player body, so the camera doesn't collide with it. |
  | 3     | interactable | Interactables. Only the player's Interactor detects them. |

- **Greyboxing:** block out levels with CSG nodes (see `sandbox.tscn`) and replace them with
  Blender models once a layout feels right.

## Models (Blender)

Models are made in **Blender 5.2 LTS**. Each one lives in its own folder,
`assets/models/<name>/`, as `<name>.blend`, the file you edit, and `<name>.glb`, the export Godot
uses. Godot is set not to read `.blend` files itself, so the project works on machines without
Blender.

1. Edit or create `<name>.blend`.
2. Name each material after a palette file in `assets/materials/`: one of the `toon_*.tres`,
   such as `toon_grass` or `toon_bark`, or a `face_*.tres` for a face the face shader paints.
   Godot then uses that material instead of the Blender one.
3. Name objects with a collision suffix where needed: `-col` (the mesh plus matching collision),
   `-convcol` (the mesh plus simpler convex collision), or `-colonly` / `-convcolonly` (an
   invisible collider only).
4. Export with **File > Export > glTF 2.0**, format **glTF Binary (.glb)**, to
   `<name>.glb` in the same folder. The default settings are right (+Y up, apply modifiers).
5. For a new model, after Godot imports it once, run `python3 tools/link_model_materials.py` to
   link its materials to the palette, then let Godot import again.

## Tooling

[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) lints and formats GDScript:

```sh
pipx install "gdtoolkit==4.*"
gdlint . && gdformat --check .   # drop --check to apply formatting
```

`tools/godot.sh` runs Godot from the command line, passing on all its arguments. On 64-bit
x86 Linux or Windows it downloads Godot 4.7.2 the first time, verifies it against the official
SHA-512 checksums and caches it in `~/.cache/dhull-garden`. On Windows, run it from Git Bash.
Elsewhere, or to use your own copy, set `GODOT` to the path of a Godot binary.
`.claude/settings.json` lets Claude Code run this script without asking.

`tools/blender.sh` does the same for Blender 5.2.3 LTS, the version models are made with
(SHA-256 checked; set `BLENDER` to use your own copy). For example,
`tools/blender.sh --background --python script.py` runs a Blender script without the interface.

Tests live in `tests/unit/`: any `test_*.gd` file extending `TestCase`, with `test_*`
methods. Run them all with:

```sh
tools/godot.sh --headless --path . res://tests/test_runner.tscn
```

or open `tests/test_runner.tscn` and press F6. A test fails on a failed assertion or on any
error logged while it runs. The exit code is 1 if anything failed.
