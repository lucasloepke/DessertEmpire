# Project: Dessert Empire — Roblox tycoon

I'm building a Roblox tycoon game in Roblox Studio. This is my first project of this size. Assume nothing about my project structure or toolchain unless I've told you — ask, or have me check in Studio.

**The game:** You start with a popsicle stand in a vacant boardwalk kiosk and build it into a dessert park. Everything happens on the player's own plot.

## The station model (this is the whole game)

Every tier is the same mechanic. There is exactly one mechanic in Dessert Empire and it is this:

1. Player walks up to a station. A floating panel fades in.
2. Player clicks the button on it.
3. An animated progress bar runs for N seconds; the bar label counts down remaining time (`1.5s` → `0.5s` …). Idle = `SELL`, automated idle = `AUTO`.
4. The bar completes and pays $X.

Automation means the button clicks itself the instant the bar completes. The bar then runs forever and pays $X every N seconds without the player. It is off-cooldown for one frame, so an automated station and a manual one are the same object in the same state loop — automation is a boolean, not a second system.

**A station has exactly two numbers: payout and duration.** Income is payout ÷ duration. Nothing else feeds it. No arrival rate, no demand, no queue, no stock, no inventory, no spoilage. Customers are decoration and never touch income.

Both numbers are a base value times multipliers the player buys:

- payout = `BasePayout × PayoutGrowth^level × (every owned PayoutMultiplier)`, rounded to whole dollars
- duration = `BaseDuration ÷ (every owned SpeedMultiplier)`

This math lives in exactly one place: `src/shared/StationMath.luau`.

Each new tier is a new station with a bigger payout, sitting alongside the old ones. Automated earlier stations keep paying, so total income is the sum of every automated station's rate. That is the entire economy.

## The spend flow (same for every station)

1. **Panel UPGRADE** — the button under SELL on the floating panel. Repeatable forever. Each level multiplies payout by `PayoutGrowth` (×1.25); its price multiplies by `CostGrowth` (×1.6) each time. This is the always-available money sink.
2. **Physical upgrades** — walk-on floor buttons next to the station. Default unlock is in list order; an upgrade can set `Requires = { ids }` to appear earlier/in parallel. Each available upgrade gets its own button. Each adds a visible model and one big effect: `PayoutMultiplier` (e.g. ×2, ×3) or `SpeedMultiplier` (e.g. ×2 sell speed, which halves duration).
3. **Employee** — physical upgrade with `Automates = true`: the bar clicks itself forever. It unlocks partway down the list, not last: tier 1 Cashier with Deep Freezer (`Requires = { "BiggerCooler" }`), tier 2 Cart Manager as soon as the Cooler Cart exists (`Requires = {}`, same time as Second Cart).
4. **Next tier unlock** — a floor button owned by the current station but placed on the spot where the next station will stand (`Placement`). It appears once the current station owns every id in the next station's `UnlockRequires`, so the next tier's path is visible *before* the employee is bought. Buying it builds the next station.

## Core design rules (settled, don't re-propose alternatives)

- **Every station is manual first.** The player clicks it themselves; the employee automates it.
- **Every station follows the spend flow above.** Panel upgrade + physical upgrades (ordered unless `Requires` says otherwise) including an employee. Don't invent per-station mechanics.
- **The panel upgrade is payout only.** Speed comes only from physical upgrades, so each lever has one obvious source.
- **Keep `CostGrowth` well above `PayoutGrowth`.** At ×1.35 cost vs ×1.25 payout, a simulated player hit $2.7K/s by automation and made tier 2 trivial. ×1.6 is the current tested value — re-simulate before changing either.
- Employee cost for a tier ≈ unlock cost of the next tier. Keep those two numbers adjacent in the config so the rule is checkable at a glance.
- Physical upgrades add visible models to the plot. Progress must be legible from the plot entrance without opening any UI. (Panel upgrade levels are not visible on the plot — they're the small, frequent sink.)
- **Big builds are many upgrades, not one.** Shells and structures (truck body, parlor room, factory, dock) are staged as bite-sized physical buys — frame, walls, roof, then gear — so every purchase changes the plot. See Tier ladder roadmap.
- Earlier tiers never become dead content — once automated they keep paying forever.
- **No loss mechanics.** No spoilage, decay, failure, or anything that can take money or progress away.
- Players don't leave the plot to progress. Off-plot is for foraging rare ingredients, a trading hub, and seasonal events only.
- All progression numbers live in one shared config module. No magic numbers in systems code.
- **Server is authoritative** for all money and station state. Clients send requests only; the server independently re-validates ownership, distance, cooldown, and affordability on every one. An automated station's timer runs on the server, not in the client's bar.
- **No far-away `$` icon** over the stand. Purchase text holograms are distance-gated; the far marker was cut.
- **Things only exist once bought.** No pre-built empty slots, lots or outlines: an upgrade's whole visual (including its ground, e.g. a parking spot's asphalt) appears on purchase. Before that, only its floor button is there, standing where the thing will appear.
- **Every purchase lands.** Anything bought or built falls in from the sky with a small hop and the block-place sound; NPCs land just after their props with the block sound plus a louder villager line, then chatter randomly. Not replayed on join/rebuild.
- **Decoration never touches income.** Cart traffic, NPC chatter, drop-ins and customers are client-side flavour on top of the payout ÷ duration loop.

