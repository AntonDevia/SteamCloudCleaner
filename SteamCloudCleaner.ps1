<#
.SYNOPSIS
    Steam Cloud Cleaner - TUI automation for clearing Steam Cloud saves/config for a game
    (based on steamcommunity.com discussion 392183857616788182).

.DESCRIPTION
    Interactive full-screen console UI (arrow-key menus) with EN/RU localization.
    Flow: language select -> red warning + confirm -> mode select (clear only / clear + disable cloud)
    -> fully automatic run with status screens (no further prompts), except the unavoidable wait for
    Steam's own sync-conflict dialog.

    Only touches the Steam Cloud part of game data: userdata\<SteamId>\<AppId>\remote\ and
    remotecache.vdf. Local settings (userdata\<SteamId>\<AppId>\local\ - video, keybinds, etc.)
    are never touched.

.PARAMETER AppId
    Steam AppID of the game. Defaults to 730 (Counter-Strike 2).

.PARAMETER SteamId
    SteamID3 of the profile (userdata subfolder). Auto-detected from registry if omitted.

.PARAMETER SteamPath
    Steam installation path. Auto-detected from registry if omitted.

.EXAMPLE
    .\SteamCloudCleaner.ps1
#>

[CmdletBinding()]
param(
    [string]$AppId,
    [string]$SteamId,
    [string]$SteamPath
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# Localization
# ============================================================

$Strings = @{
    en = @{
        title              = "STEAM CLOUD CLEANER"
        subtitle           = "Automated Steam Cloud sync-conflict cleanup"
        lang_prompt        = "Select language"
        lang_en            = "English"
        lang_ru            = "Russian"
        warn_title         = "IRREVERSIBLE OPERATION"
        warn_body          = @(
            "This will COMPLETELY WIPE Steam Cloud data for the selected game.",
            "",
            "  - Cloud saves / configs stored in userdata\<id>\<appid>\remote\ will be deleted.",
            "  - This action CANNOT be undone once Steam re-syncs the empty cloud.",
            "",
            "This will NOT affect your local files or configs (userdata\<id>\<appid>\local\)."
        )
        confirm_prompt     = "Do you want to continue?"
        yes                = "Yes, continue"
        no                 = "No, cancel"
        cancelled          = "Cancelled. No changes were made."
        mode_prompt        = "Choose what to do"
        mode_clear         = "Clear Steam Cloud only"
        mode_clear_desc    = "Wipes cloud data, then re-uploads a clean empty state. Cloud sync stays enabled."
        mode_disable       = "Clear Steam Cloud and disable sync"
        mode_disable_desc  = "Wipes cloud data, then shows instructions to disable Steam Cloud sync for this game."
        detecting          = "Detecting Steam installation..."
        found_steam        = "Steam found at"
        found_id           = "Active SteamID3"
        found_game         = "Game data folder"
        not_found_path     = "Could not auto-detect Steam path from registry."
        enter_path         = "Enter Steam installation path"
        no_userdata        = "No userdata profiles found under"
        pick_profile       = "Select profile"
        game_not_found     = "Game data folder not found"
        check_ids          = "Check AppId/SteamId and try again."
        step0_title        = "STEP 1 / 4 - Temporarily disable Steam Cloud"
        why_disable_first  = "Steam auto-restores files from the cloud on startup if sync stays on."
        why_disable_first2 = "So sync must be turned OFF before wiping files, or Steam will just re-download them."
        disable_steps_tmp  = @(
            "1. Right-click the game in your Steam Library -> Properties.",
            "2. Open the 'General' tab.",
            "3. Uncheck 'Enable Steam Cloud synchronization for <game>'.",
            "4. Close the Properties window."
        )
        opening_props      = "Opening game properties in Steam..."
        press_continue     = "Press Enter once you've done this"
        step1_title        = "STEP 2 / 4 - Wiping local cloud files"
        closing_steam      = "Closing Steam and game processes..."
        wiping_remote      = "Wiping files in remote\..."
        no_remote          = "No remote\ folder found, skipping."
        removing_cache     = "Removing remotecache.vdf..."
        no_cache           = "remotecache.vdf not found, skipping."
        starting_steam     = "Starting Steam..."
        waiting_steam      = "Waiting for Steam to initialize"
        step2_title        = "STEP 3 / 4 - Re-enable sync and trigger conflict"
        reenable_steps     = @(
            "1. Right-click the game in your Steam Library -> Properties.",
            "2. Open the 'General' tab.",
            "3. Check 'Enable Steam Cloud synchronization for <game>' back ON.",
            "4. Close the Properties window."
        )
        launching_game     = "Launching game to trigger sync-conflict dialog..."
        waiting_dialog_sub = "Steam should show a 'Steam Cloud Conflict' dialog with two options: Cloud saves vs Local saves."
        upload_notice      = "ACTION NEEDED: select 'Local saves' (the empty/wiped ones) and click 'Continue' to upload the empty state to the cloud."
        syncing_wait       = "Giving Steam a few seconds to finish uploading before closing..."
        step3_title        = "STEP 4 / 4 - Final sync state"
        disable_title      = "How to disable Steam Cloud sync (final)"
        disable_steps      = @(
            "1. Right-click the game in your Steam Library -> Properties.",
            "2. Open the 'General' tab.",
            "3. Uncheck 'Enable Steam Cloud synchronization for <game>'.",
            "4. Close the Properties window."
        )
        finishing          = "Finishing up, closing processes..."
        done_title         = "DONE"
        done_clear         = "Steam Cloud data cleared for AppID {0} (SteamID {1})."
        done_disable       = "Steam Cloud data cleared and sync disabled for AppID {0} (SteamID {1})."
        done_local_safe    = "Local settings (local\) were not touched."
        press_exit         = "Press Enter to exit"
        arrow_hint         = "Use UP/DOWN arrows to move, ENTER to select"
    }
    ru = @{
        title              = "STEAM CLOUD CLEANER"
        subtitle           = "Автоматическая очистка конфликта синхронизации Steam Cloud"
        lang_prompt        = "Выберите язык"
        lang_en            = "Английский"
        lang_ru            = "Русский"
        warn_title         = "НЕОБРАТИМАЯ ОПЕРАЦИЯ"
        warn_body          = @(
            "Steam Cloud для выбранной игры будет ПОЛНОСТЬЮ ОЧИЩЕН.",
            "",
            "  - Облачные сохранения/конфиги в userdata\<id>\<appid>\remote\ будут удалены.",
            "  - Отменить это после повторной синхронизации пустого облака будет НЕЛЬЗЯ.",
            "",
            "Локальные файлы и конфиги (userdata\<id>\<appid>\local\) затронуты НЕ будут."
        )
        confirm_prompt     = "Продолжить?"
        yes                = "Да, продолжить"
        no                 = "Нет, отмена"
        cancelled          = "Отменено. Изменения не внесены."
        mode_prompt        = "Выберите режим"
        mode_clear         = "Только очистить Steam Cloud"
        mode_clear_desc    = "Очищает облако и загружает обратно чистое пустое состояние. Синхронизация остаётся включённой."
        mode_disable       = "Очистить Steam Cloud и отключить синхронизацию"
        mode_disable_desc  = "Очищает облако, затем показывает инструкцию по отключению синхронизации для этой игры."
        detecting          = "Определение установки Steam..."
        found_steam        = "Steam найден в"
        found_id           = "Активный SteamID3"
        found_game         = "Папка данных игры"
        not_found_path     = "Не удалось определить путь Steam из реестра."
        enter_path         = "Введите путь установки Steam"
        no_userdata        = "Профили userdata не найдены в"
        pick_profile       = "Выберите профиль"
        game_not_found     = "Папка данных игры не найдена"
        check_ids          = "Проверьте AppId/SteamId и попробуйте снова."
        step0_title        = "ШАГ 1 / 4 - Временное отключение Steam Cloud"
        why_disable_first  = "Steam автоматически восстанавливает файлы из облака при запуске, пока синхронизация включена."
        why_disable_first2 = "Поэтому синхронизацию нужно ВЫКЛЮЧИТЬ перед очисткой файлов, иначе Steam просто скачает их заново."
        disable_steps_tmp  = @(
            "1. ПКМ по игре в библиотеке Steam -> Свойства.",
            "2. Откройте вкладку 'Общие'.",
            "3. Снимите галочку 'Enable Steam Cloud synchronization for <game>'.",
            "4. Закройте окно свойств."
        )
        opening_props      = "Открываю свойства игры в Steam..."
        press_continue     = "Нажмите Enter, когда сделаете это"
        step1_title        = "ШАГ 2 / 4 - Очистка локальных облачных файлов"
        closing_steam      = "Закрытие Steam и процессов игры..."
        wiping_remote      = "Очистка файлов в remote\..."
        no_remote          = "Папка remote\ не найдена, пропускаю."
        removing_cache     = "Удаление remotecache.vdf..."
        no_cache           = "remotecache.vdf не найден, пропускаю."
        starting_steam     = "Запуск Steam..."
        waiting_steam      = "Ожидание инициализации Steam"
        step2_title        = "ШАГ 3 / 4 - Включение синхронизации обратно и вызов конфликта"
        reenable_steps     = @(
            "1. ПКМ по игре в библиотеке Steam -> Свойства.",
            "2. Откройте вкладку 'Общие'.",
            "3. Включите ОБРАТНО галочку 'Enable Steam Cloud synchronization for <game>'.",
            "4. Закройте окно свойств."
        )
        launching_game     = "Запуск игры для вызова диалога конфликта синхронизации..."
        waiting_dialog_sub = "Steam должен показать диалог 'Конфликт со Steam Cloud' с двумя вариантами: Облачные сохранения и Локальные сохранения."
        upload_notice      = "ТРЕБУЕТСЯ ДЕЙСТВИЕ: выберите 'Локальные сохранения' (пустые/очищенные) и нажмите 'Продолжить', чтобы загрузить пустое состояние в облако."
        syncing_wait       = "Даю Steam несколько секунд на завершение загрузки перед закрытием..."
        step3_title        = "ШАГ 4 / 4 - Финальное состояние синхронизации"
        disable_title      = "Как отключить синхронизацию Steam Cloud (финально)"
        disable_steps      = @(
            "1. ПКМ по игре в библиотеке Steam -> Свойства.",
            "2. Откройте вкладку 'Общие'.",
            "3. Снимите галочку 'Enable Steam Cloud synchronization for <game>'.",
            "4. Закройте окно свойств."
        )
        finishing          = "Завершение процессов..."
        done_title         = "ГОТОВО"
        done_clear         = "Steam Cloud очищен для AppID {0} (SteamID {1})."
        done_disable       = "Steam Cloud очищен и синхронизация отключена для AppID {0} (SteamID {1})."
        done_local_safe    = "Локальные настройки (local\) не были затронуты."
        press_exit         = "Нажмите Enter для выхода"
        arrow_hint         = "Стрелки ВВЕРХ/ВНИЗ - навигация, ENTER - выбор"
    }
}

$script:Lang = 'en'
function T {
    param([string]$Key, [object[]]$FormatArgs)
    $val = $Strings[$script:Lang][$Key]
    if ($FormatArgs) { return ($val -f $FormatArgs) }
    return $val
}

# ============================================================
# UI primitives
# ============================================================

$UI = @{
    Accent   = [ConsoleColor]::Cyan
    Warn     = [ConsoleColor]::Red
    Ok       = [ConsoleColor]::Green
    Dim      = [ConsoleColor]::DarkGray
    Text     = [ConsoleColor]::White
    Select   = [ConsoleColor]::Black
    SelectBg = [ConsoleColor]::Cyan
}

function Get-ConsoleWidth {
    try { return [Math]::Max(60, $Host.UI.RawUI.WindowSize.Width) } catch { return 80 }
}

function Write-Center {
    param([string]$Text, [ConsoleColor]$Color = $UI.Text)
    $w = Get-ConsoleWidth
    $pad = [Math]::Max(0, [int](($w - $Text.Length) / 2))
    Write-Host ((" " * $pad) + $Text) -ForegroundColor $Color
}

function Draw-Frame {
    param([string]$Title)
    $w = Get-ConsoleWidth
    $line = "=" * $w
    Write-Host $line -ForegroundColor $UI.Accent
    Write-Center $Title -Color $UI.Accent
    Write-Host $line -ForegroundColor $UI.Accent
    Write-Host ""
}

function Clear-Screen {
    Clear-Host
}

function Show-Header {
    param([string]$Subtitle)
    Clear-Screen
    Draw-Frame -Title (T 'title')
    if ($Subtitle) {
        Write-Center $Subtitle -Color $UI.Dim
        Write-Host ""
    }
}

# Arrow-key menu. Returns selected index.
function Show-Menu {
    param(
        [string[]]$Options,
        [string[]]$Descriptions = @(),
        [int]$Selected = 0
    )
    $top = [Console]::CursorTop
    while ($true) {
        [Console]::SetCursorPosition(0, $top)
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = if ($i -eq $Selected) { " > " } else { "   " }
            $line = "$prefix$($Options[$i])"
            $pad = (Get-ConsoleWidth) - $line.Length
            if ($pad -lt 0) { $pad = 0 }
            $lineOut = $line + (" " * $pad)
            if ($i -eq $Selected) {
                Write-Host $lineOut -ForegroundColor $UI.Select -BackgroundColor $UI.SelectBg
            } else {
                Write-Host $lineOut -ForegroundColor $UI.Text
            }
            if ($Descriptions.Count -gt $i -and $Descriptions[$i]) {
                $descLine = "     $($Descriptions[$i])"
                $descPad = (Get-ConsoleWidth) - $descLine.Length
                if ($descPad -lt 0) { $descPad = 0 }
                Write-Host ($descLine + (" " * $descPad)) -ForegroundColor $UI.Dim
            }
        }
        Write-Host ""
        Write-Center (T 'arrow_hint') -Color $UI.Dim

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow'   { $Selected = if ($Selected -eq 0) { $Options.Count - 1 } else { $Selected - 1 } }
            'DownArrow' { $Selected = if ($Selected -eq $Options.Count - 1) { 0 } else { $Selected + 1 } }
            'Enter'     { return $Selected }
        }
    }
}

