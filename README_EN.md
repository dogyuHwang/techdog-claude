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

TechDog Claude (tdc) places **8 specialized AI agents** on top of Claude Code,
turning solo coding into a **team development** experience.

```
Normally:  You <-> Claude (1:1 conversation)

tdc:       You -> Master Agent -> Planner           (planning)
                                -> Developer          (development)
                                -> Debugger           (debugging)
                                -> Reviewer           (review)
                                -> Security Reviewer  (security audit)
                                -> Test Engineer      (test generation)
                                -> Architect          (design)
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
- **Language skill packs** selectable install (Python/Django, Next.js, Go, Rust, Java, Flutter, Kotlin, React)

Language skill pack selection during install:
```
=== Language Skill Pack Installation ===

  1) Install all (All skill packs)
  2) Choose individually
  3) Core only (no skill packs)

  Choose (1/2/3) [1]:
```

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

#### Normal Mode — auto pipeline from planning to development
```
/tdc spec.md
```

#### Deep Mode — repeats until every check passes
```
/tdc deep spec.md
```

> **Normal mode** runs plan -> develop -> review once and completes.
> **Deep mode** keeps iterating until tests pass + build succeeds + review is APPROVED — **all checks must pass**.
> Use Deep mode for quality-critical work.

Either way, the **Master Agent handles everything automatically:**

```
/tdc spec.md (or /tdc deep spec.md)   <-- Just type this and you're done!
    |
[If needed] AI asks clarifying questions once before starting (skipped if spec is clear)
    |
[Auto] Planner Agent analyzes the spec and breaks it into tasks
    |
[Auto] Developer Agent writes code for each task
    | (error occurs?)
[Auto] Debugger Agent finds the cause and fixes it  <-- No user intervention needed
    |
[Auto] Tests/linters run -> Debugger auto-fixes on failure
    |
[Auto] Reviewer + Security Reviewer audit the code
    | (serious issues found?)
[Auto] Developer Agent makes corrections  <-- No user intervention needed
    | (Deep mode?)
[Auto] Repeats until tests + build + review ALL pass  <-- Never cuts corners
    |
Final results reported to the user (with per-agent token usage)
```

> **Key point:** The agents communicate with each other automatically through the Master Agent.
> **You only need to give input once at the start.**

### 3. Individual Commands (Optional)

Use these when you want to run a specific stage separately instead of the full pipeline.
**You won't normally need these** -- `/tdc spec.md` alone is enough.

```
/tdc-plan spec.md     <-- When you only want to plan without developing yet
/tdc-dev              <-- When planning is done and you just want to start coding
/tdc-debug <error>    <-- When you find a new error in existing code
/tdc-review           <-- When you want a review of code you wrote yourself
/tdc onboard          <-- First time using tdc in an existing project (auto-analyze)
/tdc upgrade          <-- Update tdc to the latest version
```

### 4. Project Onboarding (first time using tdc in an existing project)

When using tdc for the first time in an existing project, run this once:

```
/tdc onboard
```

This **auto-analyzes** your project's tech stack, coding conventions, directory structure, and build commands,
saving them to `.tdc/project-memory.md`.

Future `/tdc spec.md` runs will automatically use this information for more accurate code generation.

### 5. Update

```
/tdc upgrade
```

Updates tdc's skills, agents, and hooks to the latest version.
Project-specific data (sessions, plans, memory) is preserved.
You'll be notified automatically when a new version is available.

### 6. When Work Takes Long (Session Management)

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

| What you type | Mode | What happens |
|---------------|------|-------------|
| `/tdc spec.md` | Normal | **Auto pipeline**: planning -> development -> review |
| `/tdc deep spec.md` | Deep | Normal + **repeats until all tests/build/review pass** |
| `/tdc Add a login feature` | Normal | Text instructions without a spec file |
| `/tdc deep Build a payment system` | Deep | Text instructions + thorough verification |

### Individual Commands (when you want a specific stage only)

| What you type | When to use it |
|---------------|---------------|
| `/tdc-plan spec.md` | When you want to preview the plan (no development yet) |
| `/tdc-dev` | When planning is done and you want to start development |
| `/tdc-debug <error details>` | When you find a new bug in existing code |
| `/tdc-review` | When you want a review of code you wrote yourself |
| `/tdc onboard` | Auto-analyze project when first adopting tdc |
| `/tdc upgrade` | Update tdc to the latest version |

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

### Parallel Development (git worktree)

When there are multiple independent tasks, they run **in parallel via git worktree**:

```
[TDC] Phase 2 — Parallel execution (3 independent tasks)
  [TDC] developer-1 working on Task 1: "DB model" (worktree)
  [TDC] developer-2 working on Task 3: "Frontend" (worktree)

