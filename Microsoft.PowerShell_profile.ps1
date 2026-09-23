# Force UTF-8 encoding for Unicode/Japanese text output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# PowerShell Profile - Customized by Y7XIFIED

# === Shell Completions & Behaviors ===
Import-Module PSReadLine
try {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
} catch {}
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function BackwardKillWord -ErrorAction SilentlyContinue

# === Module Imports ===
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

# === Zoxide Initialization ===
if (Test-Path "$env:USERPROFILE\.config\zoxide.ps1") {
    . "$env:USERPROFILE\.config\zoxide.ps1"
}

# === Commands & Aliases ===
Set-Alias -Name cat -Value bat -Force -ErrorAction SilentlyContinue
Set-Alias -Name ping -Value gping -Force -ErrorAction SilentlyContinue

function ls { lsd @args }
function find { fd @args }
function grep { rg @args }

function Get-WindowsAccentColor {
    try {
        $acc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -ErrorAction SilentlyContinue).AccentPalette
        if ($acc -and $acc.Length -ge 16) {
            $r = $acc[12]; $g = $acc[13]; $b = $acc[14]
            return "$([char]27)[38;2;$r;$g;${b}m"
        }
        $dwm = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -ErrorAction Stop
        if ($dwm.ColorizationColor) {
            $col = [uint32]$dwm.ColorizationColor
            $r = ($col -shr 16) -band 0xFF
            $g = ($col -shr 8) -band 0xFF
            $b = $col -band 0xFF
            $brightness = [Math]::Max($r, [Math]::Max($g, $b))
            if ($brightness -gt 0 -and $brightness -lt 170) {
                $scale = 170.0 / $brightness
                $r = [Math]::Min(255, [int]($r * $scale))
                $g = [Math]::Min(255, [int]($g * $scale))
                $b = [Math]::Min(255, [int]($b * $scale))
            }
            return "$([char]27)[38;2;$r;$g;${b}m"
        }
    } catch {}
    return "$([char]27)[96m"
}

function Sync-AccentThemes {
    try {
        $acc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -ErrorAction SilentlyContinue).AccentPalette
        if (-not ($acc -and $acc.Length -ge 16)) { return }
        $r = $acc[12]; $g = $acc[13]; $b = $acc[14]
        $hex = "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b
        $cacheFile = "$env:TEMP\terminal_accent_cache.txt"
        if ((Test-Path $cacheFile) -and ((Get-Content $cacheFile -ErrorAction SilentlyContinue) -eq $hex)) {
            return
        }

        # Update Fastfetch config
        $ffPath = "$env:USERPROFILE\.config\fastfetch\config.jsonc"
        if (Test-Path $ffPath) {
            $ff = [System.IO.File]::ReadAllText($ffPath, [System.Text.Encoding]::UTF8)
            $ff = $ff -replace '"\d+":\s*"#[0-9a-fA-F]{6}"', ('"1": "' + $hex + '"')
            $ansiCode = '\u001b[38;2;' + $r + ';' + $g + ';' + $b + 'm'
            $ff = [regex]::Replace($ff, '\\u001b\[(38;2;\d+;\d+;\d+|91|31)m', $ansiCode)
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($ffPath, $ff, $utf8NoBom)
        }


        # Update Windows Terminal scheme
        $wtPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) {
            $wtText = Get-Content $wtPath -Raw
            $wt = $wtText | ConvertFrom-Json
            foreach ($scheme in $wt.schemes) {
                if ($scheme.name -eq 'Red White Black') {
                    $scheme.red = $hex
                    $scheme.brightRed = "#{0:X2}{1:X2}{2:X2}" -f $acc[8], $acc[9], $acc[10]
                    $scheme.blue = $hex
                    $scheme.brightBlue = "#{0:X2}{1:X2}{2:X2}" -f $acc[4], $acc[5], $acc[6]
                    $scheme.purple = $hex
                    $scheme.brightPurple = "#{0:X2}{1:X2}{2:X2}" -f $acc[4], $acc[5], $acc[6]
                    $scheme.cursorColor = $hex
                    $scheme.selectionBackground = $hex
                }
            }
            $newWtText = $wt | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($wtPath, $newWtText, [System.Text.Encoding]::UTF8)
        }

        $hex | Set-Content -Path $cacheFile -Encoding ASCII
    } catch {}
}