## Simplicity rules (learned the hard way)

- Prefer the simplest version that's still fun. If a mechanic needs tracked state the player can get stuck behind, cut it and assume it instead.
- If a proposed feature isn't "a button, a bar, and a payout," it probably doesn't belong. Say so before building it.
- Placeholder art is plain `Part`s, `Material = Plastic`, all six surfaces `Studs`. No meshes/textures for placeholders. Chosen Creator Store art (like the street road) is exported into `assets/` and baked — not left as a loose Studio-only insert.
- Prefer engine built-in assets (`rbxasset://`) over Creator Store IDs when a simple Part will do. A wrong Creator Store ID fails silently.
- Every `WaitForChild` gets a timeout and an `assert` naming the instance. A bare `WaitForChild` turns a typo into a silent server freeze.
- Replicate state to clients via **Player attributes** where possible, not RemoteEvents. Attributes replicate automatically and can't desync. Add remotes only when the client needs to *request* something.

## Tier ladder (roadmap)

popsicle stand → cooler cart → ice cream truck → parlor → dessert factory → loading dock → second wing / prestige

Each is one station, following the model above, with a bigger payout than the last. The flavor per tier (a cart, a truck with a jingle, seated tables, a factory line, grocery semis) is visual identity and may act as a flat income multiplier. It is never a simulation.

**Bite-sized upgrades keep the game fun.** Big structures are never one purchase. Break them into ordered physical upgrades that each add a visible piece and one payout/speed/automate effect — same spend flow as tiers 1–2. Example: a factory unlocks as a bare pad, then Frame → Walls → Roof → equipment, each its own floor button. The plot must look meaningfully different after every buy. Prefer many small steps over a few expensive "whole building" dumps. Parallel paths via `Requires` are fine (employee alongside shell pieces); don't invent a second mechanic to stage construction.

| Tier | Station | Status | Planned physical flavor (not numbered yet) |
| --- | --- | --- | --- |
| 1 | Popsicle stand | **Built** | Cooler → Freezer + Cashier → Dispenser → Neon Sign |
| 2 | Cooler cart | **Built** | Fleet carts + Cart Manager (lot asphalt per cart) |
| 3 | Ice cream truck | Placeholder (`UnlockCost` only) | Speakers, side window, string lights, paint/wrap, menu board; **Driver** automates. Truck can arrive incomplete (chassis → body → window → lights) rather than as one dump. |
| 4 | Parlor | Not started | Toppings bar, booths, second floor, décor/signage, marketing bits (sandwich board, awning, posters); **employees** automate. Build the room in steps (foundation / walls / roof / interior) before stuffing it with amenities. |
| 5 | Dessert factory | Not started | **Build piece by piece:** 1. frame, 2. walls, 3. roof, then industrial freezer, industrial packager, second conveyor belt, packing station, etc. One station, many bite-sized buys — the building grows on the plot. |
| 6 | Loading dock | Not started | Connected to the factory. Dock bay / canopy / ramp as separate steps; semi trucks that pull in (decoration, like cart traffic); more bays or fleet trucks as payout/speed ups; a dock worker / dispatcher automates. |
| 7+ | Second wing / prestige | Not started | Later. Prestige is a supporting system, not a station mechanic change. |

