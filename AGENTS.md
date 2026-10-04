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
2. **Physical upgrades** — walk-on floor buttons next to the station. Default unlock is in list order; an upgrade can set `Requires = { ids }` to appear earlier/in parallel. Each available upgrade gets its own button. Each adds a visible model and one big effect: `PayoutMultiplier` (e.g. ×2, ×3) or `SpeedMultiplier` (e.g. ×2 sell speed, which halves duration). The one exception is a **gate step** (below).
   - **Gate steps** — cheap physical upgrades with *no* income effect that prepare the ground for a later tier (Parking Lot → Cooler Cart, Ice Cream Truck Lot → Ice Cream Truck, Parlor Land → Parlor). The next tier's `UnlockRequires` lists the gate step, so it's a required stop, priced low (≈ ¼ of the tier it opens) so it never feels like a wall. Hologram subtitle is `Subtitle` if set, else "unlocks {next tier}".
3. **Employee** — physical upgrade with `Automates = true`: the bar clicks itself forever. It unlocks partway down the list, not last: tier 1 Cashier with Deep Freezer (`Requires = { "BiggerCooler" }`), tier 2 Cart Manager as soon as the Cooler Cart exists (`Requires = {}`, same time as Second Cart).
4. **Next tier unlock** — a floor button owned by the current station but placed on the spot where the next station will stand (`Placement`). It appears once the current station owns every id in the next station's `UnlockRequires`, so the next tier's path is visible *before* the employee is bought. Buying it builds the next station.

## Core design rules (settled, don't re-propose alternatives)

- **Always a next upgrade within reach.** At every point the player should see at least one floor button they can afford soon — no long dead stretches saving for one big buy. When a gap opens between prices, fill it with a bite-sized physical step (or a gate step for the next tier) rather than lowering the big price.
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
- **Things only exist once bought.** No pre-built empty slots, lots or outlines: an upgrade's whole visual (including its ground, e.g. the Parking Lot's asphalt) appears on purchase. Before that, only its floor button is there, standing where the thing will appear.
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
| 1 | Popsicle stand | **Built** | Cooler → Freezer + Cashier → Dispenser → Neon Sign; gate steps Parking Lot (tier 2) and Parlor Land (tier 4) |
| 2 | Cooler cart | **Built** | Fleet carts + Cart Manager on the Parking Lot; gate steps Ice Cream Truck Lot + Old Truck (tier 3) |
| 3 | Ice cream truck | **Built** | Old Truck fixed up piece by piece: paint → tires + Driver → serving window → speakers → menu board → giant cone → string lights. Stands on the Ice Cream Truck Lot. |
| 4 | Parlor | Placeholder (`UnlockCost` only); land built (stand gate step) | Builds on Parlor Land, right of the stand. Toppings bar, booths, second floor, décor/signage, marketing bits (sandwich board, awning, posters); **employees** automate. Build the room in steps (foundation / walls / roof / interior) before stuffing it with amenities. |
| 5 | Dessert factory | Not started | **Build piece by piece:** 1. frame, 2. walls, 3. roof, then industrial freezer, industrial packager, second conveyor belt, packing station, etc. One station, many bite-sized buys — the building grows on the plot. |
| 6 | Loading dock | Not started | Connected to the factory. Dock bay / canopy / ramp as separate steps; semi trucks that pull in (decoration, like cart traffic); more bays or fleet trucks as payout/speed ups; a dock worker / dispatcher automates. |
| 7+ | Second wing / prestige | Not started | Later. Prestige is a supporting system, not a station mechanic change. |

Tiers 4–6 are direction only: upgrade names and build order will get real costs / `Requires` / placements when we design each tier. Until then, don't invent numbers in systems code.

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
| 6 | Parking Lot | $2,500 | none (gate step: Cooler Cart `UnlockRequires`) | asphalt left of the stand, stand-space X −56…−16, sidewalk (Z −10) back to Z 30; back planter + bushes, right curb, two street lamps, blue `PARKING` sign; button at lot center (−36, 10) | after Cooler (`Requires = { "BiggerCooler" }`) |
| 7 | Parlor Land | $25,000 | none (gate step for tier 4, `Subtitle = "parlor coming soon"`) | roped-off dirt lot right of the stand, X 16…60, Z −10…30; corner stakes, lumber pile, `{Player}'s Parlor - Coming Soon` sign; button at (38, 10) | after Cashier (`Requires = { "Cashier" }`) — fills the $10K→$40K gap at tier 2 start |

