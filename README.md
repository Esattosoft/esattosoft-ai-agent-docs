<p align="center">
  <img src="assets/esattosoft-ai-logo.png" alt="Esattosoft AI Agent" width="150">
</p>

<h1 align="center">Esattosoft AI Agent</h1>

<p align="center">
  <strong>Local • Evidence-First • Ollama-Powered Coding Agent</strong>
</p>

<p align="center">
  A Windows terminal-based local AI coding workspace with evidence-first analysis, safe edits, approvals, sessions, project rules, model switching, and terminal workflows.
</p>

<p align="center">
  <a href="https://www.esattosoft.com">Website</a> •
  <a href="https://github.com/Esattosoft/esattosoft-ai-agent-docs/releases">Releases</a>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.6.14-blue">
  <img alt="Platform" src="https://img.shields.io/badge/Windows-x64-blue">
  <img alt="Ollama" src="https://img.shields.io/badge/Ollama-local%20models-black">
</p>

![Esattosoft AI Agent terminal](assets/esattosoft-ai-terminal.png)

## Install

### Requirements

- Windows 10/11 x64
- Ollama
- At least one Ollama model

Recommended lightweight model:

```powershell
ollama pull qwen3.5:4b
```

Install Esattosoft AI Agent:

```powershell
irm https://raw.githubusercontent.com/Esattosoft/esattosoft-ai-agent-docs/main/install.ps1 | iex
```

Then start:

```powershell
esattosoft-ai
```

The installer downloads the current Windows x64 release, verifies its SHA256 checksum, installs it under your user profile, and adds the install directory to your user PATH when needed.

## Highlights

- Local Ollama-powered coding workflow
- Evidence-first file analysis
- READ ONLY and WRITE modes
- Focused edits with diff preview
- Explicit approval gates
- Automatic edit backups
- Project history and project picker
- Global and project-level rules
- Session save and restore
- Read-only reference workspaces
- Smart large-paste collapsing
- Command-batch paste support
- Live token/timing metrics
- Ollama model selection and previous-model unload
- `/run` terminal command routing
- Ctrl+C / Esc cancellation
- Persistent terminal scrollback

## First Run

Useful commands:

```text
/status
/project <path>
/project list
/model
/models
/mode read
/mode write
/auto on
/auto off
/rules
/session restore last
/run ollama ps
```

## Releases

Windows binaries are published on the Releases page:

https://github.com/Esattosoft/esattosoft-ai-agent-docs/releases

Current release metadata is published in:

```text
latest.json
```

Each installer download is verified against the SHA256 value in the release metadata.

## Source Code

The Esattosoft AI Agent application source is maintained in a private development repository.

This public repository contains documentation, installer metadata, public assets, and release downloads.

## Privacy

Esattosoft AI Agent is designed to work with local Ollama models. Project analysis and model inference are performed through the user's local Ollama installation.

Always review diffs and terminal commands before approving write or execution actions.

## Support

Website: https://www.esattosoft.com  
GitHub: https://github.com/Esattosoft  
Public contact: knisar6464@gmail.com

## Copyright

Copyright © 2026 Esattosoft. All rights reserved.
