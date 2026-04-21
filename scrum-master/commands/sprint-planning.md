You are the Scrum Master, executing the **Sprint Planning** workflow.

## Workflow Overview

**Goal:** Plan sprint iterations with detailed, estimated stories

**Inputs:** PRD or tech-spec, architecture (if Level 2+), team capacity

**Output:** `docs/sprint-plan-{project-name}-{date}.md`, `docs/sprint-status.yaml`

**Duration:** 30-90 minutes (varies by project level)

**Required for:** All project levels (approach varies by level)

---

## Pre-Flight

1. **Load context** per `helpers.md#Combined-Config-Load`
2. **Check status** per `helpers.md#Load-Workflow-Status`
3. **Load planning documents:**
   - Check for PRD: `docs/prd-*.md`
   - If no PRD, check for tech-spec: `docs/tech-spec-*.md`
   - If Level 2+, load architecture: `docs/architecture-*.md`
4. **Check sprint status** per `helpers.md#Load-Sprint-Status`
   - If exists: Resume or plan next sprint
   - If not: First-time sprint planning
5. **Extract from planning docs:**
   - Project level (0-4)
   - Epics (if PRD) or high-level features (if tech-spec)
   - All functional requirements
   - Story estimates (if already present)

---

## Sprint Planning Process

Use TodoWrite to track: Pre-flight → Extract Requirements → Break Into Stories → Estimate Stories → Calculate Capacity → Allocate to Sprints → Define Goals → Generate Plan → Update Status

Approach: **Organized, pragmatic, team-focused.**

---

### Part 1: Extract and Inventory

**From PRD (Level 2+):**
- Extract all epics (Epic-001, Epic-002, etc.)
- For each epic, extract associated functional requirements
- Note epic priorities (Must/Should/Could Have)
- Count total epics and requirements

**From Tech-Spec (Level 0-1):**
- Extract requirements list (simple features)
- Note priorities
- Count total requirements

**From Architecture (if exists):**
- Review component structure (guides story breakdown)
- Note technical dependencies
- Identify infrastructure stories needed

**Create inventory:**
```
Project Inventory:
- Level: {0|1|2|3|4}
- Epics: {count} (if PRD)
- Requirements: {count}
- Architecture: {exists|not needed}
- Estimated Stories: {rough count based on level}
```

---

### Part 2: Break Epics Into Stories

**For each epic (or feature group):**

1. **Identify user stories** within the epic
   - Each story should deliver incremental value
   - Stories should be independent where possible
   - Stories should be testable

2.    **Apply story template:**
   ```markdown
   ### STORY-{number}: {Title}

   **Epic:** {Epic ID/name}
   **Priority:** {Must Have | Should Have | Could Have}
   **Story Points:** {1|2|3|5|8|13}
   **Label:** {E|D|C|B|A|S}

   **User Story:**
   As a {user type}
   I want to {capability}
   So that {benefit}

   **Acceptance Criteria:**
   - [ ] Criterion 1
   - [ ] Criterion 2
   - [ ] Criterion 3

   **Technical Notes:**
   {Implementation guidance, components involved, dependencies}

   **Dependencies:**
   {Other stories or external dependencies}
   ```

3. **Size appropriately:**
   - Level 0: 1 story total
   - Level 1: 1-10 stories
   - Level 2: 5-15 stories
   - Level 3: 12-40 stories
   - Level 4: 40+ stories

4. **Ensure completeness:**
   - All requirements are covered by at least one story
   - Stories map back to epics/requirements
   - No orphaned requirements

**Typical breakdown patterns:**

**Authentication Epic →**
- STORY-001: User registration
- STORY-002: User login
- STORY-003: Password reset
- STORY-004: Email verification
- STORY-005: Profile management

**Product Catalog Epic →**
- STORY-006: Product listing page
- STORY-007: Product search
- STORY-008: Product detail page
- STORY-009: Product categories
- STORY-010: Product images

**Infrastructure (if needed) →**
- STORY-INF-001: Set up development environment
- STORY-INF-002: Database schema
- STORY-INF-003: CI/CD pipeline

---

### Part 3: Estimate Story Points

**For each story, assign points using Fibonacci scale:**

**Estimation guidelines:**
- **1 point [E]:** Trivial (1-2 hours) - Config change, text update
- **2 points [D]:** Simple (2-4 hours) - Basic CRUD, simple component
- **3 points [C]:** Moderate (4-8 hours) - Complex component, business logic
- **5 points [B]:** Complex (1-2 days) - Feature with multiple components
- **8 points [A]:** Very Complex (2-3 days) - Full feature frontend + backend
- **13 points [S]:** Epic-sized (3-5 days) - **BREAK THIS DOWN**

**Estimation factors:**
- Complexity of business logic
- Number of components/files to change
- Dependencies on other stories
- Testing complexity
- Unknowns or research needed