Tiers 3–6 are direction only: upgrade names and build order will get real costs / `Requires` / placements when we design each tier. Until then, don't invent numbers in systems code.

## Supporting systems (not built yet)

- **Flavors** as the collection layer: fruit pops → ice cream → gelato → novelty, with rares and seasonals.
- **Weather and time of day** as flat income multipliers.
- **Offline earnings** — trivially computable under this model: for each automated station, elapsed time ÷ duration × payout (both from `StationMath`).
- **Prestige.**

---

## Tier 1 — popsicle stand

The canonical station. Click SELL, a **1.5-second** bar runs, it pays $5. UPGRADE under SELL starts at $10 and makes sales ×1.25 per level. Floor buttons offer available physical upgrades:

| # | Upgrade | Cost | Effect | Visual | Unlock |
| --- | --- | --- | --- | --- | --- |
| 1 | Bigger Cooler | $150 | ×2 sales | blue cooler, left of counter | start |
| 2 | Deep Freezer | $1,000 | ×3 sales | white freezer, right of counter | after Cooler |
| 3 | Pop Dispenser | $4,000 | ×2 sell speed | pink box on counter (right; old register spot) | after Freezer |
| 4 | Cashier | $10,000 | automates | Creator Store `Cashier` NPC behind counter + register on counter center facing employee | after Cooler (`Requires = { "BiggerCooler" }`, same time as Freezer) |
| 5 | Neon Sign | $150,000 | ×2 sales | neon board mounted on the **street-facing front of the counter** (not above it); SurfaceGui `{DisplayName}'s Popsicles!` (`Material = "Neon"` is the one exception to the Plastic placeholder rule) | after Cashier + Dispenser (`Requires`) — cooler-cart mid-game return sink |

Cashier arrival: clones `ReplicatedStorage.Cashier` as an anchored prop (no nameplates, no physics), feet on the pad; it drops in like every other purchase (below), landing just after its register. Cash register uses `FaceEmployee`; NPC faces the street.

**Drop-in (all tiers):** every physical-upgrade visual and every newly unlocked station falls from the sky on purchase (40 studs, ~0.55s fall + small hop), then plays `Workspace.Sounds["Minecraft Block Place"]`. NPCs land ~0.35s after their props and play the block sound plus a louder random `Workspace.Sounds["NPC Sounds"]` line (`NpcPurchaseVolume`). Server places things at their final spot and tags them (`TycoonConfig.Tags.DropIn` + `DropAt` server time + `DropParts` part count); `client/DropIn.luau` animates locally for every player, timed off server time. The tag can reach the client before the model's children, so the client waits (≤ `ReplicationWait`) until `DropParts` parts have arrived, lifting each out of sight as it shows up — without this, drops and landing sounds silently didn't happen. `shared/DropParts.luau` is the one rule for which parts move (skips nested drop-ins like the NPC, and purchase buttons). Not on join/rebuild. NPCs (tag `Npc`) also say a random NPC line every 8–20s (`client/NpcChatter.luau`). Numbers: `TycoonConfig.DropIn`, `TycoonConfig.Audio.Place*` / `Npc*` (sound ids there are fallbacks if the place copies are missing).

Neon Sign is intentional dead-content prevention: the button shows once the early stand is complete, but $150K sits between cooler-cart Second ($40K) and Third ($200K), so players duck back to the stand after a bit of cart progress. Visual parts use `FaceStreet`; the neon face sets `Label = "{Player}'s Popsicles!"` (substituted with `player.DisplayName` in `StandService`).

Simulated pacing at **BaseDuration = 1.5** (player clicks every cycle, buys the cheapest affordable thing incl. panel levels): Cooler ~0.8 min, Freezer ~1.8, Dispenser ~2.3, Cashier ~2.7 (~$1.1K/s). That's fast — tier 1 may want a retune. The sim predates the Neon Sign, so re-run it with the sign before trusting tier-2 minute marks. Tier 2 unlock is $10,000 to match the Cashier.

What it does not have, on purpose: mold trays, pouring, stock, customer arrivals, queues, ProximityPrompts, floating status text, far-away `$` stand icon. All were tried and cut.

## Tier 2 — cooler cart

