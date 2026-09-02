---
name: build-and-commit
description: Local wrapper around /build — creates a branch off the current branch, runs the build pipeline, then commits and pushes only if it converged (otherwise cleans up). Invoke with /build-and-commit <task description>.
argument-hint: "<task description>"
disable-model-invocation: true
---

# Build and Commit

Wraps the `build` skill with the branch/commit/push steps that the GitHub Action runner handles automatically when `/build` runs there. Use this locally instead of invoking `/build` directly.

## Step 1 — Create a branch

1. Run `git status --porcelain`. If it reports any uncommitted changes, stop and report to the user that the working tree isn't clean — do not proceed, since doing so could sweep unrelated work into the new branch.
2. Record the current branch name (`git branch --show-current`) as the base branch — Step 3a returns to it on failure.
3. Derive a short kebab-case slug (3-6 words) from the task description.
4. Run `git checkout -b claude/<slug>` off the current branch.

## Step 2 — Run the build pipeline

Invoke the `build` skill with the task description passed through unchanged. Wait for it to complete and capture whatever it reports.

Check the last line of its output per its output contract:

- `BUILD_RESULT: FAILED` → go to Step 3a (clean up). Do not proceed to Step 3b.
- `BUILD_RESULT: PASSED` → go to Step 3b (commit and push).

## Step 3a — Clean up (on failure)

Discard the failed attempt and remove the branch, so nothing is left dangling:

1. `git reset --hard`
2. `git clean -fd`
3. `git checkout <base branch from Step 1>`
4. `git branch -D claude/<slug>` (the branch from Step 1)

Report the outcome to the user, including the tester's final findings report in full, so they can see what was tried and what's still outstanding. Make clear that the branch and changes were discarded — nothing was committed or pushed.

## Step 3b — Commit and push (on success)

Run `git status --porcelain`. If it reports no changes, skip the rest of this step and tell the user there was nothing to commit.

Otherwise, stage and commit all changes with a message summarizing the task, ending the commit message with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

Then push the branch: `git push -u origin claude/<slug>` (using the branch name from Step 1).

Report the branch name to the user. Do not open a pull request automatically — leave that for the user to do once they've reviewed the branch.
