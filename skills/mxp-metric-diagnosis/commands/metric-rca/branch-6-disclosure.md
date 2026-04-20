# Branch 6 — External factor disclosure (Step 10)

**Not a detection branch — a disclosure layer.** Always runs, regardless
of mode, regardless of what earlier branches found. Produces no queries.

Writes to `rca_context.branch_6_findings` (schema in `preflight.md`).

The purpose: the skill must **explicitly acknowledge what Mixpanel
cannot see**. This is a credibility thing. A skill that over-claims is
trusted less than one that names its own blind spots.

---

## 10.1 What to disclose

Build the disclosure list from four standard categories, tailored to
the drift window:

| Category | Concrete examples for the disclosure | When to include |
|---|---|---|
| **External traffic** | "marketing spend changes, SEO rankings, store listing changes, app-store review scores" | Always |
| **Competitive moves** | "competitor launches, pricing changes, or feature parity announcements" | Always |
| **Macro factors** | "holidays, regional events, news cycles, or seasonal patterns" | Always — tailor to the drift window (e.g., cite specific Indian festivals if the drift window overlaps Diwali, Eid, Onam, New Year, or cricket finals) |
| **Customer-side changes not instrumented** | "pricing changes, feature flags, A/B tests, or backend migrations not tracked as Mixpanel properties" | Always |

If `rca_context.metric_type = retention`, add a fifth line specific to
retention metrics: "product changes that shifted what the first-session
experience looks like for new cohorts — often not visible in event
volumes alone."

Store the macro-factor tailoring in
`rca_context.branch_6_findings.drift_window_tailored_events` as a list of
relevant events matching the drift window dates.

---

## 10.2 Output template

Branch 6's output is a single section, phrased as a prompt to the CSA
— not an attempt to answer anything:

> **What Mixpanel couldn't see**
>
> Mixpanel has no visibility into:
> - `<External traffic examples>`
> - `<Competitive moves examples>`
> - `<Macro factors, tailored to drift window>`
> - `<Customer-side changes not instrumented>`
>
> Worth asking `<customer_context>` whether any of these changed between
> `<baseline_window>` and `<drift_window>`.

`<customer_context>` is populated with the customer name if known from
the project profile (e.g., "the JioHotstar team"), otherwise a generic
"the customer." Store the resolved label in
`rca_context.branch_6_findings.customer_context_label`.

---

## 10.3 Position in final output

Branch 6's disclosure always appears as the **last section** of the
final output, below all other findings and below the scope-limits line.
It's a closing layer, not a finding to be ranked.
