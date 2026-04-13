---
name: tdc-review
description: "TechDog Claude - Code review workflow"
user-invocable: true
argument-hint: "[파일 경로]"
---

**입력:** $ARGUMENTS

# /tdc-review - Code Review Workflow

## Trigger

User wants a code review on recent changes or specific files.

## Workflow

1. **Identify Scope**
   - If files specified, review those files
   - If no files specified, check `git diff` for recent changes
   - If PR specified, review the PR diff

2. **Review**
   - Invoke the `reviewer` agent (model: haiku — lightweight, fast) with:
     - The diff or file contents
     - Project conventions if known
   - For large changes, split into chunks and review in parallel

3. **Report**
   - Categorized findings: critical / warnings / suggestions
   - Clear approve or request-changes verdict

## Token Optimization

- Use `git diff` output, not full file reads
- Reviewer uses haiku model — cheapest tier
- Split large reviews into focused chunks
- No need to include unchanged code context
