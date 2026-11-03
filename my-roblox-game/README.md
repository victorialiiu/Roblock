# Squishy Rain 🌧️

Our Roblox game. All the code lives in this repo, and we use [Rojo](https://rojo.space) to sync it into Roblox Studio. That way we can all work on it together without sending place files around.

---

## One-time setup (about 10 minutes)

### 1. Get the tools
- **Roblox Studio**: you probably already have it
- **Git**: check with `git --version`
- **VS Code**: or any editor you like
- **Rokit**: installs the right version of Rojo for us. Follow the install steps at https://github.com/rojo-rbx/rokit

### 2. Clone the repo
```bash
git clone https://github.com/victorialiiu/Roblock.git
cd Roblock/my-roblox-game
```

### 3. Install Rojo
```bash
rokit install
```
This reads `rokit.toml` and installs the same Rojo version for everyone (7.7.1), so nobody gets weird version bugs.

### 4. Install the Rojo plugin in Studio
```bash
rojo plugin install
```
Restart Studio after this. You should see a **Rojo** button in the Plugins tab.

---

## Working on the game

Do this every time you sit down to work:

```bash
cd Roblock/my-roblox-game
git pull                                   # grab everyone else's changes
rojo build -o "my-roblox-game.rbxlx"       # build a fresh place file
rojo serve                                 # leave this running
```

Then:
1. Open `my-roblox-game.rbxlx` in Roblox Studio
2. Click **Plugins → Rojo → Connect**
3. Edit code in VS Code. It shows up in Studio as soon as you save
4. Hit **Play** in Studio to test

---

## Where stuff goes

| Folder | Ends up in | What it's for |
|---|---|---|
| `src/server/` | ServerScriptService | Game logic, building the map, damage, etc. |
| `src/client/` | StarterPlayerScripts | UI and things only you see on your screen |
| `src/shared/` | ReplicatedStorage | Modules that both the server and client use |

File names decide the script type:
- `Something.server.luau` is a server Script
- `Something.client.luau` is a LocalScript
- `Something.luau` is a ModuleScript

**How the game is put together:**

| Want to... | Edit this |
|---|---|
| Add or change a squishy (name, rarity, value, equip boost) | `src/shared/SquishyTypes.luau` |
| Change what a squishy looks like | `src/server/SquishyShapes.luau` |
| Add a weather type or attribute (mutation) | `src/shared/Weather.luau` and `Mutations` in `SquishyTypes.luau` |
| Add or change a region (its squishies, luck, attribute, terrain, unlock cost) | One file per region in `src/shared/Regions/` |
| Move the lobby island or the hunting map | `src/shared/Lobby.luau` / `src/shared/World.luau` |
| Change the portals between them | `src/server/Travel.server.luau` |
| Change the region walls and gates | `src/server/RegionGates.server.luau` |
| Change how the land is generated, or add props (trees, lollipops...) | `src/server/Terrain.server.luau` / `src/server/TerrainProps.luau` |
| Change shop upgrades, Lucky Spin prizes, rebirth numbers, base income | `src/shared/Shop.luau` |
| Gamepasses and the Lucky Box (paste real ids here) | `src/shared/Passes.luau` |
| Squishy Pass season, XP, and tier rewards | `src/shared/SquishyPass.luau` |
| Leaderboard periods, top-3 tags, end-of-week/month prizes | `src/shared/Leaderboards.luau` |
| Save something new about a player | `SAVED_ATTRIBUTES` in `src/server/Economy.server.luau` |
| Build a new UI screen | Use the helpers in `src/shared/UI.luau` |
| Change the lobby booths | `src/server/Lobby.server.luau` |
| Change player bases (in the lobby) and showcase pedestals | `src/server/Base.server.luau` |
| Change how trading works | `src/server/Trade.server.luau` |
| Add the fart sound (or other sounds) | `src/shared/Sounds.luau` |
| Add a chaotic event | Make a ModuleScript in `src/server/Events/` with a `Name`, `Start`, and `Stop` |
| Change spawn rate, weather timing | Numbers at the top of `SquishyRain.server.luau` / `Weather.server.luau` |

**How the game loop works:**
- You spawn in the **lobby**, a floating island far from the hunting map with the shops, trading, leaderboards, and everyone's bases. Walk through the portal (or tap **Go Hunt**) to get to the **hunting map**, and back the same way.
- Outer regions are **locked** behind a glowing wall. Each one needs some rebirths, then a one-time payment at a gate (set with `Unlock` in the region's file). Better regions = more luck and rarer squishies.
- Squishies fall around you. Which ones depends on the **region** you're in (farther out = rarer, more evil). Weather (sometimes two at once!) and regions add **attributes** that stack: `Wet Shocked Donut` is worth x2 × x5 = x10.
- **Commons are for selling.** Uncommon and up can be **equipped** for stat boosts (speed, jump, HP, luck, money). Equipped squishies and ones on your base are held, so they can't be sold or traded by accident.
- Squishies on your **base pedestals earn money every second**.
- **Rebirth** resets money and upgrades for a money multiplier, more pedestals, more equip slots, and a bigger bag.
- Progress saves with DataStores. To save in Studio, turn on Game Settings → Security → **Enable Studio Access to API Services**.
- Every server gets its own random map. The seed prints in the output and is saved as workspace's `TerrainSeed` attribute.

### Using real 3D models for squishies 🧈
Any squishy can use a real model instead of the built-in shape:
1. In Studio, get the model (Toolbox, or import from Blender) and put it in Workspace
2. **Delete any scripts inside it** (free models sometimes hide sketchy scripts)
3. Rename the model to **exactly** the squishy's name, like `Butter` or `Boba Tea`
4. Right-click it → **Save to File...** → save it into `src/shared/Models/` as `Butter.rbxm`
5. Delete it from Workspace. Rojo syncs the file in and the game uses it automatically. Commit the `.rbxm` so everyone gets it

---

## ⚠️ The big gotcha

**Anything you build by hand in Studio (dragging parts around, etc.) is NOT saved to git.** The `.rbxlx` file is gitignored, so only the stuff in `src/` and `default.project.json` gets shared.

So if you want teammates to see something:
- **Make it with a script**, like the squishy rain does, **or**
- **Add it to `default.project.json`** under `Workspace`, like the Baseplate

If you build something in Studio that you love, ask in the chat. We can turn it into a script or save it as a model file.

---

## Sharing your changes

Keep it simple:

```bash
git pull                          # get the latest first
git checkout -b my-cool-thing     # make a branch for your feature
# ...do your thing...
git add .
git commit -m "added a jump pad"
git push -u origin my-cool-thing
```

Then open a Pull Request on GitHub and drop the link in the group chat. Someone gives it a quick look and merges it. No pressure, it doesn't need to be perfect.

### Tips so we don't step on each other
- **One feature = one file.** Make a new script like `JumpPad.server.luau` instead of piling everything into one big file. That way two people almost never edit the same file at once.
- **Say what you're working on** in the chat so two people don't build the same thing.
- **Pull often.** The more often you `git pull`, the fewer merge conflicts you get.
- **Got a merge conflict?** Don't panic. Ask someone in the chat and we'll sort it out together.

---

## Stuck?
- Nothing syncing? Make sure `rojo serve` is still running and you clicked **Connect** in Studio.
- `rojo: command not found`? Run `rokit install` again and restart your terminal.
- Rojo docs: https://rojo.space/docs
