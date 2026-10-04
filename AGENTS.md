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
3. **Employee** — physical upgrade with `Automates = true`: the bar clicks itself forever. On tier 1 it unlocks with Deep Freezer (after Bigger Cooler), via `Requires = { "BiggerCooler" }`.
4. **Next tier unlock** — opens the next station (not built yet).

## Core design rules (settled, don't re-propose alternatives)

- **Every station is manual first.** The player clicks it themselves; the employee automates it.
- **Every station follows the spend flow above.** Panel upgrade + physical upgrades (ordered unless `Requires` says otherwise) including an employee. Don't invent per-station mechanics.
- **The panel upgrade is payout only.** Speed comes only from physical upgrades, so each lever has one obvious source.
- **Keep `CostGrowth` well above `PayoutGrowth`.** At ×1.35 cost vs ×1.25 payout, a simulated player hit $2.7K/s by automation and made tier 2 trivial. ×1.6 is the current tested value — re-simulate before changing either.
- Employee cost for a tier ≈ unlock cost of the next tier. Keep those two numbers adjacent in the config so the rule is checkable at a glance.
- Physical upgrades add visible models to the plot. Progress must be legible from the plot entrance without opening any UI. (Panel upgrade levels are not visible on the plot — they're the small, frequent sink.)
- Earlier tiers never become dead content — once automated they keep paying forever.
- **No loss mechanics.** No spoilage, decay, failure, or anything that can take money or progress away.
- Players don't leave the plot to progress. Off-plot is for foraging rare ingredients, a trading hub, and seasonal events only.
- All progression numbers live in one shared config module. No magic numbers in systems code.
- **Server is authoritative** for all money and station state. Clients send requests only; the server independently re-validates ownership, distance, cooldown, and affordability on every one. An automated station's timer runs on the server, not in the client's bar.
- **No far-away `$` icon** over the stand. Purchase text holograms are distance-gated; the far marker was cut.

## Simplicity rules (learned the hard way)

- Prefer the simplest version that's still fun. If a mechanic needs tracked state the player can get stuck behind, cut it and assume it instead.
- If a proposed feature isn't "a button, a bar, and a payout," it probably doesn't belong. Say so before building it.
- Placeholder art is plain `Part`s, `Material = Plastic`, all six surfaces `Studs`. No meshes/textures for placeholders. Chosen Creator Store art (like the street road) is exported into `assets/` and baked — not left as a loose Studio-only insert.
- Prefer engine built-in assets (`rbxasset://`) over Creator Store IDs when a simple Part will do. A wrong Creator Store ID fails silently.
- Every `WaitForChild` gets a timeout and an `assert` naming the instance. A bare `WaitForChild` turns a typo into a silent server freeze.
- Replicate state to clients via **Player attributes** where possible, not RemoteEvents. Attributes replicate automatically and can't desync. Add remotes only when the client needs to *request* something.

## Tier ladder

popsicle stand → cooler cart → ice cream truck → parlor → dessert factory → loading dock → second wing / prestige

Each is one station, following the model above, with a bigger payout than the last. The flavor per tier (a cart, a truck with a jingle, seated tables, a factory line, grocery semis) is visual identity and may act as a flat income multiplier. It is never a simulation.

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
| 4 | Stand Helper | $10,000 | automates | Creator Store `Cashier` NPC behind counter + register on counter center facing employee | after Cooler (`Requires = { "BiggerCooler" }`, same time as Freezer) |

Stand Helper arrival: clones `ReplicatedStorage.Cashier`, drops from ~12 studs, then snaps feet-to-pad and freezes (anchored prop, no nameplates). Cash register uses `FaceEmployee`; cashier uses `FaceStreet`.

Simulated pacing (player clicks every cycle, buys as soon as affordable) was last run at **BaseDuration = 3** — re-simulate after the 1.5s change before trusting those minutes. Tier 2 unlock is $10,000 to match the Helper.

What it does not have, on purpose: mold trays, pouring, stock, customer arrivals, queues, ProximityPrompts, floating status text, far-away `$` stand icon. All were tried and cut.

## Current implementation state

Working:
- Rojo module layout + place geometry bake
- Player save schema + DataStore load/save with retries (in-memory fallback when DataStores unavailable in unpublished Studio)
- Street plot pads in the place file; plot assignment + runtime stand population
- Join-order skeleton (`CharacterAutoLoads` off)
- Placeholder popsicle stand on claim; vacant pads are grass, claimed pads flip to boardwalk
- Creator Store road tiled and **baked** into the place (`Workspace.Plots.Street.RoadSegments`)
- Tier 1 loop: client station panel (SELL countdown bar + UPGRADE) → server-run cycle → payout; employee restarts the cycle on the server
- Walk-on purchase buttons (cyan = affordable, orange = not) + distance-gated text holograms; one button per `StationMath.availablePhysical` offer
- Stand Helper parallel unlock with Deep Freezer; Pop Dispenser still sequential after Freezer
- Money HUD (Cash attribute) with +$ gain popups; positional sale sound
- Temporary admin HUD (left side): `+$1K` and **Reset Progress** — Studio always; live = place CreatorId + `TycoonConfig.Admin.UserIds`. Server re-checks; sets `AdminEnabled` attribute.

Not built yet: everything past tier 1, offline earnings, real cha-ching / music audio ids (`TycoonConfig.Audio`).

### Toolchain

- **Rojo 7** (aftman: `~/.aftman/bin/rojo.exe`). Source of truth is `default.project.json` + `src/` + `assets/`.
- After geometry/config changes: `python tools/bake_plots.py` then `rojo build -o DessertEmpire.rbxl` (or `rojo serve` + reopen/sync).
- **Do not use `Position` on BaseParts in `default.project.json`.** Rojo does not persist it — parts collapse to the origin. Always use **`CFrame`** (12-number `GetComponents()` list).
- `Workspace.$ignoreUnknownInstances = true` and `ReplicatedStorage.$ignoreUnknownInstances = true` so Studio-inserted instances (e.g. Creator Store Cashier) survive sync. Still prefer baking lasting art into the project/`assets/`.
- Rebuilding the `.rbxl` from Rojo **overwrites** the place file — export Creator Store models to `assets/` before relying on them.

### Rojo layout

```
src/shared/     → ReplicatedStorage.Shared
  TycoonConfig.luau   — all tunables (plots, stations, interact, admin, audio, road, datastore)
  PlayerData.luau     — default save shape + sanitize
  Format.luau         — shared cash formatting ($1.5K)
  StationMath.luau    — payout / duration / upgrade cost / availablePhysical (Requires-aware)

src/server/     → ServerScriptService.Server
  init.server.luau    — join/leave order
  DataService.luau    — saves, cash, trySpend, resetProgress
  PlotService.luau    — register place plots; assign/release; spawn placement
  StandService.luau   — stand model + owned-upgrade visuals + floor buttons per available upgrade
  StationService.luau — sell cycle, automation, panel upgrade, walk-on purchases, StationAction remote
  AdminService.luau   — AdminAction remote: ResetProgress / AddCash (Studio + creator gated)
  PhysicalButton.luau — the one purchase-button model (UpgradeId attribute)
  Hologram.luau       — purchase text holograms only (distance-gated; no far icons)
  RoadService.luau    — uses baked RoadSegments; runtime tile only if missing

src/client/     → StarterPlayer.StarterPlayerScripts.Client
  init.client.luau    — starts the modules below
  Hud.luau            — money display
  AdminHud.luau       — left-side debug buttons (AdminEnabled only)
  StationPanel.luau   — SELL bar (countdown while running) + UPGRADE button
  Audio.luau          — music + sale sound (warns on failed loads)

assets/
  Road.rbxmx            — exported Creator Store road template (asset id 8856361636)
  RoadSegments.rbxmx    — baked tiles along the street (from bake_plots.py)

  Stand Helper NPC: ReplicatedStorage.Cashier (Creator Store model in the place via
  $ignoreUnknownInstances). Export to assets/ before a full Rojo rebuild or it can be lost.

tools/bake_plots.py     — rebuilds Workspace.Plots + RoadSegments from config + Road.rbxmx
```

### Saves / data

- DataStore name: `DessertEmpire_Player_v1` (keys `player_<userId>`).
- Save shape (v2): `{ version, cash, stations[id] = { unlocked, level, owned = { [physicalUpgradeId] = true } }, lastSeen }`. Automation is derived (owns an `Automates` upgrade), not stored. v1 saves migrate in `PlayerData.sanitize` (`toolLevel` → `level`, `automated` → owns the employee).
- Failed load → session **unsaveable** (defaults for play only; never write over a real save).
- Unpublished Studio: in-memory saves so the server still boots.
- Remotes under `ReplicatedStorage.Remotes`:
  - `StationAction` — `"Sell" | "Upgrade", stationId`. Server re-checks ownership, distance, busy, affordability.
  - `AdminAction` — `"ResetProgress" | "AddCash"`. Server re-checks admin gate; AddCash uses `TycoonConfig.Admin.AddCashAmount` (1000).
- Physical upgrades are walk-on (server Touched), no remote. Button attribute `UpgradeId` selects which available upgrade to buy.
- Cash / plot index via Player attributes. `AdminEnabled` marks who sees the admin HUD. `Plot` + `Station` are ObjectValues on the Player. Station state (`CycleStartedAt`/`CycleEndsAt` server time, `Payout`, `Duration`, `Level`, `UpgradeCost`, `Automated`, `SaleCount`) is attributes on the station model.

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
| Grass baseplate | 2048×2048, top at Y=0 | Material Grass; no separate hub grass pad |
| Hub spawn | `Plots.Street.HubSpawn` | Invisible Neutral SpawnLocation on the street |

Each plot Model: `Pad` (Part), `Spawn` (SpawnLocation at street edge, disabled until owned), `Side` (`North`/`South`).

- Players spawn at the **street edge**, facing **into** the plot (away from the street).
- Pads are starter footprints only — not an expansion cap.
- `PlotService` **registers** place-file plots; it does not rebuild them. Change sizes → rebake.

### Road (baked)

- Template: `assets/Road.rbxmx` (~80×80 slab, Creator Store / SourceAssetId `8856361636`).
- Baked copies: `assets/RoadSegments.rbxmx` → `Workspace.Plots.Street.RoadSegments` (16 tiles along X).
- Grey `Pavement` stays for collision; Transparency = 1 when roads are baked.
- `RoadService` skips tiling when baked segments exist. To change the road: replace `assets/Road.rbxmx`, run `python tools/bake_plots.py`, rebuild/sync.

### Join order / authority

- `CharacterAutoLoads` is **off**. Order: load data → assign plot → build stand → `LoadCharacter()`. A hang before `LoadCharacter` = grey screen.
- Real per-plot `SpawnLocation` via `player.RespawnLocation`.
- Server authoritative for money/station state.

### Tier 1 config (in TycoonConfig)

- `BaseDuration = 1.5`, `BasePayout = 5`. `Upgrade = { BaseCost = 10, CostGrowth = 1.6, PayoutGrowth = 1.25 }`.
- Physical: Cooler → Freezer + Helper in parallel (`StandHelper.Requires = { "BiggerCooler" }`) → Dispenser after Freezer. Helper `Cost = 10000` sits next to placeholder tier-2 `UnlockCost = 10000`.
- Stand Helper visual: `ModelTemplate = "Cashier"` + cash register parts (`FaceEmployee`). Dispenser offset is the old register spot (right of counter).
- Admin: `TycoonConfig.Admin = { AddCashAmount = 1000, UserIds = {} }`.

## Unverified / open

- Automated stations keep the full panel (bar shows countdown while running, else `AUTO`) because UPGRADE still lives there. Revisit if it feels cluttered.
- Pacing numbers are stale after `BaseDuration` 3 → 1.5 and after Helper unlocking with Freezer — re-simulate before trusting old minute marks.
- Nothing past tier 1 is designed in numbers yet (tier 2 is a placeholder with `UnlockCost = 10000` and no physical upgrades).
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