Cashier arrival: clones `ReplicatedStorage.Cashier` as an anchored prop (no nameplates, no physics), feet on the pad; it drops in like every other purchase (below), landing just after its register. Cash register uses `FaceEmployee`; NPC faces the street.

**Drop-in (all tiers):** every physical-upgrade visual and every newly unlocked station falls from the sky on purchase (40 studs, ~0.55s fall + small hop), then plays `Workspace.Sounds["Minecraft Block Place"]`. NPCs land ~0.35s after their props and play the block sound plus a louder random `Workspace.Sounds["NPC Sounds"]` line (`NpcPurchaseVolume`). Server places things at their final spot and tags them (`TycoonConfig.Tags.DropIn` + `DropAt` server time + `DropParts` part count); `client/DropIn.luau` animates locally for every player, timed off server time. The tag can reach the client before the model's children, so the client waits (≤ `ReplicationWait`) until `DropParts` parts have arrived, lifting each out of sight as it shows up — without this, drops and landing sounds silently didn't happen. `shared/DropParts.luau` is the one rule for which parts move (skips nested drop-ins like the NPC, and purchase buttons). Not on join/rebuild. NPCs (tag `Npc`) also say a random NPC line every 8–20s (`client/NpcChatter.luau`). Numbers: `TycoonConfig.DropIn`, `TycoonConfig.Audio.Place*` / `Npc*` (sound ids there are fallbacks if the place copies are missing).

Neon Sign is intentional dead-content prevention: the button shows once the early stand is complete, but $150K sits between cooler-cart Second ($40K) and Third ($200K), so players duck back to the stand after a bit of cart progress. Visual parts use `FaceStreet`; the neon face sets `Label = "{Player}'s Popsicles!"` (substituted with `player.DisplayName` in `StandService`).

Simulated pacing (`tools/pacing_sim.luau`, greedy player, no walking — see Unverified / open): Cooler 0.8 min, Freezer 1.8, Parking Lot 2.1, Dispenser 2.5, Cooler Cart 2.9, Cashier 3.3. Tier 2 unlock is $10,000 to match the Cashier.

What it does not have, on purpose: mold trays, pouring, stock, customer arrivals, queues, ProximityPrompts, floating status text, far-away `$` stand icon. All were tried and cut.

## Tier 2 — cooler cart

One cooler cart left of the popsicle stand (when facing the road), on the Parking Lot (tier 1 gate step), with three fleet spots further left that fill with carts — a fleet of four. Parked carts are rotated nose-to-street; every cart has four corner wheels. Click SELL (on the first cart), a **4-second** bar runs, it pays $150. UPGRADE starts at $300 (×1.6 cost / ×1.25 payout, same as tier 1).

Unlock: a $10,000 floor button on the cart's spot, shown once the stand owns the Parking Lot (`UnlockRequires = { "ParkingLot" }`; the lot itself needs Bigger Cooler), so the tier 2 path is still visible before automating tier 1. The Parking Lot paves the whole area; each fleet cart upgrade adds its cart plus that spot's painted lines.

| # | Upgrade | Cost | Effect | Visual / button | Unlock |
| --- | --- | --- | --- | --- | --- |
| 1 | Second Cart | $40,000 | ×2 sales | parks in lot spot 1; button on that spot | start |
| 2 | Cart Manager | $40,000 | automates | desk (clipboard, sign) right of the first cart + `Cashier` NPC behind it; button on the desk spot | start (`Requires = {}`, same time as Second) |
| 3 | Third Cart | $200,000 | ×2 sell speed | lot spot 2 | after Second |
| 4 | Fourth Cart | $1,000,000 | ×3 sales | lot spot 3 | after Third |
| 5 | Ice Cream Truck Lot | $10,000 | none (gate step, `Subtitle = "trucks coming soon"`) | second asphalt section extending the Parking Lot left, stand-space X −100…−56, same depth, same planter/lamps, left curb, `TRUCKS` sign; button at its center | after Second (`Requires = { "SecondCart" }`, so tier 2 is played before the truck path opens) |
| 6 | Old Truck | $15,000 | none (gate step: Ice Cream Truck `UnlockRequires`, `Subtitle = "fixer-upper"`) | rusty faded truck on the Truck Lot: body, cab, grimy windshield, dark empty window, rust patches, four flat tires; button where it will stand | after Truck Lot |