function hi {
    param([string]$name = "Y7XIFIED")
    $esc = [char]27
    $accent = Get-WindowsAccentColor
    $c_tl = [char]0x256d
    $c_tr = [char]0x256e
    $c_bl = [char]0x2570
    $c_br = [char]0x256f
    $c_v  = [char]0x2502
    $c_h  = [char]0x2500
    $border = New-Object System.String ($c_h, 50)

    $hour = (Get-Date).Hour
    $timeGreeting = if ($hour -ge 5 -and $hour -lt 12) {
        "Good morning"
    } elseif ($hour -ge 12 -and $hour -lt 17) {
        "Good afternoon"
    } elseif ($hour -ge 17 -and $hour -lt 22) {
        "Good evening"
    } else {
        "Working late"
    }

    $vibes = @(
        "Ready to build something awesome today?",
        "Terminal primed and ready for action.",
        "Clean code, high performance, zero bugs.",
        "Stay hydrated, code passionately.",
        "The compiler is waiting. Make magic happen."
    )
    $spark = $vibes | Get-Random

    $line1 = "$timeGreeting, $name!"
    $pad1 = 48 - $line1.Length
    if ($pad1 -lt 0) { $pad1 = 0 }

    $pad2 = 48 - $spark.Length
    if ($pad2 -lt 0) { $pad2 = 0 }
    $line2_padded = $spark + (" " * $pad2)

    Write-Host ""
    Write-Host "  $accent$c_tl$border$c_tr$esc[0m"
    Write-Host "  $accent$c_v$esc[0m  $esc[97m$timeGreeting, $accent$name$esc[97m!$esc[0m$(" " * $pad1)$accent$c_v$esc[0m"
    Write-Host "  $accent$c_v$esc[0m  $esc[90m$line2_padded$esc[0m$accent$c_v$esc[0m"
    Write-Host "  $accent$c_bl$border$c_br$esc[0m"
    Write-Host ""
}
Set-Alias -Name hello -Value hi -Force -ErrorAction SilentlyContinue

function pokefetch {
    wsl /mnt/c/Users/Y7XIFIED/poke-fetch.sh
}

