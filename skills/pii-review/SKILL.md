---
name: pii-review
description: Scan Mixpanel event and user properties for PII. Flag unmarked sensitive properties and update them in Lexicon.
---

# PII Review

Identify personally identifiable information (PII) in Mixpanel event and user properties and ensure all sensitive fields are marked `sensitive: true` in Lexicon.

## When to Use

- Before a security or compliance audit
- When onboarding a new project
- After adding new user registration or profile flows

## PII Patterns to Scan For

| Category | Property name signals |
|----------|-----------------------|
| Email | `email`, `$email`, `user_email`, `contact_email` |
| Name | `name`, `first_name`, `last_name`, `full_name`, `username` |
| Phone | `phone`, `mobile`, `phone_number` |
| Address | `address`, `street`, `city`, `zip`, `postal_code`, `location` |
| IP / device | `ip`, `ip_address`, `device_id`, `mac_address` |
| Identity | `ssn`, `tax_id`, `passport`, `national_id`, `dob`, `date_of_birth` |
| Financial | `credit_card`, `card_number`, `bank_account`, `iban` |
| Health | `diagnosis`, `condition`, `medication`, `health_record` |

Also flag free-text properties that may capture user input verbatim: `query`, `search_term`, `message`, `note`, `comment`, `feedback`.

## Scan Workflow

### 1. Pull all event properties

```
Get-Property-Names resource_type=Event project_id=<id>
```

For targeted scans, pull per event:
```
Get-Property-Names resource_type=Event event="<event>" project_id=<id>
```

### 2. Pull user profile properties

```
Get-Property-Names resource_type=User project_id=<id>
```

### 3. Match against PII patterns

For each property name, check against the patterns above. Flag any match as a PII candidate.

Also check for obfuscated or abbreviated names — `em`, `ph`, `addr`, `fn`, `ln` — that may represent PII fields.

### 4. Verify with sample values

For flagged properties, confirm what values are actually being sent:
```
Get-Property-Values resource_type=Event event="<event>" property="<property>"
Get-Property-Values resource_type=User property="<property>"
```

If values confirm PII (e.g. actual email addresses, phone numbers), escalate. If values are hashed or tokenized, document that in the property description.

### 5. Mark sensitive in Lexicon

For each confirmed PII property:
```
Edit-Property:
  project_id:    <id>
  resource_type: "Event"   # or "User"
  property_name: "<property>"
  sensitive:     true
  description:   "<what this is; note if hashed/tokenized>"
```

`sensitive: true` hides the property values from Mixpanel's UI for non-admin users.

## Remediation Options

| Situation | Action |
|-----------|--------|
| PII being sent in plain text | Fix the SDK call — hash, tokenize, or remove before tracking |
| PII is intentional and needed | Mark `sensitive: true`; restrict project access to authorized users |
| Free-text field may capture PII | Mark `sensitive: true`; add description noting the risk |
| Property is hashed/anonymized | Mark `sensitive: true`; document hashing method in description |

## Output: PII Audit Report

```
## PII Audit — <date>

### Confirmed PII (action required)
| Property | Type | Event(s) | Status | Action |
|----------|------|----------|--------|--------|
| `$email` | Email | User Account Created | Not marked sensitive | Mark sensitive |
| `full_name` | Name | Profile Updated | Not marked sensitive | Evaluate — remove or mark |

### Already marked sensitive
| Property | Type |
|----------|------|
| `phone_number` | Phone |

### Free-text fields (monitor)
| Property | Event | Risk |
|----------|-------|------|
| `search_query` | Search Performed | May capture names or emails |

### Not PII (cleared)
X properties scanned, no PII detected.
```

## Important Notes

- `sensitive: true` controls **visibility in the UI** — it does not delete stored data or prevent ingestion
- To stop collecting a PII property entirely, fix the SDK call and set `dropped: true` on the property
- Mixpanel does not natively support deletion of specific property values — use [User Deletion API](https://developer.mixpanel.com/reference/delete-users) for GDPR/CCPA requests
