# Esattosoft AI Agent installer for Windows
# Public installer. Source repository may remain private.

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[Esattosoft] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Normalize-PathEntry {
    param([string]$PathValue)
    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return ""
    }
    return $PathValue.Trim().TrimEnd("\")
}

try {
    # PowerShell 5.1 compatibility for GitHub HTTPS.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {}

    if ($env:OS -ne "Windows_NT") {
        throw "This installer currently supports Windows only."
    }

    $arch = if ($env:PROCESSOR_ARCHITEW6432) {
        $env:PROCESSOR_ARCHITEW6432
    } else {
        $env:PROCESSOR_ARCHITECTURE
    }

    if ($arch -ne "AMD64") {
        throw "This release currently supports Windows x64 only. Detected architecture: $arch"
    }

    $metadataUrl = "https://raw.githubusercontent.com/Esattosoft/esattosoft-ai-agent-docs/main/latest.json"

    Write-Step "Checking latest release..."
    $release = Invoke-RestMethod -Uri $metadataUrl -UseBasicParsing

    if (-not $release.version -or -not $release.windows_x64 -or -not $release.sha256) {
        throw "Release metadata is incomplete."
    }

    Write-Step ("Latest version: " + $release.version)

    # Windows v1.6.17+ uses a Nuitka standalone ZIP. Keep all runtime files
    # together in a dedicated install directory and put that directory on PATH.
    $binRoot = Join-Path $HOME ".local\bin"
    $installDir = Join-Path $binRoot "esattosoft-ai"
    $installExe = Join-Path $installDir "esattosoft-ai.exe"

    # Legacy v1.6.14 installer placed a single EXE directly in ~/.local/bin.
    $legacyExe = Join-Path $binRoot "esattosoft-ai.exe"

    New-Item -ItemType Directory -Force -Path $binRoot | Out-Null

    $running = Get-Process -Name "esattosoft-ai" -ErrorAction SilentlyContinue
    if ($running) {
        throw "Esattosoft AI Agent is currently running. Close it and run the installer again."
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("esattosoft-ai-install-" + [guid]::NewGuid().ToString("N"))
    $tempZip = Join-Path $tempRoot "esattosoft-ai-windows-x64.zip"
    $extractDir = Join-Path $tempRoot "extract"
    $backupDir = Join-Path $binRoot ("esattosoft-ai-backup-" + [guid]::NewGuid().ToString("N"))

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    $installed = $false
    $backupCreated = $false

    try {
        Write-Step "Downloading Esattosoft AI Agent..."
        Invoke-WebRequest -Uri $release.windows_x64 -OutFile $tempZip -UseBasicParsing

        Write-Step "Verifying SHA256..."
        $actualHash = (Get-FileHash -Path $tempZip -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = ([string]$release.sha256).Trim().ToLowerInvariant()

        if ($actualHash -ne $expectedHash) {
            throw "SHA256 verification failed. Expected $expectedHash but received $actualHash."
        }

        Write-Ok "SHA256 verified."

        Write-Step "Extracting standalone package..."
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force

        $extractedExe = Join-Path $extractDir "esattosoft-ai.exe"
        if (-not (Test-Path $extractedExe -PathType Leaf)) {
            throw "Downloaded package is invalid: esattosoft-ai.exe was not found after extraction."
        }

        # Guard against an unexpectedly incomplete archive.
        $packageFiles = @(Get-ChildItem -Path $extractDir -Force)
        if ($packageFiles.Count -lt 2) {
            throw "Downloaded standalone package appears incomplete."
        }

        if (Test-Path $installDir) {
            Move-Item -Path $installDir -Destination $backupDir
            $backupCreated = $true
        }

        try {
            Move-Item -Path $extractDir -Destination $installDir

            if (-not (Test-Path $installExe -PathType Leaf)) {
                throw "Installation validation failed: executable is missing from the install directory."
            }

            # Remove the legacy single-file installation only after the new
            # standalone package has been placed successfully.
            if (Test-Path $legacyExe -PathType Leaf) {
                Remove-Item -Path $legacyExe -Force
                Write-Ok "Removed legacy single-file installation."
            }

            $installed = $true
        }
        catch {
            if (Test-Path $installDir) {
                Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
            }

            if ($backupCreated -and (Test-Path $backupDir)) {
                Move-Item -Path $backupDir -Destination $installDir
                $backupCreated = $false
            }

            throw
        }

        if ($backupCreated -and (Test-Path $backupDir)) {
            Remove-Item $backupDir -Recurse -Force -ErrorAction SilentlyContinue
            $backupCreated = $false
        }

        Write-Ok ("Installed standalone package to " + $installDir)
    }
    finally {
        if (-not $installed -and $backupCreated -and (Test-Path $backupDir) -and -not (Test-Path $installDir)) {
            Move-Item -Path $backupDir -Destination $installDir -ErrorAction SilentlyContinue
        }

        if (Test-Path $tempRoot) {
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Add the standalone package directory to the user's PATH.
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) {
        $userPath = ""
    }

    $wantedPath = Normalize-PathEntry $installDir
    $pathEntries = @($userPath -split ";" | Where-Object { $_ -and $_.Trim() })
    $alreadyOnPath = $false

    foreach ($entry in $pathEntries) {
        if ((Normalize-PathEntry $entry) -ieq $wantedPath) {
            $alreadyOnPath = $true
            break
        }
    }

    if (-not $alreadyOnPath) {
        $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
            $installDir
        } else {
            $userPath.TrimEnd(";") + ";" + $installDir
        }

        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Ok ("Added " + $installDir + " to the user PATH.")
        Write-Warn "Open a new PowerShell window before using 'esattosoft-ai' by name."
    }

    $currentEntries = @($env:Path -split ";" | Where-Object { $_ -and $_.Trim() })
    $currentHasInstallDir = $false

    foreach ($entry in $currentEntries) {
        if ((Normalize-PathEntry $entry) -ieq $wantedPath) {
            $currentHasInstallDir = $true
            break
        }
    }

    if (-not $currentHasInstallDir) {
        $env:Path = $env:Path.TrimEnd(";") + ";" + $installDir
    }

    Write-Host ""
    Write-Ok ("Esattosoft AI Agent v" + $release.version + " installed.")

    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollama) {
        Write-Ok "Ollama detected."
        Write-Host ""
        Write-Host "Recommended lightweight model:" -ForegroundColor White
        Write-Host "  ollama pull qwen3.5:4b" -ForegroundColor Cyan
    } else {
        Write-Warn "Ollama was not detected."
        Write-Host "Install Ollama, then pull a model before using the agent:" -ForegroundColor White
        Write-Host "  https://ollama.com" -ForegroundColor Cyan
        Write-Host "  ollama pull qwen3.5:4b" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "Start Esattosoft AI Agent:" -ForegroundColor White
    Write-Host "  esattosoft-ai" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: https://www.esattosoft.com" -ForegroundColor DarkGray
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