[TDC] developer-1 completed Task 1 (15s)
[TDC] developer-2 completed Task 3 (22s)
[TDC] Worktrees merged successfully
[TDC] Continuing with dependent tasks...
```

The Planner analyzes task dependencies to identify independent tasks,
and each Developer works simultaneously in a separate worktree.
After completion, changes are auto-merged. Conflicts are resolved by the Debugger.

### Real-time Progress (Triple Visibility)

When you run `/tdc spec.md`, you can monitor agent activity in **3 ways** in real-time:

#### 1. Status Line (always visible at the bottom of the terminal)

The current status is always shown at the bottom of the terminal:

```
[TDC] Phase 2/4 -- IMPLEMENTATION | developer[sonnet] working | ~14.0k tokens | 45 tools | rtk:99.7%
```

Agent name, **model tier**, cumulative tokens, and rtk status update in real-time.

#### 2. Console Messages (agent start/completion with model name)

Messages with **model name** are displayed automatically when an agent starts or finishes:

```
[TDC] planner agent started [sonnet] (14:03:01)
[TDC] planner [sonnet] completed (21s) — Token Usage:
       planner    ██████████ ~2.4k (100%)
       ──────────── total: ~2.4k
[TDC] developer agent started [sonnet] (14:03:23) — cumulative: ~2.4k tokens
[TDC] developer [sonnet] completed (22s) — Token Usage:
       planner    ██░░░░░░░░ ~2.4k (17%)
       developer  ██████████ ~8.8k (63%)
       ──────────── total: ~11.2k
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
| **Security Reviewer** | haiku (lightweight) | Low | OWASP security vulnerability audit |
| **Test Engineer** | sonnet (general-purpose) | Medium | Test coverage analysis + auto test generation |
| **Architect** | opus (high-performance) | High | Big-picture design (only when needed) |

There's no need to use expensive opus for a simple review.
By matching models to roles, **costs are reduced by 30-50%**.

### Real-time Token Dashboard

A **cumulative token gauge updates in real-time** as each agent completes:

```
[TDC] developer [sonnet] completed (22s) — Token Usage:
       planner(sonnet)    ██░░░░░░░░ ~2.4k (17%)
       developer(sonnet)  ████████░░ ~8.8k (63%)
       debugger(sonnet)   ██░░░░░░░░ ~2.8k (20%)
       ──────────────────── total: ~14.0k
```

Phase 4 includes a full summary with rtk savings estimate and cost estimate.

### Token Reduction Strategy

| Method | Description | Savings |
|--------|-------------|---------|
| **Model tiering** | Route to haiku/sonnet/opus based on role | 30-50% |
| **rtk** | Auto-compress command output ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) | 60-90% |
| **Smart Read** | Detect large file reads + force targeted reads (Grep first, offset/limit required) | 40-60% |
| **Diff-Only Review** | Send only `git diff` to Reviewer instead of full files | 50-70% |
| **Preemptive Compaction** | Auto-save state before context compression | Prevent context loss |
| **Rate Limit Guard** | Auto-detect API limits + wait guidance | Prevent session interruption |
| **Project Memory** | Persist project knowledge across sessions | Eliminate re-explanation |
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
  skills/                           # /tdc slash commands + language skill packs
    tdc/SKILL.md                    # Main entry point
    tdc-plan/ tdc-dev/ ...          # Individual commands
    tdc-learn/SKILL.md              # Skill learning
    tdc-stack-python-django/        # Language skill packs (selectable)
    tdc-stack-ts-nextjs/
    tdc-stack-go/ tdc-stack-rust/
    tdc-stack-java/ tdc-stack-react/
    tdc-stack-flutter/ tdc-stack-kotlin/
  agents/                           # Agent definitions (8)
    master.md, planner.md, developer.md, debugger.md,
    reviewer.md, security-reviewer.md, test-engineer.md, architect.md

your-project/                       # Your project folder
├── .tdc/                           # Auto-created on first /tdc run
│   ├── sessions/                   # Saved sessions
│   ├── context/                    # Context monitoring + token tracking
│   ├── plans/                      # Generated plans
│   ├── learned-skills/             # Auto-learned skill patterns
│   └── project-memory.md           # Project knowledge (persists across sessions)
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
# Option A: From the cloned folder (recommended)
bash uninstall.sh

# Option B: Download and run remote script
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/uninstall.sh -o /tmp/tdc-uninstall.sh && bash /tmp/tdc-uninstall.sh
```

> **Safety:** You must type `y` and press Enter to confirm deletion.

This automatically cleans up skills, agents, skill packs, global files (`~/.tdc/`), and settings.json hook configurations.
You will be prompted whether to also remove rtk (token optimizer).

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
- jq (required for rtk token compression — install.sh auto-installs)

## Maintenance

For adding agents, changing skills, or modifying the architecture, see [MAINTENANCE.md](MAINTENANCE.md).

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) -- Claude Code multi-agent framework
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) -- Claude Code all-in-one agent harness
- [rtk](https://github.com/rtk-ai/rtk) -- LLM token reduction CLI proxy

## License

MIT
