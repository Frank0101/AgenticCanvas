---
name: build-and-push
description: Local wrapper around /build — runs the build pipeline directly on the current branch, then commits and pushes only if it converged. Invoke with /build-and-push <task description>.
argument-hint: "<task description>"
---

# Build and Push

Wraps the `build` skill with a commit/push step, operating directly on the current branch.

## Step 1 — Preflight

Run `git status --porcelain`. If it reports any changes at all — staged or unstaged — stop and report to the user that the working tree isn't clean. Do not proceed, since the pipeline's own edits would otherwise be indistinguishable from pre-existing changes.

## Step 2 — Run the build pipeline

Invoke the `build` skill with the task description passed through unchanged. Wait for it to complete and capture whatever it reports. Do not stage or commit anything at this point, regardless of outcome.

Check the last line of its output per its output contract:

- `BUILD_RESULT: FAILED` → stop here. Report the outcome and the tester's final findings report in full to the user. Leave the changes exactly as they are — unstaged, on the current branch — so the user can inspect them and reset manually (e.g. `git reset --hard`) if they want to discard them. Do not stage, commit, or reset anything yourself.
- `BUILD_RESULT: PASSED` → continue to Step 3.

## Step 3 — Commit and push

Run `git status --porcelain`. If it reports no changes, skip the rest of this step and tell the user there was nothing to commit.

Otherwise, stage and commit all changes with a message summarizing the task, ending the commit message with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

Then push to origin: `git push -u origin <current branch>`. This creates the branch on origin if it doesn't already exist there, and is safe to run even if it does.

Report the result to the user.
