# AgenticCanvas

A blank canvas for starting new projects with agentic AI. It's not a framework or a library — it's a `.claude/` setup (agents + skills) that you clone as the first commit of a new project, then build on top of using Claude Code. Expect to outgrow or override most of it once real project work begins.

## How it works

Run `/build <task description>` in Claude Code. The skill orchestrates three subagents in a pipeline:

1. **Planner** — explores the codebase and produces a structured execution plan (read-only)
2. **Engineer** — takes the plan and implements it step by step, running tests after each step
3. **Tester** — reviews the actual changes against the task and plan, and produces a findings report classified by severity (read-only)

If the tester finds at least one CRITICAL or MAJOR issue, or more than 2 MINOR ones, the engineer is launched again to address them and the tester re-reviews. This repeats up to 3 attempts total, then the pipeline stops and reports the final findings either way.

## Running it locally

Three skills build on top of each other, for increasing amounts of git automation:

- `/build <task>` — runs the pipeline only, on whatever branch you currently have checked out. Doesn't touch git.
- `/build-and-push <task>` — runs `/build`, then commits and pushes to the current branch, but only if the pipeline passed.
- `/build-and-ship <task>` — runs `/build-and-push` inside an isolated git worktree/branch (so it never touches your working directory, and multiple runs can happen in parallel), then opens a pull request if a commit landed. Cleans up the worktree either way.

## Running it via GitHub

The same pipeline can run automatically from GitHub, via [.github/workflows/claude-build.yml](.github/workflows/claude-build.yml). Comment `@claude <task>` on an issue or PR (or open/assign an issue mentioning `@claude`), and the workflow triggers `/build` with that text as the task.

This requires installing the [Claude GitHub App](https://code.claude.com/docs/en/github-actions) on the repo, and adding a `CLAUDE_CODE_OAUTH_TOKEN` repository secret.

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
    build-and-push/
      SKILL.md   # Runs /build, commits, and pushes to the current branch if it passed
    build-and-ship/
      SKILL.md   # Runs /build-and-push in an isolated worktree/branch, then opens a PR
.github/
  workflows/
    claude-build.yml  # Triggers /build from @claude mentions on issues, PRs, and reviews
```

## Using this template

1. Clone the repo into your new project directory
2. Add your own source code alongside the `.claude/` folder
3. Run `/build`, `/build-and-push`, or `/build-and-ship <your task>` locally, or trigger `/build` from GitHub with `@claude <your task>`
