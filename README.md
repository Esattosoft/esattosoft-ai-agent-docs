<p align="center">
  <img src="assets/esattosoft-ai-logo.png" alt="Esattosoft AI Agent" width="150">
</p>

<h1 align="center">Esattosoft AI Agent</h1>

<p align="center">
  <strong>Local • Evidence-First • Ollama-Powered Coding Agent</strong>
</p>

<p align="center">
  A terminal-based local AI coding workspace focused on evidence-first analysis, safe edits, explicit approvals, project rules, session restore, and Ollama model control.
</p>

<p align="center">
  <a href="https://www.esattosoft.com">Website</a> •
  <a href="https://github.com/Esattosoft/esattosoft-ai-agent/releases">Releases</a> •
  <a href="LICENSE">MIT License</a>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.6.14-blue">
  <img alt="Python" src="https://img.shields.io/badge/Python-3.10%2B-blue">
  <img alt="Ollama" src="https://img.shields.io/badge/Ollama-local%20models-black">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
</p>

![Esattosoft AI Agent terminal](assets/esattosoft-ai-terminal.png)

## Why Esattosoft AI Agent?

Esattosoft AI Agent is designed for developers who want a local coding assistant without sending project code to a hosted model by default. It works with Ollama and keeps the coding workflow centered around verified project evidence.

The agent can inspect project files, analyze code, prepare focused edits, preview diffs, ask for approval before writes, run terminal commands through a safety gate, remember project history, restore previous sessions, apply global/project rules, and switch between installed Ollama models.

## Highlights

- Local Ollama-powered coding workflow
- Evidence-first file analysis
- READ ONLY and WRITE modes
- Autonomous task routing with a plain-chat guard
- Focused file editing with diff preview
- Deterministic exact-edit protection for narrow replacements
- Approval gates for file edits, file creation, and terminal commands
- Automatic edit backups
- Project history and project picker
- Global and project-level engineering rules
- Session save and restore with recent-conversation preview
- Reference workspaces for read-only comparison
- Smart large-paste collapsing
- Multi-command paste batches
- Live token, timing, prompt, and tokens-per-second metrics
- Ollama model selection and previous-model unload
- Ctrl+C / Esc cancellation support
- Persistent terminal scrollback during normal workspace changes

## Requirements

Before installing, make sure you have:

- Python 3.10 or newer
- Git
- Ollama
- At least one Ollama model

> **Tested release environment:** Windows + PowerShell. macOS/Linux support has not yet been formally verified for v1.6.14.

Recommended model for a lightweight local setup:

```bash
ollama pull qwen3.5:4b
```

You can use `/model` inside the agent to select another installed Ollama model.

## Quick Install

### Windows PowerShell

Install `pipx`:

```powershell
py -m pip install --user pipx
py -m pipx ensurepath
```

If you want to use a specific Python version, for example Python 3.13:

```powershell
py -3.13 -m pip install --user pipx
py -3.13 -m pipx ensurepath
```

Close and reopen PowerShell if the `pipx` command is not immediately available.

Install Esattosoft AI Agent directly from GitHub:

```powershell
py -m pipx install git+https://github.com/Esattosoft/esattosoft-ai-agent.git
```

Or with a specific Python version:

```powershell
py -3.13 -m pipx install git+https://github.com/Esattosoft/esattosoft-ai-agent.git
```

Start the agent:

```powershell
esattosoft-ai
```

### macOS / Linux

v1.6.14 has not yet been formally verified on macOS/Linux. The expected installation flow is:

```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
python3 -m pipx install git+https://github.com/Esattosoft/esattosoft-ai-agent.git
esattosoft-ai
```

Please report platform-specific issues through GitHub Issues.

## First Run

On first launch, Esattosoft AI Agent creates its local workspace configuration under your user profile.

Useful commands:

```text
/project <path>      Select a target project
/project list        Open recent project list
/status              Show current runtime status
/model               Select an installed Ollama model
/models              List installed Ollama models
/mode read           Enable READ ONLY mode
/mode write          Enable WRITE mode
/auto on             Enable autonomous task routing
/auto off            Disable autonomous task routing
```

Example:

```text
You > /project D:\Projects\demo-project
You > analyze index.php
```

## Safe Editing Workflow

A typical edit workflow looks like this:

```text
You > /mode write
You > /edit @app.php change the heading from Hello to Welcome
```

The agent:

1. Resolves the target file.
2. Reads existing project evidence.
3. Prepares the smallest focused change.
4. Shows a diff preview.
5. Requests approval.
6. Creates a backup.
7. Writes only after approval.

For exact replacements, the agent can detect when the requested state is already satisfied and avoid unnecessary model calls or file rewrites.

## Large Prompt Paste

Large multi-line prompts collapse while you paste them:

```text
You > [Pasted text #1 +30 lines]
```

The full original prompt is still used internally.

When a large paste is waiting to be sent, the prompt shows:

```text
Paste captured • Enter = send
```

This keeps the terminal readable without losing the full request.

## Terminal Commands

Use `/run` for terminal commands:

```text
/run ollama ps
/run git status
/run python --version
```

Read-only inspection commands can run in READ ONLY mode after approval.

Commands that may change files or system state require WRITE mode.

`/run` is a terminal-only route and does not fall through to AI chat or autonomous planning.

## Model Management

Open the model selector:

```text
/model
```

When you switch models, Esattosoft AI Agent stops the previously active Ollama model so memory can be released.

The new model loads lazily when the next AI request is sent.

You can inspect loaded Ollama models with:

```text
/run ollama ps
```

## Project Rules

Global rules are stored in the agent's local configuration directory.

Create project-specific rules:

```text
/rules init
```

Reload rules after editing:

```text
/rules reload
```

Show active rules:

```text
/rules show
```

Project rules allow you to document framework versions, protected files, coding conventions, validation commands, UI constraints, and other project-specific requirements.

See:

- `GLOBAL_RULES.default.md`
- `PROJECT_RULES.example.md`

## Sessions

Clear the current conversation while saving it:

```text
/clear
```

Restore the most recent session:

```text
/session restore last
```

The restore view includes:

- saved date/time
- project
- message count
- recent conversation preview
- restored model/mode/auto/project state

## Reference Workspaces

Reference workspaces are always read-only.

Useful commands:

```text
/reference <path>
/references
/reference remove
/reference clear
/compare
```

You can also reference files directly:

```text
@ref1:path/to/file.php
```

## Configuration

Show runtime configuration:

```text
/config
```

Example:

```text
/config set ollama.num_ctx 4096
/config reload
```

A public example configuration is included in:

```text
config.example.json
```

## Recommended Public Default

For CPU-only or lightweight machines, `qwen3.5:4b` is the recommended starting model.

Larger models can provide different coding behavior but may require substantially more RAM and prompt-processing time.

## Install from Source

```bash
git clone https://github.com/Esattosoft/esattosoft-ai-agent.git
cd esattosoft-ai-agent
python -m pip install -e .
esattosoft-ai
```

## Update

Until a package index release is published, the simplest update path is:

```powershell
py -3.13 -m pipx uninstall esattosoft-ai-agent
py -3.13 -m pipx install git+https://github.com/Esattosoft/esattosoft-ai-agent.git
```

Your local workspace configuration is stored separately from the pipx environment.

## Uninstall

```powershell
py -3.13 -m pipx uninstall esattosoft-ai-agent
```

This removes the installed CLI package.

Your local agent configuration may remain in your user profile so sessions, project history, and settings can survive reinstalls.

## Repository Files

```text
agent.py                  Main agent runtime
cli.py                    CLI entry point
version.py                Package version
pyproject.toml            Python package configuration
requirements.txt          Runtime dependencies
config.example.json       Example runtime configuration
GLOBAL_RULES.default.md   Default global engineering rules
PROJECT_RULES.example.md  Project rules example
PROMPTS.md                Prompt behavior/reference
CHANGELOG.md              Release history
DEVELOPER_GUIDE.md        Development and release documentation
LICENSE                   MIT License
```

## Privacy

Esattosoft AI Agent is designed to work with local Ollama models. Project files are analyzed locally by the agent and the selected Ollama model.

Always review commands and diffs before approving write or terminal actions.

## License

Released under the MIT License.

See [LICENSE](LICENSE).

## Author

**Esattosoft**
**Code with Khurram Nisar**

Website: https://www.esattosoft.com
GitHub: https://github.com/Esattosoft
Public contact: knisar6464@gmail.com
