# Scrum Master Helper Utilities

This document contains reusable utilities for Scrum Master workflows. Skills and commands reference specific sections to avoid repetition.

## Config Loading

### Load Global Config
```
Path: ~/.claude/config/bmad/config.yaml (or project-level equivalent)
Purpose: Get user settings and defaults

Using Read tool:
1. Read config file
2. Parse YAML to extract:
   - user_name
   - communication_language
   - default_output_folder
3. Store in memory for workflow
```

### Load Project Config
```
Path: {project-root}/docs/project-config.yaml (or bmad/config.yaml if using BMad)
Purpose: Get project-specific settings

Using Read tool:
1. Read config file
2. Parse YAML to extract:
   - project_name
   - project_type
   - project_level
   - output_folder (default: docs/)
3. Merge with global config (project overrides global)
```

### Combined Config Load
```
Execute in order:
1. Load global config (defaults)
2. Load project config (overrides)
3. Return merged config object
4. If no config found, use defaults:
   - output_folder: docs/
   - project_level: 1
```

## Status File Operations

### Load Workflow Status
```
Path: {output_folder}/workflow-status.yaml
Purpose: Check completed workflows, current phase

Using Read tool:
1. Read docs/workflow-status.yaml
2. Parse YAML to extract:
   - project metadata
   - workflow_status entries
3. Determine current phase:
   - Find last completed workflow
   - Identify next required/recommended workflow
```

### Update Workflow Status
```
Purpose: Mark workflow as complete

Using Edit tool:
1. Load current status file
2. Find workflow by name
3. Update status field with file path or timestamp
4. Update last_updated field
5. Save changes
```

### Load Sprint Status
```
Path: {output_folder}/sprint-status.yaml
Purpose: Check epic/story progress

Using Read tool:
1. Read docs/sprint-status.yaml
2. Parse YAML to extract:
   - current_sprint number
   - sprints array (each with stories, points, status)
   - velocity data
   - team capacity
```

### Update Sprint Status
```
Purpose: Add/update epics, stories and sprint data

Using Edit tool:
1. Load current sprint status
2. Modify sprints/stories array
3. Recalculate metrics (points done, completion %)
4. Update last_updated timestamp
5. Save changes
```

## Template Operations

### Load Template
```
Purpose: Load document template for workflow

Using Read tool:
1. Read template from local commands/ folder or inline
2. Store template content
3. Extract variable placeholders: {variable_name}
```

### Apply Variables to Template
```
Purpose: Substitute {variables} with actual values

Process:
1. For each variable in template:
   - {project_name} → from config
   - {date}         → current date (YYYY-MM-DD)
   - {user_name}    → from config
2. Replace all {variable} with values
3. Return completed document
```

### Save Output Document
```
Purpose: Write completed document to output folder

Using Write tool:
1. Determine output path:
   - {output_folder}/{workflow-name}-{project-name}-{date}.md
   - Example: docs/sprint-plan-myapp-2025-01-11.md
2. Write content to path
3. Return file path for status update
```

## Variable Reference

### Standard Variables
```
{project_name}     → config: project_name
{project_type}     → config: project_type
{project_level}    → config: project_level
{user_name}        → config: user_name
{date}             → current date (YYYY-MM-DD)
{output_folder}    → config: output_folder (default: docs/)
```

### Level-Based Logic
```
Level 0 (1 story):         No sprint needed, direct to implementation
Level 1 (1-10 stories):    Single sprint, light planning
Level 2 (5-15 stories):    1-2 sprints, standard planning
Level 3 (12-40 stories):   2-4+ sprints, full planning with velocity
Level 4 (40+ stories):     Multiple sprints, enterprise planning
```

## Workflow Recommendations

### Determine Next Workflow
```
Input: workflow_status file
Output: recommended next workflow

Logic:
1. If no requirements doc → Recommend: create PRD or tech-spec first
2. If requirements exist, no sprint plan → Recommend: /sprint-planning
3. If sprint plan exists, stories pending → Recommend: /create-story or /dev-story
4. If sprint in progress → Recommend: /sprint-status
5. If sprint complete → Recommend: /velocity-report, then plan next sprint
```

### Status Display Format
```
✓ = Completed
⚠ = Required but not started
→ = Current/in progress
- = Optional or not started

Example:
✓ Requirements: docs/prd-myapp-2025-01-10.md
→ Sprint Planning [CURRENT]
  ⚠ sprint-plan (not started)
- Implementation
  - STORY-001 (not started)
```

## Path Resolution

### Resolve Output Folder
```
Default: docs/
Override: from project config output_folder field
Fallback: create docs/ if it does not exist
```

### Standard File Paths
```
docs/sprint-plan-{project}-{date}.md    → Sprint plan document
docs/sprint-status.yaml                 → Sprint tracking status
docs/stories/STORY-{ID}.md             → Individual story files
docs/workflow-status.yaml              → Overall workflow status
```

## Error Handling

### File Not Found
```
If config file missing:
  - Use defaults (output_folder: docs/, project_level: 1)
  - Inform user and continue

If sprint-status.yaml missing:
  - Inform user no active sprint found
  - Suggest running /sprint-planning first

If PRD/tech-spec missing:
  - Inform user that requirements are needed
  - Suggest creating requirements before sprint planning
```

### Invalid YAML
```
If YAML parse error:
  - Show the file path and error
  - Ask user to check file formatting
  - Offer to reinitialize status file
```

## Token Optimization Tips

### Reference vs. Embed
```
Good: "Per helpers.md#Load-Sprint-Status"
Bad:  Embed all instructions inline in every command

Good: "Use standard variables from helpers.md#Standard-Variables"
Bad:  List all variables in every template
```

### Lazy Loading
```
Good: Load sprint status only when /sprint-status or /velocity-report is called
Bad:  Load all files upfront on every activation
```
