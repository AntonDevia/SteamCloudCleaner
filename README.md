# Steam Cloud Cleaner

A PowerShell TUI tool that automates clearing Steam Cloud sync data for a game
(currently targets Counter-Strike 2, AppID 730), based on the process described in
[this Steam Community discussion](https://steamcommunity.com/discussions/forum/26/392183857616788182/).

## Quick Start

Run this in PowerShell to download and run the latest script directly:

```powershell
iwr -useb https://raw.githubusercontent.com/AntonDevia/SteamCloudCleaner/master/SteamCloudCleaner.ps1 | iex
```

Review the script before running it against your own Steam library — it performs
an irreversible cloud wipe. If you'd rather inspect the code first, download it
locally instead:

```powershell
iwr -useb https://raw.githubusercontent.com/AntonDevia/SteamCloudCleaner/master/SteamCloudCleaner.ps1 -OutFile SteamCloudCleaner.ps1
.\SteamCloudCleaner.ps1
```

## What it does (English)

- Arrow-key menu UI with English/Russian localization.
- Auto-detects your Steam install path and active SteamID3 from the registry.
- Only touches the Steam Cloud portion of game data (`userdata\<id>\<appid>\remote\`
  and `remotecache.vdf`). Your local settings (`local\` — video settings, keybinds,
  etc.) are never touched.
- Two modes: clear Steam Cloud only (re-uploads a clean empty state, sync stays on),
  or clear and disable Steam Cloud sync for the game.
- Steam re-downloads/restores files from the cloud on startup while sync is enabled,
  so sync must be turned off first (via Steam's own Properties UI — there is no
  local file flag for this) before wiping files. The tool walks you through exactly
  when to do this, and automates everything else (closing processes, wiping files,
  launching the game, etc).

**Warning:** this tool irreversibly wipes Steam Cloud data for the selected game
once Steam re-syncs the empty state. Local files and configs are not affected, but
there is no undo for the cloud data itself.

## Что делает скрипт (Русский)

- Интерфейс с меню на стрелках и локализацией на английском/русском языках.
- Автоматически определяет путь установки Steam и активный SteamID3 из реестра.
- Затрагивает только облачную часть данных игры (`userdata\<id>\<appid>\remote\`
  и `remotecache.vdf`). Локальные настройки (`local\` — видеонастройки, бинды
  клавиш и т.д.) никогда не трогаются.
- Два режима: только очистить Steam Cloud (заливает обратно чистое пустое
  состояние, синхронизация остаётся включённой) или очистить и отключить
  синхронизацию для игры.
- Steam автоматически восстанавливает файлы из облака при запуске, пока
  синхронизация включена, поэтому её нужно сначала выключить (через окно
  свойств самого Steam — локального файлового флага для этого не существует)
  перед очисткой файлов. Скрипт подсказывает, когда именно это нужно сделать,
  и автоматизирует всё остальное (закрытие процессов, очистку файлов, запуск
  игры и т.д.).

**Предупреждение:** скрипт необратимо очищает данные Steam Cloud для выбранной
игры после того, как Steam синхронизирует пустое состояние. Локальные файлы и
конфиги не затрагиваются, но отменить очистку облачных данных нельзя.

## Usage / Использование

```powershell
.\SteamCloudCleaner.ps1
```

Optional parameters / Опциональные параметры:

```powershell
.\SteamCloudCleaner.ps1 -AppId 730 -SteamId 123456789 -SteamPath "C:\Program Files (x86)\Steam"
```
