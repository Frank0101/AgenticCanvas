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

If the engineer returns no implementation report or fails, stop and report the error. Do not proceed.

## Stage 3 — Test

Launch the `tester` subagent with the following as its prompt:

- The original task
- The plan from Stage 1
- The implementation report from Stage 2

Wait for it to complete and capture the findings report.

If the tester returns no findings report or fails, stop and report the error. Do not proceed.

## Stage 4 — Evaluate and decide

Track an attempt counter, starting at 1 for the implementation from Stage 2. Read the tester's findings report and count findings by severity.

**If the implementation passes** (zero CRITICAL, zero MAJOR, and 2 or fewer MINOR findings): the pipeline is complete. Return the tester's findings report to the user. Surface any MINOR findings as a note.

**If the implementation does not pass** (at least one CRITICAL or MAJOR finding, or more than 2 MINOR findings):

- **If the attempt counter is below 3**: increment the counter, launch the `engineer` subagent again with the original plan from Stage 1 (unmodified) and the tester's findings report from Stage 3 (unmodified), instructing it to amend the implementation to address all flagged findings while staying within the scope of the original plan. Then repeat Stage 3 (test) against the new implementation, and re-evaluate here at Stage 4.
- **If the attempt counter has reached 3** (i.e. the implementation has already been tried 3 times, including retries): stop the loop. Report to the user that the pipeline did not converge after 3 attempts, and include the final tester findings report in full so the user can see what's still outstanding.
