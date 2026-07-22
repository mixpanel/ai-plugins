# Command: target

Change which level(s) the skill writes business context to: org-level, project-level, or both.

**Session reads:** `org_id`, `org_name`, `project_id`, `project_name`, `caller_role`
**Session writes:** `target_level`

---

## Prompt

Ask which level the user wants to target:

```
Where should business context live?
  1. Org level only    — shared across all projects
  2. Project level only — scoped to [Project Name]
  3. Both              — org context + project-specific context
```

## Validate permissions

Check `caller_role` for the chosen target(s) against SKILL.md's "Permissions gate writes" constraint (the canonical role matrix). If the user lacks write permission for a level, name the required role from that matrix and offer alternatives:

- Can't write to org → offer targeting project only.
- Can't write to project → offer targeting org only, or exporting locally.

## Set and confirm

Update `target_level` to `"org"`, `"project"`, or `"both"`. Confirm back to the user: "Got it — targeting [level(s)]."

## Follow-on

Offer the next natural step based on where they are in the workflow:
- If they haven't run `status` yet: "Want me to check your AI readiness **status** first?"
- If they have context to import: "Ready to **import** your existing context?"
- Otherwise: "Ready to **set up** context from scratch?"
