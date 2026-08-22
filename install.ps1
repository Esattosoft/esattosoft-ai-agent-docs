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

try {
    # PowerShell 5.1 compatibility for GitHub HTTPS.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {}

    $isWindows = $env:OS -eq "Windows_NT"
    if (-not $isWindows) {
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

    $installDir = Join-Path $HOME ".local\bin"
    $installPath = Join-Path $installDir "esattosoft-ai.exe"

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("esattosoft-ai-install-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $tempExe = Join-Path $tempRoot "esattosoft-ai.exe"

    try {
        Write-Step "Downloading Esattosoft AI Agent..."
        Invoke-WebRequest -Uri $release.windows_x64 -OutFile $tempExe -UseBasicParsing

        Write-Step "Verifying SHA256..."
        $actualHash = (Get-FileHash -Path $tempExe -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = ([string]$release.sha256).Trim().ToLowerInvariant()

        if ($actualHash -ne $expectedHash) {
            throw "SHA256 verification failed. Expected $expectedHash but received $actualHash."
        }

        Write-Ok "SHA256 verified."

        # A running executable cannot safely be overwritten.
        $running = Get-Process -Name "esattosoft-ai" -ErrorAction SilentlyContinue
        if ($running) {
            throw "Esattosoft AI Agent is currently running. Close it and run the installer again."
        }

        Copy-Item -Path $tempExe -Destination $installPath -Force
        Write-Ok ("Installed to " + $installPath)
    }
    finally {
        if (Test-Path $tempRoot) {
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Add ~/.local/bin to the user's PATH if needed.
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) {
        $userPath = ""
    }

    $pathEntries = @($userPath -split ";" | Where-Object { $_ -and $_.Trim() })
    $alreadyOnPath = $false
    foreach ($entry in $pathEntries) {
        if ($entry.TrimEnd("\") -ieq $installDir.TrimEnd("\")) {
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

    if (($env:Path -split ";") -notcontains $installDir) {
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