function kotofetch {
    $quotes = @(
        @{ jp = [char]0x96fb + " " + [char]0x8133 + " " + [char]0x7a7a + " " + [char]0x9593; en = "Java is to JavaScript what car is to carpet." },
        @{ jp = [char]0x6e29 + " " + [char]0x6545 + " " + [char]0x77e5 + " " + [char]0x65b0; en = "To understand what recursion is, you must first understand recursion." },
        @{ jp = [char]0x5343 + " " + [char]0x5909 + " " + [char]0x4e07 + " " + [char]0x5316; en = "There are 10 types of people: those who understand binary, and those who don't." },
        @{ jp = [char]0x5207 + " " + [char]0x7426 + " " + [char]0x7422 + " " + [char]0x78e8; en = "Talk is cheap. Show me the code. - Linus Torvalds" },
        @{ jp = [char]0x683c + " " + [char]0x7269 + " " + [char]0x81f4 + " " + [char]0x77e5; en = "Computers are good at following instructions, but not at reading your mind." },
        @{ jp = [char]0x660e + " " + [char]0x93e1 + " " + [char]0x6b62 + " " + [char]0x6c34; en = "Before software can be reusable it first has to be usable. - Ralph Johnson" },
        @{ jp = [char]0x4e00 + " " + [char]0x610f + " " + [char]0x5c02 + " " + [char]0x5fc3; en = "The code you write today is the technical debt you pay tomorrow." },
        @{ jp = [char]0x8a66 + " " + [char]0x884c + " " + [char]0x932f + " " + [char]0x8aa4; en = "If at first you don't succeed, call it version 1.0." },
        @{ jp = [char]0x5341 + " " + [char]0x4eba + " " + [char]0x5341 + " " + [char]0x8272; en = "A user interface is like a joke. If you have to explain it, it is not that good." },
        @{ jp = [char]0x6c34 + " " + [char]0x6ef4 + " " + [char]0x77f3 + " " + [char]0x7a7f; en = "Real programmers count from 0." }
    )
    $q = $quotes | Get-Random
    
    # Fixed content width inside the box
    $width = 82
    
    # Calculate visual length of full-width Japanese text
    $jp_visual_len = 0
    foreach ($char in $q.jp.ToCharArray()) {
        if ([int]$char -gt 127) { $jp_visual_len += 2 } else { $jp_visual_len += 1 }
    }
    
    # Center Japanese text
    $jp_pad = $width - $jp_visual_len
    $jp_left = [Math]::Floor($jp_pad / 2)
    $jp_right = $jp_pad - $jp_left
    $jp_line = " " * $jp_left + $q.jp + " " * $jp_right
    
    # Center English text
    $en_visual_len = $q.en.Length
    $en_pad = $width - $en_visual_len
    $en_left = [Math]::Floor($en_pad / 2)
    $en_right = $en_pad - $en_left
    $en_line = " " * $en_left + $q.en + " " * $en_right
    
    # Box borders
    $c_tl = [char]0x256d  # top-left
    $c_tr = [char]0x256e  # top-right
    $c_bl = [char]0x2570  # bottom-left
    $c_br = [char]0x256f  # bottom-right
    $c_v  = [char]0x2502  # vertical
    $c_h  = [char]0x2500  # horizontal
    
    $border = New-Object System.String ($c_h, $width)
    $padding_row = " " * $width
    $esc = [char]27
    
    $termWidth = 120
    if ($Host -and $Host.UI -and $Host.UI.RawUI -and $Host.UI.RawUI.WindowSize) {
        $termWidth = $Host.UI.RawUI.WindowSize.Width
    }
    
    $leftMargin = 0
    if ($termWidth -gt $width) {
        $leftMargin = [Math]::Floor(($termWidth - $width) / 2)
    }
    $marginSpaces = " " * $leftMargin
    
    $accent = Get-WindowsAccentColor
    Write-Host "${marginSpaces}$accent$c_tl$border$c_tr$esc[0m"
    Write-Host "${marginSpaces}$accent$c_v$esc[97m$padding_row$accent$c_v$esc[0m"
    Write-Host "${marginSpaces}$accent$c_v$esc[97m$jp_line$accent$c_v$esc[0m"
    Write-Host "${marginSpaces}$accent$c_v$esc[97m$padding_row$accent$c_v$esc[0m"
    Write-Host "${marginSpaces}$accent$c_v$esc[97m$en_line$accent$c_v$esc[0m"
    Write-Host "${marginSpaces}$accent$c_v$esc[97m$padding_row$accent$c_v$esc[0m"
    Write-Host "${marginSpaces}$accent$c_bl$border$c_br$esc[0m"
}

# === Custom Helpers ===

function google {
    param([string]$query)
    $url = "https://www.google.com/search?q=" + [URI]::EscapeDataString($query)
    Start-Process $url
}

function test-port {
    param([int]$port, [string]$host = "localhost")
    $t = New-Object System.Net.Sockets.TcpClient
    $esc = [char]27
    try {
        $t.Connect($host, $port)
        Write-Host "$esc[92mPort $port on $host is active (listening)$esc[97m"
    } catch {
        Write-Host "$esc[91mPort $port on $host is inactive (closed)$esc[97m"
    } finally {
        $t.Close()
    }
}

function Show-GitDashboard {
    if (git rev-parse --is-inside-work-tree 2>$null) {
        $status = git status -s
        $esc = [char]27
        $accent = Get-WindowsAccentColor
        if ($status) {
            Write-Host ""
            Write-Host "$accent Git Status Dashboard (Uncommitted changes):$esc[97m"
            $status | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host ""
            Write-Host "$esc[92mGit Status: Working tree clean$esc[97m"
        }
    }
}

