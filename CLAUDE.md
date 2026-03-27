# TechDog Claude (tdc)

Multi-agent development orchestration system for Claude Code.

## Architecture

- **Master Agent**: Team leader. Orchestrates all sub-agents, manages context, handles session transitions.
- **Planner Agent**: Requirement analysis, task breakdown, PRD generation.
- **Developer Agent**: Code implementation, feature development.
- **Debugger Agent**: Bug diagnosis, root cause analysis, fix implementation.
- **Reviewer Agent**: Code review, quality checks, security audit.
- **Architect Agent**: System design, architecture decisions, tech stack evaluation.

## Commands

- `/tdc` - Main entry point. Routes tasks to appropriate agents.
- `/tdc-plan` - Planning workflow with planner agent.
- `/tdc-dev` - Development workflow with developer agent.
- `/tdc-debug` - Debugging workflow with debugger agent.
- `/tdc-review` - Code review workflow with reviewer agent.
- `/tdc-session` - Session management (save/restore/list).

## Token Optimization

- Model tiering: haiku (simple), sonnet (standard), opus (complex)
- Context compression: auto-summarize when context fills
- Session persistence: resume without re-processing
- Lazy loading: only load relevant agent context

## Session Management

Sessions are stored in `.tdc/sessions/`. When context fills:
1. Master agent summarizes all progress
2. Saves state to `.tdc/sessions/{id}.json`
3. Opens new session with compressed context
4. Continues from saved checkpoint

## Directory Structure

```
.tdc/
  sessions/     # Session state persistence
  context/      # Context summaries
  plans/        # Active plans
```
