---
name: build-and-ship
description: Runs the build pipeline in an isolated git worktree/branch, then opens a pull request if it produced a pushed commit. Invoke with /build-and-ship <task description>.
argument-hint: "<task description>"
disable-model-invocation: true
---

# Build and Ship

Runs `build-and-push` inside a disposable git worktree, so it never touches your current working directory or collides with another `/build-and-ship` running at the same time, then opens a pull request for the result.

## Step 1 — Create an isolated worktree

1. Record the current branch as the base branch: `git branch --show-current`.
2. Derive a short kebab-case slug (3-6 words) from the task description.
3. Determine the repo's directory name: `basename "$(git rev-parse --show-toplevel)"`.
4. Create the worktree on a new branch off the current branch: `git worktree add ../<repo-name>-claude-<slug> -b claude/<slug>`.
5. Switch into that new directory with `EnterWorktree(path: "../<repo-name>-claude-<slug>")` rather than a plain shell `cd`, since a raw `cd` is not guaranteed to persist across later tool calls. Run every command in the steps below from there, unless a step says otherwise.
   - This worktree was created manually with `git worktree add`, not via `EnterWorktree(name: ...)`, so `ExitWorktree` will not recognize it. Do not call `ExitWorktree` in this skill — cleanup in Steps 3a/3b uses plain `cd` and `git worktree remove` instead.

## Step 2 — Run the build pipeline

Invoke the `build-and-push` skill with the task description passed through unchanged. Wait for it to complete and capture whatever it reports (the underlying plan, implementation report, and tester findings are all still visible from this same run — keep them, they're needed for the PR body in Step 3b).

## Step 3 — Check whether anything landed

Run `git log <base branch from Step 1>..HEAD --oneline`.

- **Empty output** (no commits beyond the base branch — `build-and-push` never got as far as committing, whether from a dirty preflight, a failed build, or nothing to commit): go to Step 3a.
- **Non-empty output** (at least one commit was made, which `build-and-push` always pushes in the same step it commits): go to Step 3b.

## Step 3a — Clean up (nothing to ship)

Report to the user what happened, based on what `build-and-push` reported. Then remove the isolation, discarding nothing of value since no commit was ever made:

1. `cd` back to the original directory.
2. `git worktree remove ../<repo-name>-claude-<slug> --force`
3. `git branch -D claude/<slug>`

## Step 3b — Open a pull request

Still from within the worktree, open the PR against the base branch from Step 1:

```
gh pr create --base <base branch> --head claude/<slug> --title "<short title derived from the task>" --body "<see below>"
```

Structure the PR body as:

```
## Summary
<the coder's full implementation report from Step 2, verbatim>

## Testing
<the tester's full findings report from Step 2, verbatim>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Report the PR URL to the user. Then clean up the now-unneeded worktree, keeping the branch (its commits are already pushed and the PR points at it):

1. `cd` back to the original directory.
2. `git worktree remove ../<repo-name>-claude-<slug>`
