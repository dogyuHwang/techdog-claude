[한국어](README.md) | English

# TechDog Claude (tdc)

<p align="center">
  <img src="tdc.png" alt="TechDog Claude" width="400" />
</p>

> A multi-agent development orchestration system for Claude Code

**Write what you want to build in a doc, run `/tdc spec.md`, and a team of AI agents handles everything from planning to development.**

[Get Started](#what-is-this) | [Install](#installation) | [Usage](#usage-step-by-step) | [Commands](#command-reference) | [Architecture](#architecture) | [FAQ](#faq)

---

## What Is This?

[Claude Code](https://claude.ai/code) is a tool that lets you write code by chatting with AI in the terminal.

TechDog Claude (tdc) places **6 specialized AI agents** on top of Claude Code,
turning solo coding into a **team development** experience.

```
Normally:  You <-> Claude (1:1 conversation)

tdc:       You -> Master Agent -> Planner    (planning)
                                -> Developer  (development)
                                -> Debugger   (debugging)
                                -> Reviewer   (review)
                                -> Architect  (design)
```

---

## Installation

### Prerequisites

1. **Node.js** (18 or above) -- [Install](https://nodejs.org/)
2. **Claude Code** installed:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```
3. Log in to Claude Code:
   ```bash
   claude    # Follow the login instructions on first run
   ```

### Install tdc

```bash
# Option A: Remote install (recommended)
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

# Option B: Clone and install
git clone https://github.com/dogyuHwang/techdog-claude.git
cd techdog-claude && bash install.sh
```

The installer automatically:
- Adds the `/tdc` slash command to Claude Code (installed in `~/.claude/skills/`)
- Installs [rtk](https://github.com/rtk-ai/rtk) (a tool that reduces tokens by 60-90%)
- Enables Claude Code Team mode

> You can start using it immediately after installation. Run `claude` in your terminal and type `/tdc spec.md`.

---

## Usage (Step by Step)

### 1. Write a Spec File

A **spec file** is a document describing what you want to build.
The format is flexible -- just create a `spec.md` file with any text editor.

**Example -- Simple web server:**

```markdown
# My Blog API

## Purpose
A REST API server to manage blog posts

## Tech Stack
- Python + Flask
- SQLite

## Features
- Create posts (title, content, author)
- List posts
- Update / delete posts
- Health check endpoint
```

**Example -- React app:**

```markdown
# Todo App

## Purpose
A simple Todo application

## Tech Stack
- React + TypeScript
- localStorage for persistence

## Features
- Add / delete / complete todos
- Filter (all / completed / incomplete)
- Dark mode
```

**Example -- CLI tool:**

```markdown
# File Organizer Script

## Purpose
Automatically sort files in the Downloads folder by extension

## Tech Stack
- Python

## Features
- Scan a specified folder
- Move files into subfolders by extension (images/, docs/, videos/, etc.)
- Detect duplicate files
- Dry-run mode (preview without actually moving)
```

> Korean and English both work. It doesn't have to be perfect -- the AI will ask if anything is unclear.

### 2. Run

Open Claude Code in your terminal and type the `/tdc` command:

```bash
claude               # Launch Claude Code
```

In the Claude Code prompt:

```
/tdc spec.md
```

The **Master Agent then handles everything automatically:**

```
/tdc spec.md   <-- Just type this and you're done!
    |
[Auto] Planner Agent analyzes the spec and breaks it into tasks
    |
[Auto] Developer Agent writes code for each task
    | (error occurs?)
[Auto] Debugger Agent finds the cause and fixes it  <-- No user intervention needed
    |
[Auto] Tests/linters run -> Debugger auto-fixes on failure
    |
[Auto] Reviewer Agent reviews the finished code
    | (serious issues found?)
[Auto] Developer Agent makes corrections  <-- No user intervention needed
    |
Final results are reported to the user
```

> **Key point:** The agents communicate with each other automatically through the Master Agent.
> If an error occurs during development, the Debugger is called automatically. If the review
> finds issues, the Developer fixes them automatically. **You only need to give input once at the start.**

### 3. Individual Commands (Optional)

Use these when you want to run a specific stage separately instead of the full pipeline.
**You won't normally need these** -- `/tdc spec.md` alone is enough.

```
/tdc-plan spec.md     <-- When you only want to plan without developing yet
/tdc-dev              <-- When planning is done and you just want to start coding
/tdc-debug <error>    <-- When you find a new error in existing code
/tdc-review           <-- When you want a review of code you wrote yourself
```

### 4. When Work Takes Long (Session Management)

If you see a "context usage is high" warning during a long session:

```
/tdc-session save      # Save your progress so far
```

Reopen Claude Code and:

```
/tdc-session resume    # Continue from where you left off
```

---

## Command Reference

All commands are used **inside the Claude Code prompt**.
(The prompt that appears after running `claude` in your terminal)

### Main Commands (usually all you need)

| What you type | What happens |
|---------------|-------------|
| `/tdc spec.md` | Reads the spec file and **automatically runs planning -> development -> debugging -> review** |
| `/tdc Add a login feature` | Give instructions as text (full auto pipeline without a spec file) |

### Individual Commands (when you want a specific stage only)

| What you type | When to use it |
|---------------|---------------|
| `/tdc-plan spec.md` | When you want to preview the plan (no development yet) |
| `/tdc-dev` | When planning is done and you want to start development |
| `/tdc-debug <error details>` | When you find a new bug in existing code |
| `/tdc-review` | When you want a review of code you wrote yourself |

### Session Management

| What you type | What happens |
|---------------|-------------|
| `/tdc-session save` | Saves current progress to a file |
| `/tdc-session resume` | Resumes work from a saved session |
| `/tdc-session list` | Lists saved sessions |
| `/tdc-session clean` | Deletes sessions older than 7 days |

---

## Architecture

### Agent Team Structure

```
User: /tdc spec.md  (just type this)
              |
+--- Master Agent (opus) --- Team leader, runs everything automatically ---+
|                                                                          |
|   [Phase 1] Planner (sonnet) -- Spec -> Task breakdown                   |
|       | auto                                                             |
|   [Phase 2] Developer (sonnet) -- Code implementation per task           |
|       | error?                                                           |
|       +-> Debugger (sonnet) -- Auto diagnose & fix -> Developer resumes  |
|       | auto                                                             |
|   [Phase 3] Reviewer (haiku) -- Automated code review                   |
|       | issues found?                                                    |
|       +-> code-level -> Developer fixes                                  |
|       +-> design-level -> Planner re-plans -> Developer re-implements    |
|       +-> critical -> Planner re-plans + Developer urgent fix            |
|       | auto                                                             |
|   [Phase 4] Final results reported to user                               |
|                                                                          |
|   * Architect (opus) -- Called automatically only for design decisions    |
+--------------------------------------------------------------------------+

Inter-agent communication (shown in real-time via Live Dashboard):
  Master acts as the central hub. Agents don't communicate directly --
  they receive only the necessary context through Master.
  All communication is displayed to the user in real-time and logged.

  Planner results -> (Master summarizes) -> Passed to Developer
  Developer error -> (Master detects) -> Debugger auto-called
  Reviewer issues -> (Master assesses severity) ->
    code-level: Developer instructed to fix
    design-level: Planner asked to re-plan -> Developer re-implements
```

### Real-time Progress (Triple Visibility)

When you run `/tdc spec.md`, you can monitor agent activity in **3 ways** in real-time:

#### 1. Status Line (always visible at the bottom of the terminal)

The current status is always shown at the bottom of the terminal:

```
[TDC] Phase 2/4 -- IMPLEMENTATION | developer working | 45 tools
```

It updates automatically whenever the active agent changes.

#### 2. Console Messages (agent start/completion notifications)

Messages are displayed automatically when an agent starts or finishes:

```
[TDC] planner agent started (14:03:01)
[TDC] planner agent completed (21s)
[TDC] developer agent started (14:03:23)
[TDC] developer agent completed (22s)
```

#### 3. Dashboard Banners (detailed logs on phase transitions)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 1 -- PLANNING                        [1/4]
  Planner Agent is analyzing the spec...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  14:03:01 [Master -> Planner] Spec file delivered
  14:03:22 [Planner -> Master] 5 tasks broken down (21s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 2 -- IMPLEMENTATION                  [2/4]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  14:03:23 [Master -> Developer] Task 1/5: "Implement DB models"
  14:03:45 [Developer -> Master] Complete (22s)
  14:03:46 [Master -> Developer] Task 2/5: "API endpoints"
  14:04:10 [Developer -> Master] Error occurred!
  14:04:10 [Master -> Debugger] Auto diagnosis requested
  14:04:25 [Debugger -> Master] Fix complete (15s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 4 -- COMPLETE                        [4/4]
  All work is done!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

A full record of all inter-agent interactions is saved in `.tdc/context/agent-log.md`.

### Why Split Into Agents?

| Agent | AI Model | Cost | Role |
|-------|----------|------|------|
| **Master** | opus (high-performance) | High | Overall orchestration. Decides who does what |
| **Planner** | sonnet (general-purpose) | Medium | Defines "what needs to be built" |
| **Developer** | sonnet (general-purpose) | Medium | Writes the actual code |
| **Debugger** | sonnet (general-purpose) | Medium | Finds and fixes bugs |
| **Reviewer** | haiku (lightweight) | Low | Code review (fast and cheap) |
| **Architect** | opus (high-performance) | High | Big-picture design (only when needed) |

There's no need to use expensive opus for a simple review.
By matching models to roles, **costs are reduced by 30-50%**.

### Token Reduction Strategy

| Method | Description | Savings |
|--------|-------------|---------|
| **Model tiering** | Route to haiku/sonnet/opus based on role | 30-50% |
| **rtk** | Auto-compress command output ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) | 60-90% |
| **Context compression** | Auto-summarize old conversations and start new sessions | Deduplication |
| **Minimal context passing** | Pass only necessary information to each agent | Eliminate unnecessary tokens |
| **Session save/resume** | No need to re-explain from scratch | Prevent rework |

### Session Management (Context Overflow)

When you chat with AI for a long time, the "context" fills up and it starts forgetting earlier content.
tdc handles this automatically:

```
Chatting...
  | (80 tool calls) -> "Context is high" warning
  | (120 tool calls) -> Progress auto-saved (including completed/pending tasks and changed files)
  |
/tdc-session resume  ->  Loads previous context and continues
```

---

## Directory Structure

```
~/.tdc/                             # Global install (created by install.sh)
  hooks/                            # Automation scripts
  state/sessions/                   # Session data
  state/context/                    # Context monitoring

~/.claude/                          # Path that Claude Code reads (created by install.sh)
  skills/                           # /tdc slash commands (must be here to be recognized)
    tdc/SKILL.md
    tdc-plan/SKILL.md
    tdc-dev/SKILL.md
    ...
  agents/                           # Agent definitions
    master.md, planner.md, ...

your-project/                       # Your project folder
├── .tdc/                           # Auto-created on first /tdc run
│   ├── sessions/                   # Saved sessions
│   ├── context/                    # Context monitoring
│   └── plans/                      # Generated plans
├── spec.md                         # Your spec file
└── (your code...)
```

---

## FAQ

**Q: What is Claude Code?**
A: It's an AI coding tool made by Anthropic. Run `claude` in your terminal to launch it.
See [claude.ai/code](https://claude.ai/code) for more details.

**Q: Does it cost money?**
A: Claude Code is billed based on Anthropic API usage.
tdc itself is free, and it minimizes costs through model tiering and rtk.

**Q: Do I have to write a spec.md?**
A: No. You can type instructions directly, like `/tdc Add a login feature`.
However, the more complex the project, the better results you get with a spec file.

**Q: What languages/frameworks are supported?**
A: There are no restrictions. Python, JavaScript, TypeScript, Go, Rust, Java, Swift, Kotlin, and more --
you can develop in any language that Claude supports.

**Q: Can I use it with an existing project?**
A: Yes. Run `claude` in your existing project folder and type `/tdc spec.md`.

---

## Uninstall

```bash
# One-liner uninstall (recommended)
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/uninstall.sh | bash

# Or from the cloned folder
bash uninstall.sh
```

This automatically cleans up skills, agents, global files (`~/.tdc/`), and settings.json hook configurations.
rtk is a separate tool and is not removed (`brew uninstall rtk` to remove it separately).

---

## Troubleshooting

**"Unknown skill" error when typing `/tdc`**
- Check if `~/.claude/skills/tdc/SKILL.md` exists
- If not: reinstall with `curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash`

**Settings Error (Invalid key)**
- There may be an invalid hook key in `~/.claude/settings.json`
- Reinstalling will fix it automatically

**rtk is not working**
- Check `rtk --version`
- If it fails: `brew install rtk` or reinstall

---

## Requirements

- [Claude Code](https://claude.ai/code) v2.0+
- macOS or Linux
- Node.js 18+
- bash 4+
- python3
- git

## Maintenance

For adding agents, changing skills, or modifying the architecture, see [MAINTENANCE.md](MAINTENANCE.md).

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) -- Claude Code multi-agent framework
- [rtk](https://github.com/rtk-ai/rtk) -- LLM token reduction CLI proxy

## License

MIT
