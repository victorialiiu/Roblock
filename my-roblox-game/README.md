# my-roblox-game 🎮

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

**Examples already in here:**
- `src/server/Lava.server.luau`: a red block that kills you 🔥
- `src/server/GrassField.server.luau`: a grass field 🌱

---

## ⚠️ The big gotcha

**Anything you build by hand in Studio (dragging parts around, etc.) is NOT saved to git.** The `.rbxlx` file is gitignored, so only the stuff in `src/` and `default.project.json` gets shared.

So if you want teammates to see something:
- **Make it with a script**, like the lava and grass field do, **or**
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
