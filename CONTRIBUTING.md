# Contributing

This document is for people who want to work on AgenticCanvas itself. If you just want to use it, see the [README](README.md).

## Repo setup

After cloning, run once:

```bash
bash scripts/setup-hooks.sh
```

This points git at the repo-managed hooks in [.githooks/](.githooks/) (`git config core.hooksPath .githooks`), so the pre-commit hook that keeps the packaged plugin in sync (see below) actually runs before every local commit.

## How the repo is organised

| Path                                                               | Purpose                                                                            |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| [.claude/agents/](.claude/agents/)                                 | Agent definitions (planner, coder, tester). **Source of truth.**                   |
| [.claude/skills/](.claude/skills/)                                 | Skill definitions (build, build-and-push, build-and-ship). **Source of truth.**    |
| [.build/agentic-canvas/](.build/agentic-canvas/)                   | The distributable plugin. **Generated, never edit by hand.**                       |
| [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) | Marketplace manifest that points at `.build/agentic-canvas`.                       |
| [VERSION](VERSION)                                                 | Plugin version, written into the generated `plugin.json`.                          |
| [scripts/](scripts/)                                               | `build-plugin.sh` (generates the plugin) and `setup-hooks.sh` (enables git hooks). |
| [.githooks/pre-commit](.githooks/pre-commit)                       | Bumps the version and rebuilds the plugin on commit.                               |
| [.github/workflows/](.github/workflows/)                           | CI: `claude-build.yml`.                                                            |

The repo uses its own `.claude/` directly (dogfooding), while everyone else installs the packaged copy under `.build/`.

## Packaging the plugin

[scripts/build-plugin.sh](scripts/build-plugin.sh) regenerates `.build/agentic-canvas/` from `.claude/agents` and `.claude/skills`, and writes `plugin.json` using the number in `VERSION`. It is deterministic: the same inputs always produce the same output.

You normally don't run it yourself. The pre-commit hook does it for you:

- On any commit that touches `.claude/`, it bumps the **patch** component of `VERSION` and rebuilds `.build/`, then stages both.
- The new version is always computed from `VERSION` as committed in `HEAD`, so retrying a failed commit gives the same result.
- Commits that don't touch `.claude/`, and merge commits, are left alone.

For a minor or major bump, edit `VERSION` yourself before committing. Note that the hook derives the next version from `HEAD`, so make that change in a separate commit first.

## CI

[claude-build.yml](.github/workflows/claude-build.yml) is an experiment showing how the pipeline can run from GitHub. Commenting `@claude <task>` on an issue or PR (or opening/assigning an issue that mentions `@claude`) triggers `/build` with that text as the task. It needs:

- the [Claude GitHub App](https://code.claude.com/docs/en/github-actions) installed on the repo,
- a `CLAUDE_CODE_OAUTH_TOKEN` repository secret.

The workflow's prompt adds CI-specific behaviour (per-subagent progress tracking, PR description format, commit trailer) so that the skill itself stays usable outside GitHub.
