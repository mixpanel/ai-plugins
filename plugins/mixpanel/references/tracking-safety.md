# Tracking implementation safety

Read this reference immediately before changing application code in
`implement-mixpanel` or `maintain-mixpanel-tracking`. These are implementation
invariants, not a customer interview script. Resolve as much as possible from
the codebase, connected Mixpanel project, and supplied handoff before asking
the customer.

## Pipeline and project

- Search for an existing Mixpanel SDK, Segment, RudderStack, mParticle, GTM,
  PostHog, Amplitude, warehouse exports, and internal analytics wrappers before
  adding a dependency. Never create a second path that can emit the same event.
- Use the customer's existing CDP or wrapper when it is the established path.
  Installing a direct SDK alongside it requires an explicit architecture
  decision.
- Send test traffic only to a confirmed development or staging project. Never
  use production as a scratch project.
- Keep project tokens in the application's existing environment/configuration
  system. A token is a public project identifier, but it still should not be
  duplicated through source files.
- Confirm the project's US, EU, or India residency before configuring an
  ingestion host. A wrong host can result in no data without a useful client
  error.
- Verify current Mixpanel documentation before relying on plan entitlements,
  hard limits, or settings that cannot be reversed.

## Consent and data minimization

- Ask whether the customer's policy requires consent before non-essential
  analytics. If the answer is unknown for a regulated audience, delay SDK
  initialization until consent is known. This skill provides implementation
  guidance, not legal advice.
- Do not forward IP addresses, sensitive attributes, or free-form text unless
  the approved tracking plan and customer policy require them.
- Omit an unavailable property. Do not substitute `null`, an empty string,
  `"unknown"`, `0`, or `-1` merely to satisfy a schema.

## Identity

- Use the application's stable database identifier for `$user_id`; never use an
  email address.
- Identify only after authentication or account creation succeeds. Identify on
  login and on authenticated session restoration, not just on signup.
- Set user-profile properties after identification.
- Reset client identity on logout and account switching.
- Never merge two authenticated user IDs. Preserve one stable ID across
  devices.
- Do not create user profiles for anonymous visitors.
- When both client and server emit events, make their identity contract
  explicit so the same person does not fragment into unrelated users.

## Runtime delivery

- Keep browser SDK initialization client-only in server-rendered frameworks.
  Ensure initialization and consent resolution happen before any child code can
  track or identify.
- In short-lived server, serverless, job, or script runtimes, wait for the SDK's
  real delivery completion mechanism before returning. Do not assume awaiting a
  non-Promise tracking call flushes data.
- For retried server events, preserve the original event name, `distinct_id`,
  occurrence time, and `$insert_id`. Generate the insert ID once and persist it
  with the payload.

## Event model

- Use one stable event name for one meaning. Never construct event or property
  names dynamically.
- Reuse existing event/property names and enum values when they represent the
  same concept. Mixpanel names and values are case-sensitive.
- Prefer specific `snake_case` custom names; do not use reserved `$` or `mp_`
  prefixes.
- Send numeric and boolean values as their real types, not quoted strings.
- Prefer flat properties that answer a named business question.
- If Autocapture supplies page views, do not also enable automatic page-view
  tracking or add manual page-view events for the same interaction.
- Classify each proposed event as client-observable, server-confirmed, or
  unavailable in this repository. Never fabricate an event or property whose
  source of truth does not exist.

## Verification and mutations

- Compilation is not ingestion verification. Trigger representative events in
  development and confirm their names, properties, types, identity, and project
  in Live View or an equivalent live query.
- Report every planned event as instrumented, blocked, or omitted; do not hide
  gaps behind a successful build.
- Code-edit permission does not automatically authorize Mixpanel writes. Get
  explicit approval before changing Lexicon, creating reports, changing project
  settings, hiding/dropping data, or making other external mutations.
- Never rename, merge, hide, or drop an existing event as an incidental part of
  implementation. Present the impact and obtain separate confirmation.
- If verification cannot be run, state exactly what remains unverified and give
  the shortest reproducible verification procedure.
