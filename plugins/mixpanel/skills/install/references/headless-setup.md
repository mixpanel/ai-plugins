# mixpanel-headless SDK setup

Source: **https://docs.mixpanel.com/docs/mixpanel-headless** and the
quickstart it links on GitHub.

## What it is

An open-source Python SDK that exposes the full Mixpanel platform — every
query engine, report type, and configuration — as a single Python object.
Built for coding agents and developers: anything that writes or generates
Python to call Mixpanel. Distinct from the MCP server (which serves
conversational clients).

## Install

1. Verify the environment:
   ```bash
   python3 --version   # 3.9+
   pip3 --version
   ```
2. If the project uses a virtualenv/poetry/uv environment, install into that;
   otherwise offer a venv before installing globally.
3. Install:
   ```bash
   pip install mixpanel-headless
   ```

## Authenticate

Follow the quickstart linked from the docs page. Authentication uses Mixpanel
**service-account credentials** supplied via environment variables — set them
in the user's shell profile or the project's untracked env file (e.g.
`.env`, confirmed gitignored). **Never** write credentials into
`.claude/mixpanel.json` or any tracked file.

The user creates a service account in Mixpanel: Organization Settings →
Service Accounts (they need admin/owner rights, or should ask an admin).

## Verify

Run a trivial call to prove import + auth work, e.g.:

```bash
python3 -c "import mixpanel_headless as mh; print(mh.__version__)"
```

then a minimal authenticated operation per the quickstart (e.g. listing
projects). On failure:
- `ImportError` → wrong interpreter/venv; confirm which `python3` the project
  uses and reinstall there.
- Auth error → credentials missing/typoed in env vars, or the service account
  lacks access to the target project.

## Rate limits

Standard usage is rate-limited (60 requests/hour at the time of writing);
production workloads need early access — see the docs page. Surface this to
the user if their workflow is query-heavy.
