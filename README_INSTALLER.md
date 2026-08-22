# Esattosoft AI Agent — Public Installer Files

This folder contains the public installer-side files for the closed-source distribution model.

## Files

- `install.ps1` — Windows x64 installer
- `latest.json` — release metadata used by the installer

## Public install command

```powershell
irm https://raw.githubusercontent.com/Esattosoft/esattosoft-ai-agent-docs/main/install.ps1 | iex
```

## Current release

- Version: `1.6.14`
- Binary: `esattosoft-ai-windows-x64.exe`
- SHA256: `42112b58250d80b5c42a170b9faa9d963371efd4290dc284e00d6cd3601883f1`

The source repository can remain private. The compiled binary is published as a release asset in the public docs repository.
