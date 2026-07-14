# AgenticCanvas

A template for Claude Code projects with a built-in agentic build pipeline. Clone this as a starting point — the agents and skill are general-purpose and work on any codebase.

## How it works

Run `/build <task description>` in Claude Code. The skill orchestrates three subagents in a pipeline:

1. **Planner** — explores the codebase and produces a structured execution plan (read-only)
2. **Engineer** — takes the plan and implements it step by step, running tests after each step
3. **Tester** — reviews the actual changes against the task and plan, and produces a findings report classified by severity (read-only)

If the tester reports at least one CRITICAL or MAJOR finding, or more than 2 MINOR findings, the engineer is launched again to address them, then the tester re-reviews. Otherwise the pipeline completes, returning the findings report with any remaining MINOR notes.

## Usage

```
/build add a user authentication module with JWT tokens
```

The planner will explore your codebase, produce a step-by-step plan with rationale and test strategy for each step, then hand it off to the engineer for implementation. The tester then reviews the result, and the pipeline loops back to the engineer to fix any flagged issues before completing.

## Structure

```
.claude/
  agents/
    planner.md   # Read-only agent: explores codebase, produces execution plan
    engineer.md  # Implementation agent: follows the plan step by step
    tester.md    # Read-only agent: reviews changes, produces a findings report
  skills/
    build/
      SKILL.md   # Orchestrates the planner → engineer → tester pipeline, with conditional re-implementation
```

## Using this template

1. Clone the repo into your new project directory
2. Add your own source code alongside the `.claude/` folder
3. Run `/build <your task>` to start building
