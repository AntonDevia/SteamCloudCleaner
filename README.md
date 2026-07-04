# Steam Cloud Cleaner

A PowerShell TUI tool that automates clearing Steam Cloud sync data for a game
(currently targets Counter-Strike 2, AppID 730), based on the process described in
[this Steam Community discussion](https://steamcommunity.com/discussions/forum/26/392183857616788182/).

## What it does

- Arrow-key menu UI with English/Russian localization.
- Auto-detects your Steam install path and active SteamID3 from the registry.
- Only touches the Steam Cloud portion of game data (`userdata\<id>\<appid>\remote\`
  and `remotecache.vdf`). Your local settings (`local\` — video settings, keybinds,
  etc.) are never touched.
- Two modes: clear Steam Cloud only (re-uploads a clean empty state, sync stays on),
  or clear and disable Steam Cloud sync for the game.

## Why manual steps are still required

Steam re-downloads/restores files from the cloud on startup while sync is enabled,
so sync must be turned off (via Steam's own Properties UI — there is no local file
flag for this) before wiping files. The tool walks you through exactly when to do
this, and automates everything else (closing processes, wiping files, launching the
game, etc).

## Usage

```powershell
.\SteamCloudCleaner.ps1
```

Optional parameters:

```powershell
.\SteamCloudCleaner.ps1 -AppId 730 -SteamId 123456789 -SteamPath "C:\Program Files (x86)\Steam"
```

## Warning

This tool **irreversibly wipes Steam Cloud data** for the selected game once Steam
re-syncs the empty state. Local files and configs are not affected, but there is no
undo for the cloud data itself.
