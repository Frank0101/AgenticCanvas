---
name: build
description: Given a task, runs the full build pipeline — planning then implementation. Launches the planner to produce an execution plan, then passes the plan to the engineer to implement it. Invoke with /build <task description>.
argument-hint: "<task description>"
disable-model-invocation: true
---

# Build

Orchestrate the build pipeline in two sequential stages:

## Stage 1 — Plan

Launch the `planner` subagent with the task passed as the skill argument. Wait for it to complete and capture the full plan it returns.

## Stage 2 — Implement

Launch the `engineer` subagent. Pass it the full plan produced in Stage 1 as its prompt, verbatim. Wait for it to complete and return its implementation report to the user.

Do not start Stage 2 until Stage 1 has completed. If the planner returns no plan or fails, stop and report the error without launching the engineer.
