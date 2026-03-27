---
name: tdc-dev
description: "TechDog Claude - Development workflow for code implementation"
user-invocable: true
---

# /tdc-dev - Development Workflow

## Trigger

User wants to implement a feature, write code, or build something.

## Workflow

1. **Check for Plan**
   - Look in `.tdc/plans/` for an existing plan
   - If no plan exists and task is complex, suggest `/tdc-plan` first
   - If simple enough, proceed directly

2. **Implement**
   - Invoke the `developer` agent (model: sonnet) with:
     - Task description or plan reference
     - Relevant existing code (read specific files, not whole directories)
   - For multi-file tasks, work incrementally

3. **Verify**
   - Run available tests/linters after implementation
   - If issues found, invoke `debugger` agent for fixes

4. **Report**
   - List all files modified with one-line summaries
   - Note any follow-up items

## Parallel Execution

For independent tasks (e.g., implementing 3 unrelated functions):
- Launch multiple `developer` agents in parallel
- Each gets only the context it needs
- Master synthesizes results

## Token Optimization

- Read only the files that need modification
- Don't include unchanged files in agent context
- Report results concisely — diffs speak louder than explanations
