# Find Top Users for an Event

Ranks the users who performed an event most frequently over a given time period, with email addresses when available.

## How to use

```
/mixpanel:top-users
```

Optionally provide context:
```
/mixpanel:top-users for "Purchase Completed" last 7 days
/mixpanel:top-users for "mcp_tool_call" yesterday
```

## What this command does

1. **Resolves the event name** — if not provided, asks which event to analyze. Uses `Get-Events` to confirm the exact name if unsure.

2. **Discovers user identifier properties** using `Get-Property-Names` on the event:
   - Looks for an email property (e.g. `Email`, `email`, `$email`, `user_email`) — property names are case-sensitive and project-specific, so always check the actual list
   - Falls back to a user/account ID property (e.g. `user_id`, `userId`, `account_id`, `distinct_id`)
   - Notes which identifier was found and which was unavailable

3. **Runs the ranking query** using `Run-Segmentation-Query`:
   - `on=properties["<email_property>"]` if an email property exists
   - Otherwise `on=properties["<id_property>"]`
   - `type=general`, `unit=day`, date range covering the requested period
   - Returns up to 60 ranked buckets by event count

4. **Presents the results** as a ranked table:

```
## Top users — Purchase Completed (last 7 days)

| Rank | Email | Count |
|------|-------|-------|
| 1 | alice@example.com | 47 |
| 2 | bob@example.com | 31 |
| 3 | carol@example.com | 28 |
...

Identifier used: Email (event property)
```

   If only an ID property was found, the table uses that column and notes that email was not available as an event property on this event.

5. **Notes any limitations** — e.g. if neither email nor a user ID property was found, suggests running `Get-Property-Names` manually to identify what user-level properties are tracked on this event.

## Property lookup rules

- Always call `Get-Property-Names` on the event before writing `on=` — never guess the property name
- Check for email candidates first: scan for any property containing "email" (case-insensitive)
- If no email property exists, scan for ID candidates: `user_id`, `userId`, `account_id`, `$distinct_id`
- `user["property_name"]` (user profile join) is a fallback only when event properties are absent — it requires `$distinct_id` to match between the event and the user profile, and fails silently as `undefined` when it doesn't

## Guidance files

- `skills/analysis/SKILL.md` — segmentation query patterns, property breakdown syntax
- `skills/mixpanel/SKILL.md` — identity model, event and user properties
