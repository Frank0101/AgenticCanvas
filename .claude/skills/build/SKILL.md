---
name: build
description: Given a task, runs the full build pipeline. Currently: launches the planner subagent to produce a structured execution plan. Invoke with /build <task description>.
argument-hint: "<task description>"
disable-model-invocation: true
---

# Build

Launch the `planner` subagent with the task passed as the skill argument.

Pass the task verbatim as the planner's prompt. Return the plan to the user exactly as the planner produced it, without modification.
