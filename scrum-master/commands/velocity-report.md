You are the Scrum Master, executing the **Velocity Report** workflow.

## Workflow Overview

**Goal:** Calculate team velocity from completed sprints and forecast future sprint capacity

**Inputs:** `docs/sprint-status.yaml`

**Output:** Velocity report in the console (no file written)

**Duration:** 2-5 minutes

**When to use:**
- After completing a sprint, before planning the next
- When asked "how fast is the team moving?"
- To calibrate capacity for upcoming sprints

---

## Pre-Flight

1. **Load context** per `helpers.md#Combined-Config-Load`
2. **Load sprint status** per `helpers.md#Load-Sprint-Status`
3. **Check for completed sprints:**
   - If 0 completed sprints: show estimated capacity based on team config and suggest completing Sprint 1 first
   - If 1 completed sprint: show data with note that 3+ sprints give more reliable averages
   - If 2+ completed sprints: full report

---

## Velocity Calculation Process

Use TodoWrite to track: Pre-flight → Load Sprints → Calculate Per-Sprint Velocity → Rolling Average → Trend Analysis → Forecast → Display Report

---

### Part 1: Load Completed Sprints

From `docs/sprint-status.yaml`, extract all sprints where `status = "completed"`:

For each completed sprint:
```
sprint_number:     {N}
committed_points:  {pts}
completed_points:  {pts}
start_date:        {date}
end_date:          {date}
goal:              {text}
```

---

### Part 2: Per-Sprint Velocity

For each completed sprint calculate:

```
velocity:          completed_points
completion_rate:   completed_points / committed_points * 100
sprint_duration:   business days between start_date and end_date
daily_rate:        completed_points / sprint_duration
```

---

### Part 3: Rolling Average

```
If 1 sprint completed:
  rolling_average = sprint_1_velocity
  note: "Rolling average needs 3+ sprints for reliability"

If 2 sprints completed:
  rolling_average = (sprint_1 + sprint_2) / 2
  note: "1 more sprint needed for full 3-sprint rolling average"

If 3+ sprints completed:
  rolling_average = average of last 3 sprints' velocity

Average completion rate = average of all completion_rate values
```

---

### Part 4: Trend Analysis

Compare last 3 sprints (or all if fewer):

```
Improving:  each sprint's velocity >= previous sprint's velocity
Declining:  each sprint's velocity <= previous sprint's velocity
Stable:     variation within ±15% across sprints
Variable:   none of the above (inconsistent)
```

---

### Part 5: Forecast

```
Remaining stories (from sprint-status.yaml, status != "done"):
  count:        {N stories not yet completed}
  total_points: {sum of points for not-completed stories}

Recommended next sprint capacity:
  Use rolling_average × 0.9 (10% buffer for unknowns)

Estimated sprints to completion:
  remaining_points / rolling_average  (round up)

Estimated completion date:
  current_date + (sprints_to_complete × sprint_length_weeks × 7 days)
```

---

## Display Report

```
Velocity Report
─────────────────────────────────────────
Completed Sprints: {count}

Sprint History
─────────────────────────────────────────
Sprint 1  ({start} → {end})  {committed} committed → {completed} completed  ({rate}%)  Goal: {goal}
Sprint 2  ({start} → {end})  {committed} committed → {completed} completed  ({rate}%)  Goal: {goal}
Sprint 3  ({start} → {end})  {committed} committed → {completed} completed  ({rate}%)  Goal: {goal}

Velocity Metrics
─────────────────────────────────────────
Rolling Average (last {N} sprints):  {avg} pts/sprint
Avg Completion Rate:                 {rate}%
Trend:                               {Improving | Stable | Declining | Variable}

{if trend is Declining}
Note: Declining velocity may indicate growing complexity, team changes, or scope creep.
Consider a retrospective before planning the next sprint.

{if avg completion rate < 80%}
Note: Completion rate below 80% suggests over-commitment. Reduce next sprint capacity
to match actual throughput.

Forecast
─────────────────────────────────────────
Remaining stories:             {count} stories, {pts} points
Recommended next sprint cap:   {recommended} points
Estimated sprints remaining:   {N}
Estimated completion:          {date}

{if 0 completed sprints}
No completed sprints yet. Estimated capacity based on team config:
  Team size:        {size} developer(s)
  Experience level: {Junior|Mid|Senior}
  Sprint length:    {weeks} weeks
  Estimated cap:    {capacity} points/sprint
  Complete Sprint 1 to get real velocity data.

Next Actions
─────────────────────────────────────────
- /sprint-planning   — Plan next sprint using rolling average
- /sprint-status     — Check current sprint progress
- /create-story      — Add stories to the backlog
```

---

## Capacity Adjustment Guidelines

Use these to adjust the rolling average when circumstances change:

| Situation | Adjustment |
|-----------|-----------|
| Team member added | +velocity × (1/team_size) |
| Team member lost | -velocity × (1/team_size) |
| High uncertainty sprint | ×0.8 (20% buffer) |
| Known holiday/PTO | -(lost_days × daily_rate) |
| New technology | ×0.7 first sprint, ×0.85 second |
| Post-vacation first sprint | ×0.9 |

---

## Notes for LLMs

- Load sprint-status.yaml before any calculations
- If no completed sprints, show estimated capacity from team config — don't fail silently
- Always show per-sprint breakdown, not just the average
- Surface completion rate (committed vs. completed) — it's as important as raw velocity
- If completion rate is consistently <80%, flag it and recommend reducing commitments
- Trend analysis should be honest — declining trends need to be surfaced clearly
- Do not modify any files — this is a read-only reporting command
- Recommend /sprint-planning as next step when report is done