Layout (station space, X across with −X = left facing the road, Z away from the street): first cart at `Placement = (-26, 0.2, 0)` from the stand counter (lifted onto the 0.2-stud asphalt, so cart-relative Y 0 = asphalt top), serving with its long side along the street. Lot spots at cart-relative X −8 / −16 / −24, 8 wide; parked carts sit at Z 1.5; spot lines run Z −2…6. Manager desk at X +6. Cart Manager reuses the `ReplicatedStorage.Cashier` model. Lot sizes / colours are the `LOT_*`, `PARKING_LOT`, `TRUCK_LOT`, `PARLOR_LAND` locals at the top of `TycoonConfig`.

Cart Manager cost = tier-3 Ice Cream Truck `UnlockCost = 40000` (`UnlockRequires = { "OldTruck" }`).

Cart traffic (decoration only, `client/CartTraffic.luau`, numbers in `TycoonConfig.CartTraffic`): each tier-2 sale sends one parked fleet cart (`Visual.DepartingParts`, built as a `Cart` sub-model tagged `Departs` so the asphalt stays put) up its driveway toward the sidewalk while fading out, then it fades back in and rolls into its spot (~3.4s). Round-robin, max one cart away at a time (`MaxAway`) so the fleet stays readable from the plot entrance. Animated only on the owner's client; carts still dropping in are skipped.

## Tier 3 — ice cream truck

The Old Truck (cooler-cart gate step) gets fixed up into a working ice cream truck, parked **nose-to-street** (18 long × 8 wide, ~10 tall; serving window on the side facing the parking lot). Unlock ($40,000, button where the kiosk will stand) opens a little order **kiosk** beside the truck: pink counter (the station `Counter`, so the SELL panel lives here) with an umbrella, a freezer and a cardboard `OPEN` sign. The kiosk never moves; the truck drives off and comes back. Sells manually right away. Click SELL, a **6-second** bar runs, it pays $2,000. UPGRADE starts at $4,000 (×1.6 / ×1.25).

| # | Upgrade | Cost | Effect | Visual (covers / adds) | Unlock |
| --- | --- | --- | --- | --- | --- |
| 1 | Fresh Paint | $60,000 | ×1.5 sales | cream body shell + pink cab (lower, roof, pillars) + pink stripe over the rusty body | start |
| 2 | New Tires | $120,000 | ×1.5 sales | four tires + hubcaps over the flats | after Paint |
| 3 | Driver | $200,000 | automates | `Cashier` NPC standing in the cab behind the wheel, visible through the open window band; rides along when the truck drives off | after Paint (`Requires = { "FreshPaint" }`, with Tires) |
| 4 | Serving Window | $400,000 | ×2 sell speed | pink window frame + dark opening + striped awning on the kiosk side | after Tires (`Requires`) |
| 5 | Jingle Speakers | $800,000 | ×1.5 sales | roof rack + two horn speakers facing the street | after Window |
| 6 | Menu Board | $1,500,000 | ×1.5 sales | `MENU` board on the kiosk front, over the cardboard OPEN sign (stays when the truck leaves) | after Speakers |
| 7 | Giant Cone | $3,000,000 | ×2 sales | cone + two scoops + cherry on the roof | after Menu |
| 8 | String Lights | $6,000,000 | ×2 sales | bulb strands along both roof edges | after Cone |

Full multiplier stack ×40.5 (tier 1 ×24, tier 2 ×12). Driver cost = placeholder tier-4 Parlor `UnlockCost = 200000` (`UnlockRequires = { "Driver" }`, no `Placement`).

Geometry is in **truck space** (`TRUCK_ORIGIN` = footprint center on the asphalt at stand-space (−84, 0.2, 2); X across, serving window on +X; Z along the truck, cab/nose at −Z toward the street). The kiosk is `TRUCK_COUNTER` = (9, 0, 4) in truck space; `TRUCK_PLACEMENT` = origin + kiosk. `truckPart(owner, …)` converts to offsets relative to the owning station (cooler cart for the Old Truck, the kiosk for everything else). **Fix-ups never delete old parts**: each new piece fully contains the shabby one it replaces (paint shell 0.1–0.2 larger than each body/cab piece, tires larger than the flats, menu board around the OPEN sign). Parts that must stay visible through the paint (grille, window hole) poke past the shell. Keep that containment when moving anything.

