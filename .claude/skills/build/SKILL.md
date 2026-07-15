---
name: build
description: Given a task, runs the full build pipeline — plan, implement, test, and conditionally re-implement if issues are found. Invoke with /build <task description>.
argument-hint: "<task description>"
disable-model-invocation: true
---

# Build

Orchestrate the build pipeline in the following stages:

## Stage 1 — Plan

Launch the `planner` subagent with the task passed as the skill argument. Wait for it to complete and capture the full plan it returns.

If the planner returns no plan or fails, stop and report the error. Do not proceed.

## Stage 2 — Implement

Launch the `engineer` subagent with the plan from Stage 1 as its prompt. Wait for it to complete and capture the implementation report.

## Stage 3 — Test

Launch the `tester` subagent with the following as its prompt:

- The original task
- The plan from Stage 1
- The implementation report from Stage 2

Wait for it to complete and capture the findings report.

## Stage 4 — Evaluate and decide

Read the tester's findings report and count findings by severity.

**If the implementation does not pass** (at least one CRITICAL or MAJOR finding, or more than 2 MINOR findings): launch the `engineer` subagent again. Pass it:

- The original plan from Stage 1
- The tester's findings report from Stage 3

Instruct the engineer to amend the implementation to address all flagged findings while staying within the scope of the original plan.

**If the implementation passes** (zero CRITICAL, zero MAJOR, and 2 or fewer MINOR findings): proceed to Stage 5.

## Stage 5 — Branch and open a pull request

Only reached when Stage 4 passes. Commit the working tree changes on a new branch and open a pull request, authenticated as the repo's GitHub App bot identity (config in `.claude/skills/build/app-config.env`, credentials in `gh-private-key.pem`) — not the local user's own git/gh identity.

1. Write a PR body to a temp file summarizing: the original task, a short description of what changed, and the tester's findings report (including any MINOR notes).
2. Run `.claude/skills/build/scripts/open-pr-as-app.sh --title "<concise summary of the task>" --body-file <temp file> --commit-message "<concise summary of the task>"`.
3. The script creates a branch, commits, pushes, and opens the PR entirely under the bot identity, then restores the local git config and working branch on exit — no manual cleanup needed.
4. Report the returned PR URL to the user along with the findings report. If the script fails (e.g. nothing to commit, token mint failure), report the error — do not retry silently.
