# Tool resolution — moved to the plugin-wide convention

This skill's capability-map pattern was promoted to the plugin level. The capability map, the session capability-map build steps, and the per-engine execution rules now live in [`../../../ENGINE.md`](../../../ENGINE.md) — read that instead.

Everything still holds: every `cap:*` token used in this skill (SKILL.md, execution.md, and the command files) is a capability key defined in ENGINE.md's map — never a literal tool name. Build the session capability map once (per ENGINE.md's rules for the configured engine), cache it, and route every `cap:*` reference through it. `web-search` is not a Mixpanel capability — resolve it to whatever web search the runtime provides (skip gracefully if none, per `metric-rca.md`).