Truck traffic (decoration, same `client/CartTraffic.luau`): every truck piece (`truckVisual(...)` = `DepartingParts` + `Depart = TRUCK_DEPART`; the Driver NPC via `Visual.Depart`) carries `DepartGroup = "Truck"`, `DepartStation = "IceCreamTruck"`, `DepartDistance = 22`, `DepartCooldown = 15`. CartTraffic groups models by `DepartGroup` (per plot) and moves them as one vehicle on that station's sales — so the Old Truck, owned by the cooler cart, rides with the truck's sales and never with the cart's. Cooldown = at most one trip per 15 s so the lone truck is parked most of the time. Verified in a playtest: leaves every ~15 s, 22 studs, driver rides along, kiosk stays.

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
- Multiple stations per plot: `TycoonConfig.Stations[i].Placement` positions each station; tiers 2–3 built (unlock button lives on the previous station, at the next station's `Placement`). Client panel follows the nearest station within range (one panel, never two overlapping).
- Tier 2: cooler cart, fleet spots on the Parking Lot, Cart Manager desk, decorative cart traffic.
- Gate steps: Parking Lot (stand, gates tier 2), Ice Cream Truck Lot (cart, gates tier 3), Parlor Land (stand, for tier 4). Purchases + drop-ins verified in a Studio playtest on a North plot. `PlayerData.sanitize` grants a tier's `UnlockRequires` on the previous station when that tier is already unlocked (old saves get the Parking Lot).
- Drop-in on every purchase (block-place sound; NPCs add a loud villager line) and random NPC chatter — verified in a Studio playtest.

- Tier 3: Old Truck gate step + Ice Cream Truck station with 8 fix-up upgrades; every purchase verified in a Studio playtest (North plot), bare Old Truck and fully upgraded truck screenshotted.

Not built yet: everything past tier 3, offline earnings.

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
  CartTraffic.luau    — decorative fleet carts / the ice cream truck driving off and back on sales
  DropIn.luau         — purchased builds fall from the sky + land sound
  NpcChatter.luau     — NPCs say random voice lines

assets/
  Road.rbxmx            — exported Creator Store road template (asset id 8856361636)
  RoadSegments.rbxmx    — baked tiles along the street (from bake_plots.py)

  Cashier NPC: ReplicatedStorage.Cashier (Creator Store model in the place via
  $ignoreUnknownInstances; used by both Cashier and Cart Manager). Export to assets/
  before a full Rojo rebuild or it can be lost.

tools/bake_plots.py     — rebuilds Workspace.Plots + RoadSegments from config + Road.rbxmx
tools/pacing_sim.luau   — greedy-player pacing sim; paste into Studio (Edit) — reads live Shared config
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
- Decoration markers (server sets, clients read): CollectionService tags `DropIn` (attributes `DropAt`, `DropDelay`, `DropParts`) and `Npc`; departing sub-models named `Cart` (and the truck Driver NPC) with attributes `Departs` + `DepartDirection`, plus optional `DepartGroup` / `DepartStation` / `DepartDistance` / `DepartCooldown` (from `Visual.Depart`).
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
- Nothing past tier 3 is designed in **numbers** yet (tier 4 Parlor is a placeholder with `UnlockCost = 200000` matching the Driver, no `Placement`, no physical upgrades). Flavor roadmap for tiers 4–6 lives under **Tier ladder**.
- **Pacing runs away (whole economy, not tier 3 specifically).** `tools/pacing_sim.luau` (run in Studio Edit mode; it requires the live `Shared` modules) has a greedy player finish all of tiers 1–3 in ~16 min at ~$590K/s. The driver is panel levels: by the end tier 1 is L29 (×646 payout), cart L22, truck L16 — each station's panel cost doesn't scale with *total* income, so later stations fund cheap early panel levels. Real players walk and won't play optimally, but this still needs a deliberate retune (panel cost growth, base costs, or tier payouts) before tier 4.
- Tier 4 unlock is linear (`nextUnlock` = the *truck* offers the Parlor), but the Parlor's ground is the *stand's* Parlor Land. When building tier 4, either the truck's unlock should also check `PopsicleStand.owned.ParlorLand` (cross-station requires) or Parlor Land should be the first Parlor upgrade.
- Tier 2 has been played in Studio (unlock, purchases), and drop-in + landing sounds were verified in a playtest, but the parking lot geometry, cart traffic and Cart Manager desk haven't been deliberately checked on both North and South plots.
- Gate steps (Parking Lot, Ice Cream Truck Lot, Parlor Land) are only checked on a North plot. "Right of the stand" uses the project convention (+X = right when *facing the road*), so from the sidewalk spawn, looking into the plot, Parlor Land appears on the **left**; flip `PARLOR_LAND` if the opposite was meant.
- Pacing with gate steps is unsimulated: the Parking Lot adds a $2.5K stop before the $10K cart unlock; Parlor Land ($25K) and the Ice Cream Truck Lot ($10K) are zero-income buys in the early tier-2 window. Tier 2 still jumps $200K → $1M with nothing in between once the Neon Sign is bought.
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
