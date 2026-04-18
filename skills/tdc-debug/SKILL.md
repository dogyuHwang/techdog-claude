---
name: tdc-debug
description: "TechDog Claude - Debugging workflow for bug diagnosis and fixing"
user-invocable: true
argument-hint: "[에러 메시지 또는 설명]"
---

**입력:** $ARGUMENTS

# /tdc-debug - Debugging Workflow

## Trigger

User reports a bug, error, or unexpected behavior.

## Workflow

1. **Collect Evidence**
   - Error message or stack trace from user
   - Relevant log output
   - Steps to reproduce (ask if not provided)

2. **Diagnose**
   - Invoke the `debugger` agent (model: claude-sonnet-4-6) with:
     - Error details
     - Relevant source files (read the specific files mentioned in stack trace)
   - Agent traces the root cause systematically

3. **Fix**
   - Apply the minimal fix
   - Run tests to verify

4. **Guard**
   - Add a regression test if testing infrastructure exists
   - Report what was wrong and what was fixed

## Escalation

If the debugger agent identifies an architectural issue:
- Report the architectural issue to Master Agent
- Master invokes `architect` agent (model: claude-opus-4-7) for design guidance
- Master routes the design guidance to `developer` agent for implementation
- All communication goes through Master (hub-and-spoke model)

## Token Optimization

- Include only stack-trace-relevant files in context
- Don't read the entire codebase looking for the bug
- Start narrow, expand only if needed