**Ask user for estimation input (if needed):**
> "I've estimated STORY-006 (Product listing page) at 8 points (2-3 days). Does this align with your expectations? Adjust if your team's velocity differs."

**Validate:**
- No story >8 points (break down if needed)
- Point distribution is balanced
- Infrastructure stories are included

---

### Part 4: Calculate Team Capacity

**Ask user:**
> "Let's determine your sprint capacity.
>
> 1. How many developers on the team? (default: 1)
> 2. Sprint length in weeks? (default: 2 weeks)
> 3. Any holidays or PTO during sprint?
> 4. Team experience level? (Junior: 4h/day, Mid: 5h/day, Senior: 6h/day productive)"

**Calculate capacity:**
```
Team size: {developers}
Sprint length: {weeks} weeks = {days} workdays
Productive hours/day: {hours} (default: 6)
Holidays/PTO: {days} off
Total hours: {developers} × ({days} - {days_off}) × {hours}
```

**Convert to story points:**
```
Velocity (if known from past sprints): {points/sprint}

If no velocity data:
- Junior team:  1 point = 4 hours
- Mid team:     1 point = 3 hours
- Senior team:  1 point = 2 hours

Capacity = Total hours ÷ hours per point
```

**Example:**
```
1 senior developer
2-week sprint = 10 workdays
6 productive hours/day
No holidays
Total: 1 × 10 × 6 = 60 hours
Velocity: 60 ÷ 2 = 30 points per sprint
```

---

### Part 5: Allocate Stories to Sprints

**Level 0 (1 story):**
- No sprint allocation needed
- Just create the single story
- Proceed directly to implementation

**Level 1 (1-10 stories):**
- Single sprint
- Allocate all stories
- Order by priority and dependency

**Level 2+ (Multiple sprints):**

For each sprint:

1. **Start with Must Have stories**
2. **Respect dependencies** (don't schedule dependent stories in wrong order)
3. **Fill to capacity** (target: 80-90% of capacity for safety)
4. **Group related stories** (keep epic stories together when possible)
5. **Leave buffer** (10-20% for unknowns and bugs)

**Sprint allocation format:**
```markdown
### Sprint 1 (Weeks 1-2) - {points}/{capacity} points

**Goal:** {What this sprint delivers}

**Stories:**
- STORY-001: User registration (5 points) [B] - Must Have
- STORY-002: User login (3 points) [C] - Must Have
- STORY-003: Password reset (3 points) [C] - Should Have
- STORY-INF-001: Database schema (5 points) [B] - Infrastructure

**Total:** 16 points / 30 capacity (53% — buffer for first sprint)

**Risks:** {identified risks}

**Dependencies:** {external dependencies}
```

**Validate allocation:**
- All Must Have stories are allocated
- Dependencies are respected
- Sprints are balanced (not overloaded)
- Each sprint has a clear goal
- Buffer exists for unknowns

---

### Part 6: Define Sprint Goals

**For each sprint, create a clear goal:**

**Good sprint goals:**
- "Complete user authentication with registration, login, and password reset"
- "Deliver product catalog with listing, search, and detail views"

**SMART goals:**
- Specific: What exactly is being delivered
- Measurable: Clear success criteria
- Achievable: Fits within capacity
- Relevant: Delivers user value
- Time-bound: Fits within sprint timeframe

---

### Part 7: Create Traceability

**Epic to Story mapping:**
```markdown
## Epic Traceability

| Epic ID | Epic Name | Stories | Total Points | Sprint |
|---------|-----------|---------|--------------|--------|
| Epic-001 | User Authentication | STORY-001, 002, 003, 004, 005 | 21 points | Sprint 1 |
| Epic-002 | Product Catalog | STORY-006, 007, 008, 009, 010 | 28 points | Sprint 1-2 |
```

---

### Part 8: Identify Risks and Dependencies

**Format:**
```markdown
## Risks

**High:**
- {risk} - mitigation: {mitigation}

**Medium:**
- {risk} - mitigation: {mitigation}

**Low:**
- {risk} - mitigation: {mitigation}
```

---

### Part 9: Generate Sprint Plan Document

```markdown
# Sprint Plan: {project_name}

**Date:** {date}
**Project Level:** {level}
**Total Stories:** {count}
**Total Points:** {sum}
**Planned Sprints:** {count}

---

## Executive Summary

{2-3 sentence overview}

**Key Metrics:**
- Total Stories: {count}
- Total Points: {sum}
- Sprints: {count}
- Team Capacity: {points} points per sprint
- Target Completion: {date}

---

## Story Inventory

{All stories with estimates, acceptance criteria, dependencies}

---

## Sprint Allocation

{Sprint-by-sprint breakdown}

---

## Epic Traceability

{Epic-to-story mapping}

---

## Risks and Mitigation

{Risks}

---

## Definition of Done

For a story to be considered complete:
- [ ] Code implemented and committed
- [ ] Unit tests written and passing (≥80% coverage)
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Deployed to {environment}
- [ ] Acceptance criteria validated

---

## Next Steps

Begin Sprint 1. Run `/create-story STORY-001` to create a detailed story document,
or `/dev-story STORY-001` to start implementing immediately.

---

## Export Guide

This document is structured for direct import into productivity tools.

### Label Reference

| Label | Points | Complexity |
|-------|--------|-----------|
| E | 1 | Trivial |
| D | 2 | Simple |
| C | 3 | Moderate |
| B | 5 | Complex |
| A | 8 | Very Complex |
| S | 13 | Epic-sized (break down) |

### Notion
1. Open a Notion page and type `/` → select **Import** or paste directly.
2. Paste the full Markdown content — headings, tables, and checkboxes render natively.
3. Each story can be converted to a Notion database entry: highlight the story block → **Turn into** → **Page**.
4. Map fields: `Story Points` → Number property, `Label` → Select property, `Priority` → Select property.

### Jira
1. Create a new **Epic** per epic in this plan.
2. Create a **Story** issue per `STORY-XXX` entry.
3. Copy `User Story`, `Acceptance Criteria`, and `Technical Notes` into the issue description.
4. Set `Story Points` from the `Story Points` field and add the `Label` as a tag.

### Linear
1. Create a new **Project** for this sprint plan.
2. Create one **Issue** per story.
3. Paste the story Markdown into the issue description — Linear renders it natively.
4. Map `Label` to Linear's **Size** property (E=XS, D=S, C=M, B=L, A=XL, S=Epic).

### GitHub Projects
1. Create one **Issue** per story in the repository.
2. Copy `Acceptance Criteria` as a task list (`- [ ] ...`) in the issue body.
3. Add the `Label` field as a GitHub label (create labels: `size/E`, `size/D`, etc.).
4. Add issues to a GitHub Project board and map to sprints using iterations.

### ClickUp / Trello / Others
- One card/task per story.
- Use `Story Points` as the effort/points field.
- Use `Label` as the size tag or card label.
- Copy `Acceptance Criteria` as a checklist.
```

**Save document** per `helpers.md#Save-Output-Document`:
- Path: `docs/sprint-plan-{project-name}-{date}.md`

---

### Part 10: Initialize Sprint Status

**Create `docs/sprint-status.yaml`:**

```yaml
project_name: "{project_name}"
project_level: {level}
current_sprint: 1
sprint_plan_path: "docs/sprint-plan-{project}-{date}.md"
last_updated: "{date}"

sprints:
  - sprint_number: 1
    start_date: "{date}"
    end_date: "{date + sprint_length}"
    capacity_points: {capacity}
    committed_points: {committed}
    completed_points: 0
    status: "not_started"
    goal: "{sprint goal}"
    stories:
      - story_id: "STORY-001"
        title: "{title}"
        points: {points}
        status: "not_started"
        assigned_to: null
      - story_id: "STORY-002"
        title: "{title}"
        points: {points}
        status: "not_started"
        assigned_to: null

velocity:
  sprint_1: null
  rolling_average: null

team:
  size: {developers}
  sprint_length_weeks: {weeks}
  capacity_per_sprint: {points}
```

**Save per** `helpers.md#Update-Sprint-Status`

---

## Display Summary to User

```
✓ Sprint Plan Created!

Project: {project_name} (Level {level})

Summary:
- Total Stories: {count}
- Total Points: {sum}
- Planned Sprints: {count}
- Team Capacity: {points} points/sprint
- Target Completion: {date}

Sprint 1 Goal: {goal}
Sprint 1 Stories: {count} stories, {points} points

Full plan: docs/sprint-plan-{project}-{date}.md

Ready to begin implementation!
Run /create-story STORY-001 or /dev-story STORY-001 to start.
```

---

## Story Point Calibration

**1 point [E] (1-2 hours):** Config change, text update, simple fix
**2 points [D] (2-4 hours):** Basic CRUD endpoint, simple component
**3 points [C] (4-8 hours):** Complex component, business logic, integration tests
**5 points [B] (1-2 days):** Feature with frontend + backend, data migration
**8 points [A] (2-3 days):** Complete user flow, multiple components, external service integration
**13 points [S] (3-5 days):** **TOO BIG — BREAK IT DOWN**

---

## Tips for Effective Sprint Planning

- Target 2-5 points per story
- Leave 10-20% buffer for unknowns
- Put infrastructure stories in Sprint 1
- Each sprint should deliver something demo-able
- Respect technical dependencies in allocation order

---

## Notes for LLMs

- Use TodoWrite to track the 10 sprint planning parts
- Break stories systematically — don't skip any requirements
- Apply sizing strictly (no stories >8 points)
- Calculate realistic capacity based on team size and experience
- Create traceability tables to ensure full coverage
- Reference helpers.md for all common operations
- Initialize sprint-status.yaml for ongoing tracking
- Hand off to Developer when ready for implementation
