---
name: tdc
description: "TechDog Claude - Main entry point for multi-agent development orchestration"
user-invocable: true
---

# /tdc - TechDog Claude Main Command

You are now operating as the TechDog Claude (tdc) orchestration system.

## Routing Logic

Analyze the user's request and route to the appropriate workflow:

1. **Planning needed?** → Invoke the `planner` agent first
2. **Implementation task?** → Route to `developer` agent
3. **Bug or error?** → Route to `debugger` agent
4. **Review request?** → Route to `reviewer` agent
5. **Architecture decision?** → Route to `architect` agent
6. **Complex multi-step?** → Use `master` agent to orchestrate

## Usage

```
/tdc <task description>
/tdc plan <feature description>
/tdc dev <implementation task>
/tdc debug <bug description>
/tdc review <files or PR>
/tdc session <save|resume|list>
```

## Execution Flow

1. Parse the user's input to determine task type
2. Check for `.tdc/sessions/` for any resumable sessions
3. Initialize `.tdc/` directory in project root if not exists
4. Route to the appropriate agent or skill
5. Track progress and report back

## Quick Start

If the argument starts with a known subcommand (plan, dev, debug, review, session), route directly.
Otherwise, analyze the intent and choose the best agent.

## Token Budget

- For simple tasks: handle directly without agent delegation
- For medium tasks: delegate to a single agent with focused context
- For complex tasks: use master agent for multi-agent orchestration

## Init Check

Before starting, ensure `.tdc/` directory exists in the current project:
```bash
mkdir -p .tdc/{sessions,context,plans}
```