function backup-configs {
    $backupDir = "$env:USERPROFILE\Documents\Terminal_Backup"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    # Copy configs
    Copy-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Destination $backupDir -Force
    Copy-Item -Path "$env:USERPROFILE\.config\fastfetch\config.jsonc" -Destination $backupDir -Force
    Copy-Item -Path "$env:USERPROFILE\.config\fastfetch\ascii.txt" -Destination $backupDir -Force
    Copy-Item -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Destination $backupDir -Force
    
    $esc = [char]27
    Write-Host "$esc[92mConfig files backed up to $backupDir$esc[97m"
    
    if (Test-Path "$backupDir\.git") {
        pushd $backupDir
        git add -A
        $env:GITHUB_TOKEN=""
        git commit -m "Update files"
        git push
        popd
    } else {
        Write-Host "Set up a Git repository in $backupDir to automatically push changes to GitHub."
    }
}

function animfetch {
    $lines = & fastfetch --pipe
    $boxChars = [char[]]([char]0x256D, [char]0x2502, [char]0x2570, [char]0x25CF)
    foreach ($line in $lines) {
        $idx = $line.IndexOfAny($boxChars)
        if ($idx -ge 0) {
            [Console]::Write($line.Substring(0, $idx))
            $infoPart = $line.Substring($idx)
            $tokens = [regex]::Matches($infoPart, '(?s)\x1b\[[0-9;]*[a-zA-Z]|.')
            $charCount = 0
            foreach ($token in $tokens) {
                [Console]::Write($token.Value)
                if ($token.Value.Length -eq 1 -and $token.Value -match '\S') {
                    $charCount++
                    if ($charCount % 3 -eq 0) {
                        Start-Sleep -Milliseconds 1
                    }
                }
            }
            [Console]::WriteLine()
        } else {
            [Console]::WriteLine($line)
        }
    }
}

# === Startup Executions ===
Sync-AccentThemes
fastfetch
Show-GitDashboard

# === Native Shell Prompt ===
function prompt {
    $esc = [char]27
    $accent = Get-WindowsAccentColor
    $currentPath = (Get-Location).Path
    $homePath = $HOME
    if ($currentPath.StartsWith($homePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $displayPath = "~" + $currentPath.Substring($homePath.Length)
    } else {
        $displayPath = $currentPath
    }

    $gitInfo = ""
    if (git rev-parse --is-inside-work-tree 2>$null) {
        $branch = (git symbolic-ref --short HEAD 2>$null)
        if (-not $branch) {
            $branch = (git rev-parse --short HEAD 2>$null)
        }
        if ($branch) {
            $gitInfo = " $esc[90mon$esc[0m $accent$branch$esc[0m"
        }
    }

    $symbol = [char]0x276F
    Write-Host ""
    Write-Host " $displayPath$gitInfo"
    return "$accent$symbol$esc[0m "
}

# === Claude + Copilot Dual Workflow ===
# Save Claude’s brainstorm into a temp file, then refine with Copilot

# Path for shared output
$claudeOut = "$env:USERPROFILE\claude_output.txt"

function Invoke-Claude {
    param([string]$Prompt)
    claude --prompt $Prompt | Out-File -FilePath $claudeOut -Encoding utf8
    Write-Host "Claude output saved to $claudeOut"
}

function Invoke-Copilot {
    param([string]$Task)
    if (Test-Path $claudeOut) {
        copilot --input $claudeOut --task $Task
    } else {
        Write-Host "No Claude output found. Run Invoke-Claude first."
    }
}

# Example shortcut: brainstorm + refine in one go
function DualAI {
    param([string]$Prompt, [string]$Task)
    Invoke-Claude -Prompt $Prompt
    Invoke-Copilot -Task $Task
}

# === Chocolatey Tab Completion ===
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
