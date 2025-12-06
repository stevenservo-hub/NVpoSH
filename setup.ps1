if ($IsWindows) {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
        Write-Error "Administrator privileges required on Windows."
        exit 1
    }

# This script relies on internet connection and DNS
if (-not (Test-Connection -ComputerName "www.google.com" -Count 1 -Quiet)) {
    Write-Error "Internet connection is required."
    exit 1
}

Clear-Host
$Banner = @"
███╗   ██╗██╗   ██╗██████╗  ██████╗ ███████╗██╗  ██╗
████╗  ██║██║   ██║██╔══██╗██╔═══██╗██╔════╝██║  ██║
██╔██╗ ██║██║   ██║██████╔╝██║   ██║███████╗███████║
██║╚██╗██║╚██╗ ██╔╝██╔═══╝ ██║   ██║╚════██║██╔══██║
██║ ╚████║ ╚████╔╝ ██║     ╚██████╔╝███████║██║  ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝
"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host "    Production-Ready Neovim for PowerShell Engineers" -ForegroundColor Gray
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

function Install-WingetPackage {
    param([string]$Id)

    $null = winget list -e --id $Id --accept-source-agreements 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing $Id...`n" -ForegroundColor Cyan
        winget install -e --id $Id --accept-package-agreements --accept-source-agreements --silent --force --disable-interactivity
    } else {
        Write-Host "$Id is already installed.`n" -ForegroundColor Green
    }
}

Install-WingetPackage -Id "Neovim.Neovim"
Install-WingetPackage -Id "Git.Git"
Install-WingetPackage -Id "OpenJS.NodeJS"
Install-WingetPackage -Id "JesseDuffield.lazygit"
Install-WingetPackage -Id "zig.zig"
Install-WingetPackage -Id "BurntSushi.ripgrep.MSVC"
Install-WingetPackage -Id "sharkdp.fd"
Install-WingetPackage -Id "Terrastruct.D2"
}

$Nerdfontcheck = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | 
    ForEach-Object { $_.PSObject.Properties.Name } | 
    Where-Object { $_ -match 'NerdFont' } | 
    Select-Object -First 1
	
if ($IsWindows -and -not $Nerdfontcheck) {
    Write-Host "Installing NerdFont...`n" -ForegroundColor Cyan
    & ([scriptblock]::Create((Invoke-WebRequest 'https://to.loredo.me/Install-NerdFont.ps1')))
} else {
	    Write-Host "NerdFont already installed`n" -ForegroundColor Green
}

$SourceDir = $PSScriptRoot

if ($IsWindows) {
    $TargetDir = Join-Path $env:LOCALAPPDATA "nvim"
} elseif ($IsLinux) {
    $TargetDir = Join-Path $HOME ".config/nvim"
} else {
    Write-Error "Unsupported Operating System."
    exit 1
}

if (Test-Path $TargetDir) {
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $BackupDir = "$TargetDir.bak.$Timestamp"
    Write-Host "Existing configuration found. Backing up to: $BackupDir`n" -ForegroundColor Yellow
    Rename-Item -Path $TargetDir -NewName $BackupDir
}

if (-not (Test-Path $TargetDir)) {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
}

Write-Host "Deploying configuration from $SourceDir to $TargetDir...`n" -ForegroundColor Cyan

Get-ChildItem -Path $SourceDir -Exclude ".git", ".gitignore", "README.md", "setup.ps1", "LICENSE" | Copy-Item -Destination $TargetDir -Recurse -Force

if (Test-Path (Join-Path $TargetDir "init.lua")) {
    Write-Host "Configuration deployed successfully.`n" -ForegroundColor Green
} else {
    Write-Error "Deployment failed: init.lua not found in target.`n"
}
Write-Host "Configuring PowerShell Profile...`n" -ForegroundColor Cyan

$ProfileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

$CurrentProfile = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if ($null -eq $CurrentProfile) { $CurrentProfile = "" }

$ConfigsToAdd = @()

# We regex escape the $ to literal match '$env:EDITOR'
if ($CurrentProfile -notmatch [regex]::Escape('$env:EDITOR')) {
    $ConfigsToAdd += '$env:EDITOR = "nvim"'
    $ConfigsToAdd += '$env:VISUAL = "nvim"'
} else {
    Write-Host "  [SKIP] Editor variable already defined in profile." -ForegroundColor Gray
}

if ($CurrentProfile -notmatch "\[Console\]::OutputEncoding") {
    $ConfigsToAdd += '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
} else {
    Write-Host "  [SKIP] Console Encoding already defined in profile." -ForegroundColor Gray
}

if ($CurrentProfile -notmatch "Set-Alias.*vi\b") {
    $ConfigsToAdd += "if (-not (Get-Alias vi -ErrorAction SilentlyContinue)) { Set-Alias -Name vi -Value nvim }"
    $ConfigsToAdd += "if (-not (Get-Alias vim -ErrorAction SilentlyContinue)) { Set-Alias -Name vim -Value nvim }"
} else {
    Write-Host "  [SKIP] 'vi'/'vim' aliases already defined in profile." -ForegroundColor Gray
}

if ($ConfigsToAdd.Count -gt 0) {
    Write-Host "  [UPDATE] Appending missing configurations..." -ForegroundColor Green
    
    Add-Content -Path $PROFILE -Value "`n# --- PoSH-Nvim Basics ---"
    foreach ($Line in $ConfigsToAdd) {
        Add-Content -Path $PROFILE -Value $Line
    }
} else {
    Write-Host "  [OK] Profile is already fully configured." -ForegroundColor Green}
