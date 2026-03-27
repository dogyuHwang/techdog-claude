---
name: tdc-plan
description: "TechDog Claude - Planning workflow with requirement analysis and task breakdown"
user-invocable: true
---

# /tdc-plan - Planning Workflow

## Trigger

User wants to plan a feature, project, or task before implementation.

## Workflow

1. **Gather Requirements**
   - Read the user's description
   - If too vague, ask up to 3 clarifying questions (no more — token budget)
   - Check existing codebase for relevant context

2. **Analyze**
   - Invoke the `planner` agent (model: sonnet) with:
     - User's request
     - Relevant existing code structure (file tree, not contents)
     - Any constraints mentioned

3. **Output Plan**
   - Structured task list with complexity and agent assignments
   - Dependencies between tasks
   - Acceptance criteria
   - Save plan to `.tdc/plans/<plan-name>.md`

4. **Confirm**
   - Present plan to user for approval
   - On approval, optionally kick off `/tdc-dev` for implementation

## Token Optimization

- Only include file NAMES in context, not file contents
- Keep the plan output under 200 lines
- Don't explore code that isn't relevant to the plan