One cooler cart left of the popsicle stand (when facing the road), with a three-spot parking lot further left that fills with carts — a fleet of four. Parked carts are rotated nose-to-street; every cart has four corner wheels. Click SELL (on the first cart), a **4-second** bar runs, it pays $150. UPGRADE starts at $300 (×1.6 cost / ×1.25 payout, same as tier 1).

Unlock: a $10,000 floor button on the cart's spot, shown once Bigger Cooler is owned (`UnlockRequires = { "BiggerCooler" }`), i.e. alongside the Cashier, so the tier 2 path is visible before automating tier 1. Nothing of the lot exists at unlock: each spot's asphalt segment (back of the lot → sidewalk, painted lines over the parking part) arrives with that spot's cart upgrade. Buttons sit on the bare plot where the spot will be.

| # | Upgrade | Cost | Effect | Visual / button | Unlock |
| --- | --- | --- | --- | --- | --- |
| 1 | Second Cart | $40,000 | ×2 sales | parks in lot spot 1; button on that spot | start |
| 2 | Cart Manager | $40,000 | automates | desk (clipboard, sign) right of the first cart + `Cashier` NPC behind it; button on the desk spot | start (`Requires = {}`, same time as Second) |
| 3 | Third Cart | $200,000 | ×2 sell speed | lot spot 2 | after Second |
| 4 | Fourth Cart | $1,000,000 | ×3 sales | lot spot 3 | after Third |

Layout (station space, X across with −X = left facing the road, Z away from the street): first cart at `Placement = (-26, 0, 0)` from the stand counter, serving with its long side along the street. Lot spots at cart-relative X −8 / −16 / −24, 8 wide; parked carts sit at Z 1.5; asphalt runs from Z 6 to the plot edge at Z −10 (`TycoonConfig.StationStreetInset`). Manager desk at X +6. Cart Manager reuses the `ReplicatedStorage.Cashier` model.

Cart Manager cost = placeholder tier-3 Ice Cream Truck `UnlockCost = 40000` (`UnlockRequires = { "SecondCart" }`, no `Placement` → never built). Old sim (Manager at $500K after Second) is stale — re-run before trusting minute marks.

Cart traffic (decoration only, `client/CartTraffic.luau`, numbers in `TycoonConfig.CartTraffic`): each tier-2 sale sends one parked fleet cart (`Visual.DepartingParts`, built as a `Cart` sub-model tagged `Departs` so the asphalt stays put) up its driveway toward the sidewalk while fading out, then it fades back in and rolls into its spot (~3.4s). Round-robin, max one cart away at a time (`MaxAway`) so the fleet stays readable from the plot entrance. Animated only on the owner's client; carts still dropping in are skipped.

## Current implementation state

Working:
- Rojo module layout + place geometry bake
- Player save schema + DataStore load/save with retries (in-memory fallback when DataStores unavailable in unpublished Studio)
- Street plot pads in the place file; plot assignment + runtime stand population
- Join-order skeleton (`CharacterAutoLoads` off)
- Placeholder popsicle stand on claim; vacant pads are grass, claimed pads flip to boardwalk
- Creator Store road tiled and **baked** into the place (`Workspace.Plots.Street.RoadSegments`)
- Station loop (every tier): client station panel (SELL countdown bar + UPGRADE) → server-run cycle → payout; employee restarts the cycle on the server
- Walk-on purchase buttons (cyan = affordable, orange = not) + distance-gated text holograms; one button per `StationMath.availablePhysical` offer
- Cashier parallel unlock with Deep Freezer; Pop Dispenser still sequential after Freezer
- Money HUD (Cash attribute): +$ gain popups spawn at a random X along the balance box, float upward, stay fully visible ~0.5s, then fade **transparency** (text + stroke — not to black); positional sale sound; door-open sound on every purchase (panel or physical)
- Music shuffles `Workspace.Sounds.Music`; bottom-right box is a vertical volume slider (bottom = 0)
- Hold Left Shift to sprint (WalkSpeed 16→25, FOV 70→82); tunables in `TycoonConfig.Sprint`
- Temporary admin HUD (left side): `+$1K`, `+$50K`, and **Reset Progress** — Studio always; live = place CreatorId + `TycoonConfig.Admin.UserIds`. Server re-checks; sets `AdminEnabled` attribute.
- Multiple stations per plot: `TycoonConfig.Stations[i].Placement` positions each station; tier 2 cooler cart built (unlock button lives on the previous station). Client panel follows the nearest station within range (one panel, never two overlapping).
- Tier 2: cooler cart, per-spot parking lot, Cart Manager desk, decorative cart traffic.
- Drop-in on every purchase (block-place sound; NPCs add a loud villager line) and random NPC chatter — verified in a Studio playtest.