function Show-Spinner {
    param(
        [string]$Message,
        [string]$SubMessage,
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 30
    )
    $frames = @('|', '/', '-', '\')
    $i = 0
    $elapsed = 0
    $intervalMs = 200
    while ($true) {
        $frame = $frames[$i % $frames.Count]
        $line = "  $frame  $Message"
        Write-Host "`r$line$(' ' * 10)" -NoNewline -ForegroundColor $UI.Accent
        Start-Sleep -Milliseconds $intervalMs
        $elapsed += $intervalMs
        $i++
        if ($Condition -and (& $Condition)) { break }
        if (-not $Condition -and $elapsed -ge ($TimeoutSeconds * 1000)) { break }
        if ($Condition -and $elapsed -ge ($TimeoutSeconds * 1000)) { break }
    }
    Write-Host "`r  [ok] $Message$(' ' * 10)" -ForegroundColor $UI.Ok
    if ($SubMessage) { Write-Host "       $SubMessage" -ForegroundColor $UI.Dim }
}

function Show-Info {
    param([string]$Text)
    Write-Host "  * $Text" -ForegroundColor $UI.Text
}

function Show-WarnLine {
    param([string]$Text)
    Write-Host "  ! $Text" -ForegroundColor $UI.Warn
}

function Wait-Enter {
    param([string]$Prompt)
    Write-Host ""
    Write-Host "  >> $Prompt" -ForegroundColor $UI.Accent
    [Console]::ReadKey($true) | Out-Null
}

# ============================================================
# Screens
# ============================================================

function Select-Language {
    $script:Lang = 'en'
    Show-Header
    Write-Center "Select language / Выберите язык" -Color $UI.Text
    Write-Host ""
    $idx = Show-Menu -Options @("English", "Русский")
    $script:Lang = if ($idx -eq 0) { 'en' } else { 'ru' }
}

function Show-WarningScreen {
    Show-Header -Subtitle (T 'subtitle')
    Write-Center (T 'warn_title') -Color $UI.Warn
    Write-Host ""
    foreach ($line in (T 'warn_body')) {
        Write-Center $line -Color $UI.Warn
    }
    Write-Host ""
    Write-Host ""
    Write-Center (T 'confirm_prompt') -Color $UI.Text
    Write-Host ""
    $idx = Show-Menu -Options @((T 'no'), (T 'yes')) -Selected 0
    return ($idx -eq 1)
}

function Select-Mode {
    Show-Header -Subtitle (T 'subtitle')
    Write-Center (T 'mode_prompt') -Color $UI.Text
    Write-Host ""
    $options = @((T 'mode_clear'), (T 'mode_disable'))
    $descs = @((T 'mode_clear_desc'), (T 'mode_disable_desc'))
    $idx = Show-Menu -Options $options -Descriptions $descs
    return $idx
}

# ============================================================
# Steam detection helpers
# ============================================================

function Get-SteamPathFromRegistry {
    try {
        $path = Get-ItemPropertyValue -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction Stop
        return ($path -replace '/', '\')
    } catch { return $null }
}

function Get-ActiveSteamId {
    try {
        return (Get-ItemPropertyValue -Path 'HKCU:\Software\Valve\Steam\ActiveProcess' -Name 'ActiveUser' -ErrorAction Stop)
    } catch { return $null }
}

function Stop-SteamAndGame {
    param([string]$AppId)
    $gameProcessNames = @('cs2', ('steam_app_' + $AppId))
    foreach ($name in $gameProcessNames) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Get-Process -Name 'steam' -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

# ============================================================
# Main flow
# ============================================================

Select-Language

if (-not $AppId) { $AppId = '730' }

Show-Header -Subtitle (T 'subtitle')
Show-Info (T 'detecting')

if (-not $SteamPath) {
    $SteamPath = Get-SteamPathFromRegistry
    if (-not $SteamPath) {
        Write-Host ""
        Show-WarnLine (T 'not_found_path')
        $SteamPath = Read-Host (T 'enter_path')
    }
}
if (-not (Test-Path $SteamPath)) {
    throw "Steam path not found: $SteamPath"
}
Show-Info "$(T 'found_steam'): $SteamPath"

if (-not $SteamId) {
    $activeId = Get-ActiveSteamId
    if ($activeId -and $activeId -ne '0' -and (Test-Path (Join-Path $SteamPath "userdata\$activeId"))) {
        $SteamId = $activeId
    } else {
        $userdataRoot = Join-Path $SteamPath 'userdata'
        $candidates = Get-ChildItem $userdataRoot -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        if ($candidates.Count -eq 1) {
            $SteamId = $candidates[0]
        } elseif ($candidates.Count -gt 1) {
            Write-Host ""
            Show-Info (T 'pick_profile')
            $idx = Show-Menu -Options $candidates
            $SteamId = $candidates[$idx]
        } else {
            throw "$(T 'no_userdata') $userdataRoot"
        }
    }
}
Show-Info "$(T 'found_id'): $SteamId"

$gameDataPath   = Join-Path $SteamPath "userdata\$SteamId\$AppId"
$remotePath     = Join-Path $gameDataPath 'remote'
$remoteCachePath = Join-Path $gameDataPath 'remotecache.vdf'
$steamExe       = Join-Path $SteamPath 'steam.exe'

if (-not (Test-Path $gameDataPath)) {
    throw "$(T 'game_not_found'): $gameDataPath. $(T 'check_ids')"
}
Show-Info "$(T 'found_game'): $gameDataPath"
Start-Sleep -Milliseconds 800

# --- Warning + confirm ---
$confirmed = Show-WarningScreen
if (-not $confirmed) {
    Show-Header
    Write-Center (T 'cancelled') -Color $UI.Warn
    Write-Host ""
    Wait-Enter (T 'press_exit')
    exit 0
}

# --- Mode select ---
$modeIdx = Select-Mode
$disableCloud = ($modeIdx -eq 1)

# ============================================================
# STEP 1: temporarily disable Steam Cloud sync (manual, via Steam UI)
# ============================================================
# Steam re-downloads/restores files from the cloud on startup while sync is
# enabled, which silently undoes any local wipe. Sync must be off first.
Show-Header -Subtitle (T 'step0_title')
Show-WarnLine (T 'why_disable_first')
Show-WarnLine (T 'why_disable_first2')
Write-Host ""
foreach ($line in (T 'disable_steps_tmp')) {
    Show-Info $line
}
Write-Host ""
Show-Info (T 'opening_props')
Start-Process "steam://gameproperties/$AppId"
Wait-Enter (T 'press_continue')

# ============================================================
# STEP 2: wipe local cloud files while sync is off
# ============================================================
Show-Header -Subtitle (T 'step1_title')

Show-Info (T 'closing_steam')
Stop-SteamAndGame -AppId $AppId

if (Test-Path $remotePath) {
    Show-Info (T 'wiping_remote')
    Get-ChildItem -Path $remotePath -Recurse -File | ForEach-Object {
        Set-Content -Path $_.FullName -Value $null -NoNewline -Encoding Byte
    }
} else {
    Show-WarnLine (T 'no_remote')
}

if (Test-Path $remoteCachePath) {
    Show-Info (T 'removing_cache')
    Remove-Item -Path $remoteCachePath -Force
} else {
    Show-WarnLine (T 'no_cache')
}

Show-Info (T 'starting_steam')
Start-Process -FilePath $steamExe
Show-Spinner -Message (T 'waiting_steam') -TimeoutSeconds 15

# ============================================================
# STEP 3: re-enable sync (manual) so Steam sees the real conflict, then clear it
# ============================================================
Show-Header -Subtitle (T 'step2_title')
foreach ($line in (T 'reenable_steps')) {
    Show-Info $line
}
Write-Host ""
Show-Info (T 'opening_props')
Start-Process "steam://gameproperties/$AppId"
Wait-Enter (T 'press_continue')

Show-Info (T 'launching_game')
Start-Process "steam://rungameid/$AppId"

Write-Host ""
Show-WarnLine (T 'waiting_dialog_sub')
Show-WarnLine (T 'upload_notice')
Wait-Enter (T 'press_continue')

Show-Spinner -Message (T 'syncing_wait') -TimeoutSeconds 15

# ============================================================
# STEP 4: final sync state
# ============================================================
if ($disableCloud) {
    Show-Header -Subtitle (T 'step3_title')
    Write-Center (T 'disable_title') -Color $UI.Text
    Write-Host ""
    foreach ($line in (T 'disable_steps')) {
        Show-Info $line
    }
    Write-Host ""
    Show-Info (T 'opening_props')
    Start-Process "steam://gameproperties/$AppId"
    Wait-Enter (T 'press_continue')
}

Show-Info (T 'finishing')
Stop-SteamAndGame -AppId $AppId

# ============================================================
# Done
# ============================================================
Show-Header
Write-Center (T 'done_title') -Color $UI.Ok
Write-Host ""
if ($disableCloud) {
    Write-Center (T 'done_disable' @($AppId, $SteamId)) -Color $UI.Ok
} else {
    Write-Center (T 'done_clear' @($AppId, $SteamId)) -Color $UI.Ok
}
Write-Center (T 'done_local_safe') -Color $UI.Dim
Write-Host ""
Wait-Enter (T 'press_exit')
