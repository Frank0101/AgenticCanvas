# AgenticCanvas

A laboratory for testing and building skills for agentic coding. It also includes an experiment showing how such skills can be invoked from a GitHub Action.

## Repo setup

After cloning, run once:

```bash
bash scripts/setup-hooks.sh
```

This points git at the repo-managed hooks in [.githooks/](.githooks/) (`git config core.hooksPath .githooks`), so the pre-commit hook that keeps the packaged plugin in sync (see [Installing as a plugin](#installing-as-a-plugin)) actually runs before every local commit.

## The skills

The `build` skill is the core of the agentic coding pipeline. It manages a workflow made of 3 subagents: planner, coder, and tester.

- **Planner** — read-only. Explores the codebase and produces a structured execution plan for the given task. Each step states why it's needed, what to do, and how to test it, so the coder gets an unambiguous, checkable unit of work rather than a vague instruction.
- **Coder** — takes the plan and implements it step by step, running the relevant tests after each step before moving to the next. It only follows the plan; it doesn't re-derive scope or make architectural decisions on its own.
- **Tester** — read-only, like the planner. Reviews the actual code changes against the original task and the plan, checking correctness, minimality, consistency with existing codebase patterns, and test coverage. Produces a findings report with issues classified as MINOR, MAJOR, or CRITICAL.

The findings report decides whether the pipeline loops: if the tester comes back with at least one CRITICAL or MAJOR issue, or more than 2 MINOR ones, the coder is launched again with those findings to address them, and the tester re-reviews the result. This repeats for up to 3 attempts total, after which the pipeline stops and reports the final findings either way — pass or fail.

Two more skills extend `build` with increasing amounts of git automation:

- `/build-and-push <task>` — runs `/build`, then commits and pushes to the current branch, but only if the pipeline passed.
- `/build-and-ship <task>` — runs `/build-and-push` inside an isolated git worktree/branch (so it never touches your working directory, and multiple runs can happen in parallel), then opens a pull request if a commit landed. Cleans up the worktree either way.

## Installing as a plugin

These skills are also packaged as an installable Claude Code plugin, so you can use them in any project without cloning this repo. Add the marketplace once per machine:

```bash
claude plugin marketplace add Frank0101/AgenticCanvas
```

Then install the plugin at whichever scope fits:

```bash
# Available in every project on this machine (default scope)
claude plugin install agentic-canvas@agentic-canvas --scope user

# Available only in the current project, for you (not committed/shared)
claude plugin install agentic-canvas@agentic-canvas --scope local

# Available to everyone who clones the current project (committed to .claude/settings.json)
claude plugin install agentic-canvas@agentic-canvas --scope project
```

`--scope` defaults to `user` if omitted. All three install the same agents and skills described above, without touching anything else in the target project.

To clean up:

1. List what's installed, to find the plugin and the scope it was installed at:

   ```bash
   claude plugin list
   ```

2. List configured marketplaces, to confirm the marketplace name:

   ```bash
   claude plugin marketplace list
   ```

3. Uninstall the plugin (matching `--scope` to what step 1 showed) and remove the marketplace:

   ```bash
   claude plugin uninstall agentic-canvas@agentic-canvas --scope <scope>
   claude plugin marketplace remove agentic-canvas
   ```

## Running it via GitHub

The repo also contains an example of how to run the pipeline automatically from GitHub, via [.github/workflows/claude-build.yml](.github/workflows/claude-build.yml). Comment `@claude <task>` on an issue or PR (or open/assign an issue mentioning `@claude`), and the workflow triggers `/build` with that text as the task.

This requires installing the [Claude GitHub App](https://code.claude.com/docs/en/github-actions) on the repo, and adding a `CLAUDE_CODE_OAUTH_TOKEN` repository secret.