Not built yet: everything past tier 2, offline earnings.

### Toolchain

- **Rojo 7** (aftman: `~/.aftman/bin/rojo.exe`). Source of truth is `default.project.json` + `src/` + `assets/`.
- After geometry/config changes: `python tools/bake_plots.py` then `rojo build -o DessertEmpire.rbxl` (or `rojo serve` + reopen/sync).
- **Do not use `Position` on BaseParts in `default.project.json`.** Rojo does not persist it — parts collapse to the origin. Always use **`CFrame`** (12-number `GetComponents()` list).
- `Workspace.$ignoreUnknownInstances = true` and `ReplicatedStorage.$ignoreUnknownInstances = true` so Studio-inserted instances (e.g. Creator Store Cashier) survive sync. Still prefer baking lasting art into the project/`assets/`.
- Rebuilding the `.rbxl` from Rojo **overwrites** the place file — export Creator Store models to `assets/` before relying on them.
- `Workspace.Sounds` (Music folder, `Minecraft Block Place`, `NPC Sounds` folder, reference SFX) lives only in the place, not the project. Code looks sounds up by name and falls back to ids in `TycoonConfig.Audio`, so a full rebuild degrades gracefully — but export them if they matter.
- No Luau analyzer/linter is in the toolchain. Agents have syntax-checked with a temp-downloaded `luau-compile` (luau-lang releases) and verified behaviour via the Roblox Studio MCP (playtest + `execute_luau`). Studio was live-syncing during that work; no local `rojo serve` process was visible, so the sync mechanism is unconfirmed.

### Rojo layout

```
src/shared/     → ReplicatedStorage.Shared
  TycoonConfig.luau   — all tunables (stations + layout helpers, plots, interact, admin, audio, sprint,
                        drop-in, cart traffic, tags, road, datastore)
  PlayerData.luau     — default save shape + sanitize (+ StandHelper → Cashier migration)
  Format.luau         — shared cash formatting ($1.5K)
  StationMath.luau    — payout / duration / upgrade cost / availablePhysical (Requires-aware) / nextUnlock
  DropParts.luau      — which parts move with a drop-in (server counts, client waits for that many)

src/server/     → ServerScriptService.Server
  init.server.luau    — join/leave order
  DataService.luau    — saves, cash, trySpend, resetProgress
  PlotService.luau    — register place plots; assign/release; spawn placement
  StandService.luau   — every unlocked station model per plot; owned-upgrade visuals (incremental, so
                        NPCs don't re-drop); floor buttons per available upgrade + next-tier unlock;
                        tags new builds DropIn / NPCs Npc
  StationService.luau — per-station sell cycle, automation, panel upgrade, walk-on upgrade + unlock
                        purchases, StationAction remote
  AdminService.luau   — AdminAction remote: ResetProgress / AddCash / AddCashLarge (Studio + creator gated)
  PhysicalButton.luau — the one purchase-button model (UpgradeId attribute)
  Hologram.luau       — purchase text holograms only (distance-gated; no far icons)
  RoadService.luau    — uses baked RoadSegments; runtime tile only if missing

src/client/     → StarterPlayer.StarterPlayerScripts.Client
  init.client.luau    — starts the modules below
  Audio.luau          — music shuffle (Workspace.Sounds.Music) + sale/upgrade/place/NPC SFX
  Hud.luau            — money display + gain popups (random X, float up, hold then fade out) + bottom-right music volume slider
  AdminHud.luau       — left-side debug buttons: +$1K, +$50K, Reset Progress (AdminEnabled only)
  StationPanel.luau   — SELL bar (countdown while running) + UPGRADE button; follows the nearest station
                        on your plot; sale/upgrade sound hooks
  Sprint.luau         — hold Left Shift to sprint (speed + FOV; TycoonConfig.Sprint)
  CartTraffic.luau    — decorative fleet carts driving off / back on each sale
  DropIn.luau         — purchased builds fall from the sky + land sound
  NpcChatter.luau     — NPCs say random voice lines

assets/
  Road.rbxmx            — exported Creator Store road template (asset id 8856361636)
  RoadSegments.rbxmx    — baked tiles along the street (from bake_plots.py)

  Cashier NPC: ReplicatedStorage.Cashier (Creator Store model in the place via
  $ignoreUnknownInstances; used by both Cashier and Cart Manager). Export to assets/
  before a full Rojo rebuild or it can be lost.

tools/bake_plots.py     — rebuilds Workspace.Plots + RoadSegments from config + Road.rbxmx
```

