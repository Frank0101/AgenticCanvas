# AgenticCanvas

A [Claude Code](https://claude.com/claude-code) plugin that adds a **plan → code → review** pipeline to your coding sessions.

Given a task, it runs three subagents in sequence:

1. a **planner** explores the codebase and writes a step-by-step plan,
2. a **coder** implements the plan, running tests after each step,
3. a **tester** reviews the changes and, if it finds significant issues, sends them back to the coder for fixes.

## Installation

You need [Claude Code](https://claude.com/claude-code) installed. Then:

**1. Add the marketplace** (once per machine):

```bash
claude plugin marketplace add Frank0101/AgenticCanvas
```

**2. Install the plugin**, choosing the scope that fits:

```bash
# Every project on this machine (default)
claude plugin install agentic-canvas@frank0101 --scope "user"

# Only the current project, only for you (not committed)
claude plugin install agentic-canvas@frank0101 --scope "local"

# Everyone who clones the current project (saved in .claude/settings.json)
claude plugin install agentic-canvas@frank0101 --scope "project"
```

All three install exactly the same skills and agents, and don't change anything else in your project.

**3. Try it.** In Claude Code, run:

```
/agentic-canvas:build create an empty C# console application
```

> Skills from a plugin are namespaced with the plugin name, so the skills below are invoked as `/agentic-canvas:build`, `/agentic-canvas:build-and-push` and `/agentic-canvas:build-and-ship`. The sections below use the short names for readability.

### Uninstalling

```bash
# List the installed plugins
claude plugin list

# Uninstall the plugin, using the scope shown above
claude plugin uninstall agentic-canvas@frank0101 --scope "<scope>"

# List the installed marketplaces
claude plugin marketplace list

# Remove the marketplace
claude plugin marketplace remove frank0101
```

### Updating

```bash
# Refresh the marketplace to pick up new releases
claude plugin marketplace update frank0101

# Check the installed version against the latest available
claude plugin list

# Update the plugin, using the scope it was installed at (restart required to apply)
claude plugin update agentic-canvas@frank0101 --scope "<scope>"
```

## Skills

Skills are the commands you run. There are three, each building on the previous one.

### `/build <task>`

Runs the full pipeline on your task:

1. The **planner** produces a plan.
2. The **coder** implements it.
3. The **tester** reviews the changes and reports findings.
4. If the review found real problems, the coder is called again to fix them and the tester re-checks. This repeats up to **3 attempts** in total.

The pipeline **passes** when the tester reports no CRITICAL findings, no MAJOR findings, and at most 2 MINOR ones. Otherwise it retries, and after the third attempt it stops and shows you what is still outstanding.

Either way, the changes are left in your working directory, uncommitted, so you can inspect them. The last line of the output is always `BUILD_RESULT: PASSED` or `BUILD_RESULT: FAILED`.

### `/build-and-push <task>`

Runs `/build`, then commits and pushes to your current branch, but **only if the build passed**.

- Requires a clean working tree. If you have uncommitted changes it stops, so the pipeline's edits can't be mixed up with yours.
- If the build fails, nothing is committed. The changes stay in your working directory for you to review or discard.

### `/build-and-ship <task>`

Runs `/build-and-push` in an isolated git worktree on its own `claude/<task-slug>` branch, then opens a **pull request** if a commit was produced.

- Your working directory is never touched, and you can run several in parallel.
- The PR description contains the coder's implementation report and the tester's findings.
- Requires the [GitHub CLI](https://cli.github.com/) (`gh`), authenticated.
- This one only runs when you invoke it yourself. Claude won't start it on its own.

## Agents

The three agents are what `/build` orchestrates. You don't normally call them directly, but Claude can delegate to them in any session once the plugin is installed. All three run on Sonnet.

### Planner

_Read-only. Tools: Read, Bash._

Explores your codebase and turns the task into a numbered plan. Every step states **what** to do, **why**, and **how to test it**.

Before planning, it looks for your project's conventions (`CLAUDE.md`, architecture docs, style guides) and follows them. Where documented guidelines and existing code disagree, it aims for the documented target and tells you where it couldn't fully get there. If the task is ambiguous, it states its assumptions at the top of the plan.

### Coder

_Tools: Read, Write, Edit, Bash._

Implements the plan one step at a time, running each step's test before moving on. It follows the plan strictly: no extra features, no unrelated refactoring. If a step is ambiguous it takes the smallest reasonable interpretation and flags it. If a step is blocked, it stops and reports the blocker.

It finishes with an implementation report listing, per step, what changed and whether its test passed.

### Tester

_Read-only. Tools: Read, Bash._

Reviews what was actually changed in the code, not just what the coder says it did, against the original task and plan. It checks four things:

- **Correctness** — does it do what the task asked?
- **Minimality** — is anything unrelated or unnecessary in the diff?
- **Consistency** — does it match the codebase's existing patterns and style?
- **Test coverage** — are meaningful changes covered, where tests exist or were requested?

Each finding is rated by severity:

| Severity     | Meaning                                                                       |
| ------------ | ----------------------------------------------------------------------------- |
| **CRITICAL** | Breaks correctness, introduces a bug, or leaves the task unaddressed          |
| **MAJOR**    | A real issue that violates something the task or codebase explicitly requires |
| **MINOR**    | Cosmetic or stylistic, with no functional impact                              |

Severity is tied to the task's scope. A generally good practice that the task didn't ask for (for example, adding tests to a project that has none) is never rated above MINOR.

## Contributing

Want to change the skills or agents? See [CONTRIBUTING.md](CONTRIBUTING.md).
