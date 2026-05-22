# AgenticCanvas

A template for Claude Code projects with a built-in agentic build pipeline. Clone this as a starting point — the agents and skill are general-purpose and work on any codebase.

## How it works

Run `/build <task description>` in Claude Code. The skill orchestrates two subagents in sequence:

1. **Planner** — explores the codebase and produces a structured execution plan (read-only)
2. **Engineer** — takes the plan and implements it step by step, running tests after each step

## Usage

```
/build add a user authentication module with JWT tokens
```

The planner will explore your codebase, produce a step-by-step plan with rationale and test strategy for each step, then hand it off to the engineer for implementation.

## Structure

```
.claude/
  agents/
    planner.md   # Read-only agent: explores codebase, produces execution plan
    engineer.md  # Implementation agent: follows the plan step by step
  skills/
    build/
      SKILL.md   # Orchestrates planner → engineer pipeline
```

## Using this template

1. Clone the repo into your new project directory
2. Add your own source code alongside the `.claude/` folder
3. Run `/build <your task>` to start building