### Saves / data

- DataStore name: `DessertEmpire_Player_v1` (keys `player_<userId>`).
- Save shape (v2): `{ version, cash, stations[id] = { unlocked, level, owned = { [physicalUpgradeId] = true } }, lastSeen }`. Automation is derived (owns an `Automates` upgrade), not stored. v1 saves migrate in `PlayerData.sanitize` (`toolLevel` → `level`, `automated` → owns the employee).
- Failed load → session **unsaveable** (defaults for play only; never write over a real save).
- Unpublished Studio: in-memory saves so the server still boots.
- Remotes under `ReplicatedStorage.Remotes`:
  - `StationAction` — `"Sell" | "Upgrade", stationId`. Server re-checks ownership, distance, busy, affordability.
  - `AdminAction` — `"ResetProgress" | "AddCash" | "AddCashLarge"`. Server re-checks admin gate; amounts from `TycoonConfig.Admin` (`AddCashAmount` = 1000, `AddCashAmountLarge` = 50000).
- Physical upgrades and tier unlocks are walk-on (server Touched), no remote. Button attribute `Kind` = `PhysicalUpgrade` (with `UpgradeId`) or `StationUnlock` (with `StationId` = the tier being unlocked; the button is a child of the previous station's model and re-validated via `StationMath.nextUnlock`).
- Decoration markers (server sets, clients read): CollectionService tags `DropIn` (attributes `DropAt`, `DropDelay`, `DropParts`) and `Npc`; fleet cart sub-models named `Cart` with attributes `Departs` + `DepartDirection`.
- Cash / plot index via Player attributes. `AdminEnabled` marks who sees the admin HUD. `Plot` is an ObjectValue on the Player; station models are its children with a `StationId` attribute. Station state (`CycleStartedAt`/`CycleEndsAt` server time, `Payout`, `Duration`, `Level`, `UpgradeCost`, `Automated`, `SaleCount`) is attributes on the station model.

### World / plot layout (settled)

Map is a **street with plots on both sides**, not a ring. Plots expand **away from the street** (north plots → further north, south → further south).

```
Plot 1  Plot 2  Plot 3  Plot 4     ← North (Side = "North"), expand +Z
============= STREET + roads ==============
Plot 5  Plot 6  Plot 7  Plot 8     ← South (Side = "South"), expand -Z
```

Numbers live in `TycoonConfig.Plots` (keep `tools/bake_plots.py` in sync):

| Setting | Value | Notes |
| --- | --- | --- |
| Plots per side | 4 (8 total) | `Plot 1`–`4` north, `Plot 5`–`8` south |
| Pad size | **280 × 400** | Width (X) × Depth (Z); ~5× the original 56×80 starters |
| Gap between pads | 40 | |
| Street half-width | 40 | Full street depth = 80 on Z |
| Pad Y | 0.5 | Pad center; bottoms sit on grass top (Y=0) |
| Sidewalk inset | 6 | Spawn sits this far onto the street from the plot edge |
| Spawn Y | 0.75 | Pavement top (0.25) + half spawn height |
| Grass baseplate | 2048×2048, top at Y=0 | Material Grass; no separate hub grass pad |
| Hub spawn | `Plots.Street.HubSpawn` | Invisible Neutral SpawnLocation on the street |

Each plot Model: `Pad` (Part), `Spawn` (SpawnLocation on the sidewalk), `Side` (`North`/`South`).

- Players spawn on the **sidewalk** (street strip at the plot edge), facing **into** the plot (away from the street center).
- Pads are starter footprints only — not an expansion cap.
- `PlotService` **registers** place-file plots; it does not rebuild them. Change sizes / spawn → update `TycoonConfig.Plots` **and** `tools/bake_plots.py`, then rebake.

### Road (baked)

- Template: `assets/Road.rbxmx` (~80×80 slab, Creator Store / SourceAssetId `8856361636`).
- Baked copies: `assets/RoadSegments.rbxmx` → `Workspace.Plots.Street.RoadSegments` (16 tiles along X).
- Grey `Pavement` stays for collision; Transparency = 1 when roads are baked.
- `RoadService` skips tiling when baked segments exist. To change the road: replace `assets/Road.rbxmx`, run `python tools/bake_plots.py`, rebuild/sync.

### Join order / authority

- `CharacterAutoLoads` is **off**. Order: load data → assign plot → build every unlocked station (+ attach each to `StationService`) → `LoadCharacter()`. A hang before `LoadCharacter` = grey screen.
- Real per-plot `SpawnLocation` via `player.RespawnLocation`.
- Server authoritative for money/station state.

### Tier 1 config (in TycoonConfig)

- `BaseDuration = 1.5`, `BasePayout = 5`. `Upgrade = { BaseCost = 10, CostGrowth = 1.6, PayoutGrowth = 1.25 }`.
- Physical: Cooler → Freezer + Cashier in parallel → Dispenser after Freezer → Neon Sign ($150K, ×2 sales, needs Cashier + Dispenser; mounted on counter front with `{DisplayName}'s Popsicles!`) as a cooler-cart mid-game return sink. Cashier `Cost = 10000` sits next to tier-2 `UnlockCost = 10000`. Floor `ButtonOffset`s are ~1.5× the original spacing.
- Cashier visual: `ModelTemplate = "Cashier"` + cash register parts (`FaceEmployee`). Dispenser offset is the old register spot (right of counter).
- Saves migrate `owned.StandHelper` → `owned.Cashier`. (Tier 2's `CartCrew` → `CartManager` rename had no migration — it shipped unplayed.)
- `TycoonConfig.StationStreetInset = 10`: the stand counter sits 10 studs in from the plot's street edge; all station-space offsets are relative to it.
- Admin: `TycoonConfig.Admin = { AddCashAmount = 1000, AddCashAmountLarge = 50000, UserIds = {} }`.

## Unverified / open

- Automated stations keep the full panel (bar shows countdown while running, else `AUTO`) because UPGRADE still lives there. Revisit if it feels cluttered.
- Pacing: tier 1 is fully bought by ~2.7 min in the sim — likely too fast. The sim (an ad-hoc script, not in `tools/`) doesn't include the Neon Sign; re-run before trusting tier-2 minute marks or retuning.
- Nothing past tier 2 is designed in **numbers** yet (tier 3 Ice Cream Truck is a placeholder with `UnlockCost = 40000` matching Cart Manager, no `Placement`, no physical upgrades). Flavor roadmap for tiers 3–6 lives under **Tier ladder** — costs / unlocks TBD when each tier is built.
- Tier 2 has been played in Studio (unlock, purchases), and drop-in + landing sounds were verified in a playtest, but the parking lot geometry, cart traffic and Cart Manager desk haven't been deliberately checked on both North and South plots.
- Door-open purchase sound + block-place landing sound both play on physical purchases. Keep, or mute the door sound for physical buys?
- Cart traffic is owner-client only; other players see parked carts. Drop-ins and NPC chatter are visible/audible to everyone.
- Plot pads are Plastic/Studs placeholders — boardwalk art later.
- Road tile seams / exact Y if the Creator Store mesh is replaced.
- `ReplicatedStorage.Cashier` is not baked into `assets/` yet — a full Rojo rebuild can drop it unless exported first.
- Admin tools are temporary debug UI; remove or tighten before ship.

---

## How to help me

- Be concrete and implementation-oriented.
- Flag balance or scope problems early. Call out when something is 3x the engineering I think it is.
- When you change a number that interacts with a design rule (automation cost vs. next-tier unlock), say so explicitly.
- When changing plot/street sizes, update `TycoonConfig.Plots` **and** `tools/bake_plots.py`, then rebake.
- Review your own output before handing it over, and tell me what you found.
- Don't state my project structure or toolchain as established fact unless I've confirmed it. Say what the code assumes, and ask.
