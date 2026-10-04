# Project: Dessert Empire — Roblox tycoon

I'm building a Roblox tycoon game in Roblox Studio. This is my first project of this size. Assume nothing about my project structure or toolchain unless I've told you — ask, or have me check in Studio.

**The game:** You start with a popsicle stand in a vacant boardwalk kiosk and build it into a dessert park. Everything happens on the player's own plot.

## The station model (this is the whole game)

Every tier is the same mechanic. There is exactly one mechanic in Dessert Empire and it is this:

1. Player walks up to a station. A floating panel fades in.
2. Player clicks the button on it.
3. An animated progress bar runs for N seconds.
4. The bar completes and pays $X.

Automation means the button clicks itself the instant the bar completes. The bar then runs forever and pays $X every N seconds without the player. It is off-cooldown for one frame, so an automated station and a manual one are the same object in the same state loop — automation is a boolean, not a second system.

**A station has exactly two numbers: payout and duration.** Income is payout ÷ duration. Nothing else feeds it. No arrival rate, no demand, no queue, no stock, no inventory, no spoilage. Customers are decoration and never touch income.

Each new tier is a new station with a bigger payout, sitting alongside the old ones. Automated earlier stations keep paying, so total income is the sum of every automated station's rate. That is the entire economy.

## Core design rules (settled, don't re-propose alternatives)

- **Every station is manual first.** The player clicks it themselves, then pays to automate it.
- **Two spend sinks per tier, always.** The *tool* upgrade improves the station you're on. The *building* unlock opens the next tier's station.
- **Pick one lever per tier for the tool upgrade** — either payout or duration, not both. Mathematically they're interchangeable (both scale payout ÷ duration), so using both just makes the numbers harder to reason about. Payout is the clearer one to show on a button.
- Automation cost for a tier ≈ unlock cost of the next tier. Keep those two numbers adjacent in the config so the rule is checkable at a glance.
- Upgrades add visible models to the plot. Progress must be legible from the plot entrance without opening any UI.
- Earlier tiers never become dead content — once automated they keep paying forever.
- **No loss mechanics.** No spoilage, decay, failure, or anything that can take money or progress away.
- Players don't leave the plot to progress. Off-plot is for foraging rare ingredients, a trading hub, and seasonal events only.
- All progression numbers live in one shared config module. No magic numbers in systems code.
- **Server is authoritative** for all money and station state. Clients send requests only; the server independently re-validates ownership, distance, cooldown, and affordability on every one. An automated station's timer runs on the server, not in the client's bar.

## Simplicity rules (learned the hard way)

- Prefer the simplest version that's still fun. If a mechanic needs tracked state the player can get stuck behind, cut it and assume it instead.
- If a proposed feature isn't "a button, a bar, and a payout," it probably doesn't belong. Say so before building it.
- Placeholder art is plain `Part`s, `Material = Plastic`, all six surfaces `Studs`. No meshes, textures, or Toolbox models.
- Prefer engine built-in assets (`rbxasset://`) over Creator Store IDs. A wrong Creator Store ID fails silently.
- Every `WaitForChild` gets a timeout and an `assert` naming the instance. A bare `WaitForChild` turns a typo into a silent server freeze.
- Replicate state to clients via **Player attributes** where possible, not RemoteEvents. Attributes replicate automatically and can't desync. Add remotes only when the client needs to *request* something.

## Tier ladder

popsicle stand → cooler cart → ice cream truck → parlor → dessert factory → loading dock → second wing / prestige

Each is one station, following the model above, with a bigger payout than the last. The flavor per tier (a cart, a truck with a jingle, seated tables, a factory line, grocery semis) is visual identity and may act as a flat income multiplier. It is never a simulation.

## Supporting systems (not built yet)

- **Flavors** as the collection layer: fruit pops → ice cream → gelato → novelty, with rares and seasonals.
- **Weather and time of day** as flat income multipliers.
- **Offline earnings** — trivially computable under this model: for each automated station, elapsed time ÷ duration × payout.
- **Prestige.**

---

## Tier 1 — popsicle stand

The canonical station. Click SELL, a 3-second bar runs, it pays $5. The tool upgrade ("Bigger Cooler") raises payout and stacks a visible crate per level. Automating it makes the bar run on its own forever, and costs about what tier 2 costs to unlock.

What it does not have, on purpose: mold trays, pouring, stock, customer arrivals, queues, ProximityPrompts, floating status text. All were tried and cut.

## Current implementation state

Working: Rojo module layout, player save schema + DataStore load/save with retries (in-memory fallback when DataStores are unavailable in unpublished Studio), street plot pads in the place file, plot assignment / runtime population, join-order skeleton, placeholder popsicle stand model on claim.

Not built yet: manual sell loop, floating station panel, tool upgrade spending, automation, everything past tier 1.

### Rojo layout (source of truth)

```
src/shared/     → ReplicatedStorage.Shared
  TycoonConfig.luau
  PlayerData.luau

src/server/     → ServerScriptService.Server  (Script + ModuleScript children)
  init.server.luau   — join/leave order
  DataService.luau
  PlotService.luau
  StandService.luau

src/client/     → StarterPlayer.StarterPlayerScripts.Client
  init.client.luau   — cash attribute listener stub (HUD later)
```

DataStore name: `DessertEmpire_Player_v1` (keys `player_<userId>`). Unpublished Studio playtests fall back to in-memory saves so the server still boots.

Remotes: none yet. Cash / plot index replicate via Player attributes. Plot + Station are ObjectValues on the Player.

### Plot layout

- Hub is just the street (no grassy spawn pad). World `Baseplate` is Grass.
- A street runs east–west through the center.
- **4 plots north, 4 south** (`Plot 1`–`4` north, `Plot 5`–`8` south) live in the place file under `Workspace.Plots` (empty pads, **280×400** each). Runtime only registers them and populates ownership / stands — it does not rebuild geometry.
- Each plot is a Model with `Pad`, street-edge `Spawn`, and `Side` (`North`/`South`).
- Players spawn at the street edge looking **into** the plot (away from the street), so the plot can expand “backwards” forever.
- Plot pads are starter footprints only — not the expansion limit.
- Re-bake pads from config with `python tools/bake_plots.py` if you change plot sizes.

Key implementation decisions:

- `CharacterAutoLoads` is **off** (project + server). Join order is load data → assign plot → build station → `LoadCharacter()`. A hang anywhere before `LoadCharacter` leaves the player on a grey screen unable to move.
- Spawning uses a real `SpawnLocation` per plot (`player.RespawnLocation`), not a post-hoc teleport.
- A failed data load marks the session **unsaveable** rather than writing defaults over a real save.
- The client finds its station through an `ObjectValue` the server sets on the Player, not by scanning Workspace.

## Unverified / open

- Whether an automated station should keep its panel visible, show a simplified running bar, or hide entirely.
- Nothing past tier 1 is designed in numbers yet (tier 2 unlock is a placeholder `500` so automation≈next-unlock stays checkable).
- Plot pads are Plastic/Studs placeholders — boardwalk art later.

---

## How to help me

- Be concrete and implementation-oriented.
- Flag balance or scope problems early. Call out when something is 3x the engineering I think it is.
- When you change a number that interacts with a design rule (automation cost vs. next-tier unlock), say so explicitly.
- Review your own output before handing it over, and tell me what you found.
- Don't state my project structure or toolchain as established fact unless I've confirmed it. Say what the code assumes, and ask.
