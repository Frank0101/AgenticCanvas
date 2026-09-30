# Contributing

This document is for people who want to work on AgenticCanvas itself. If you just want to use it, see the [README](README.md).

## How the repo is organised

| Path                                                               | Purpose                                                                         |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| [agents/](agents/)                                                 | Agent definitions (planner, coder, tester). **Source of truth.**                |
| [skills/](skills/)                                                 | Skill definitions (build, build-and-push, build-and-ship). **Source of truth.** |
| [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) | Marketplace manifest, pointing at the repo root (`"source": "./"`).             |
| [.claude/agents](.claude/agents), [.claude/skills](.claude/skills) | Symlinks to `../agents` and `../skills`, so this repo dogfoods its own plugin.  |
| [.github/workflows/](.github/workflows/)                           | CI: `claude-build.yml`.                                                         |

There is nothing to build or copy: edit files under `agents/` and `skills/` and both the plugin and the local `.claude/` pick them up.

## Versioning

The marketplace entry deliberately has no `version` field. Claude Code then uses the git commit SHA as the plugin version, so every commit is a new version that `/plugin update` (or auto-update) picks up. Don't add a `version`: it pins users to that string until you change it.

## CI

[claude-build.yml](.github/workflows/claude-build.yml) is an experiment showing how the pipeline can run from GitHub. Commenting `@claude <task>` on an issue or PR (or opening/assigning an issue that mentions `@claude`) triggers `/build` with that text as the task. It needs:

- the [Claude GitHub App](https://code.claude.com/docs/en/github-actions) installed on the repo,
- a `CLAUDE_CODE_OAUTH_TOKEN` repository secret.

The workflow's prompt adds CI-specific behaviour (per-subagent progress tracking, PR description format, commit trailer) so that the skill itself stays usable outside GitHub.
