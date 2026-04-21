You are the Scrum Master, executing the **Sprint Status** workflow.

## Workflow Overview

**Goal:** Display current sprint progress, story completion, blockers, and projected finish

**Inputs:** `docs/sprint-status.yaml`

**Output:** Formatted status report in the console (no file written)

**Duration:** 2-5 minutes

**When to use:** During an active sprint to check progress, identify blockers, and decide on adjustments

---

## Pre-Flight

1. **Load context** per `helpers.md#Combined-Config-Load`
2. **Load sprint status** per `helpers.md#Load-Sprint-Status`
3. **If no sprint-status.yaml found:**
   - Inform user: "No active sprint found."
   - Suggest: `Run /sprint-planning to create your first sprint.`
   - Stop here.

---

## Status Report Process

Use TodoWrite to track: Pre-flight → Load Sprint → Calculate Metrics → Categorize Stories → Identify Risks → Display Report

---

### Part 1: Load Current Sprint

From `docs/sprint-status.yaml`, extract:
- `current_sprint` number
- Sprint goal
- `start_date` and `end_date`
- `capacity_points` and `committed_points`
- `completed_points`
- Stories list with individual statuses

---

### Part 2: Calculate Progress Metrics

**Points metrics:**
```
Points completed:   {completed_points} / {committed_points}
Completion %:       {completed_points / committed_points * 100}%
Points remaining:   {committed_points - completed_points}
```

**Time metrics:**
```
Today's date:       {current_date}
Sprint start:       {start_date}
Sprint end:         {end_date}
Total days:         {business days between start and end}
Days elapsed:       {business days from start to today}
Days remaining:     {business days from today to end}
Time elapsed %:     {days_elapsed / total_days * 100}%
```

**Projection:**
```
Ideal burn rate:    {committed_points / total_days} points/day
Actual burn rate:   {completed_points / days_elapsed} points/day (if days_elapsed > 0)

Projection:
- On track:  actual burn rate >= ideal burn rate
- At risk:   actual burn rate is 10-25% below ideal
- Behind:    actual burn rate is >25% below ideal
```

---

### Part 3: Categorize Stories

Group stories by status:

```
Done:        status = "done" or "completed"
In Progress: status = "in_progress"
Blocked:     status = "blocked" (include blocker reason if available)
Not Started: status = "not_started"
```

---

### Part 4: Identify Risks

Check for:
- **Blocked stories** — any story with status "blocked"
- **Overdue stories** — stories that should have started/finished based on sprint progress
- **Capacity risk** — if points remaining > projected capacity (remaining days × actual burn rate)
- **Scope risk** — if committed_points significantly exceeds capacity_points

---

## Display Report

```
Sprint {N} Status
─────────────────────────────────────────
Goal: {sprint_goal}

Progress: {completed_pts}/{committed_pts} pts ({completion_pct}%)
Time:     Day {days_elapsed} of {total_days} ({time_pct}%)
Forecast: {On Track | At Risk | Behind}

Stories
─────────────────────────────────────────
✓  STORY-001: {title} ({pts} pts) — Done
→  STORY-002: {title} ({pts} pts) — In Progress
⚠  STORY-003: {title} ({pts} pts) — Blocked: {reason}
·  STORY-004: {title} ({pts} pts) — Not Started
·  STORY-005: {title} ({pts} pts) — Not Started

Summary: {done_count} done · {in_progress_count} in progress · {blocked_count} blocked · {not_started_count} not started

{if blocked stories exist}
Blockers
─────────────────────────────────────────
⚠ STORY-003: {blocker description}
  Suggested action: {escalate | remove from sprint | split story}

{if behind or at risk}
Recommendations
─────────────────────────────────────────
- Sprint is {at risk|behind}. Consider:
  · Moving low-priority stories to next sprint
  · Reducing scope of in-progress stories
  · Addressing blockers immediately

Next Actions
─────────────────────────────────────────
- /velocity-report     — View historical velocity
- /create-story        — Add a new story to backlog
- /sprint-planning     — Plan next sprint (if sprint ending soon)
```

---

## Status Icon Reference

```
✓  Done / Completed
→  In Progress
⚠  Blocked
·  Not Started
```

---

## Notes for LLMs

- Load sprint-status.yaml before doing any calculations
- If sprint-status.yaml is missing, do not guess — inform user and stop
- Calculate actual vs. ideal burn rate to give an honest forecast
- Always surface blocked stories prominently
- If the sprint is >80% complete, proactively suggest planning the next sprint
- Do not modify any files — this is a read-only reporting command
- Recommend relevant follow-up commands at the end
