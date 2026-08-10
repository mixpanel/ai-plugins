# mixpanel-headless SDK setup

Source: **https://docs.mixpanel.com/docs/mixpanel-headless** and the quickstart it links on GitHub.

## Documentation

- **Base instructions ship with the SDK**: every installation bundles agent instructions at `mixpanel_headless/CLAUDE.md` — the auth model, entry points, and full method catalog, always matching the installed version. Read them before your first call:

  ```bash
  python3 -c "import mixpanel_headless, pathlib; print((pathlib.Path(mixpanel_headless.__file__).parent / 'CLAUDE.md').read_text())"
  ```

- Web: https://docs.mixpanel.com/docs/mixpanel-headless (overview) and https://mixpanel.github.io/mixpanel-headless/ (full docs: getting started, API reference, CLI reference, user guide).
- Also self-documenting: the `mp` CLI has comprehensive `--help` on every command, and every Python method carries a complete docstring (`help()` on any object). Prefer these over guessing an API surface.

## What it is

An open-source Python SDK that exposes the full Mixpanel platform — every query engine, report type, and configuration — as a single Python object. Built for coding agents and developers: anything that writes or generates Python to call Mixpanel. Distinct from the MCP server (which serves conversational clients).

## Install

One command tells you whether it's already available — no other environment probing needed:

```bash
mp --version
```

If it prints a version, the SDK is installed — skip to Authenticate. (If `mp` is missing but `python3 -c "import mixpanel_headless"` succeeds, it's a PATH issue — fix the PATH or reinstall into the Python the project actually uses.) Otherwise install it into the project's existing Python environment (venv/poetry/uv if the project has one; requires Python 3.9+):

```bash
pip install mixpanel-headless
```

## Authenticate

One command handles every auth path — `mp login` reads the environment and picks the right flow:

```bash
mp login
```

- `MP_USERNAME` + `MP_SECRET` set → service account, no browser (region auto-probes us → eu → in).
- `MP_OAUTH_TOKEN` set → static bearer token, no browser (the CI/agent mode).
- Neither → browser OAuth (PKCE). Run the command yourself in the shell (generous timeout): it opens the user's browser and waits for the callback — just tell the user to complete the login there. Region defaults to **US**; pass `--region eu|in` for other clusters. It is non-TTY safe: with several accessible projects it exits with a structured error listing them — re-run with `--project <id>`.

Credentials and tokens live under `~/.mp/` — nothing touches the project. For non-interactive use, the user sets the env vars first (service account from Mixpanel → Organization Settings → Service Accounts, plus `MP_PROJECT_ID` and `MP_REGION`) in their shell profile or an untracked env file (e.g. `.env`, confirmed gitignored). **Never** write credentials into any tracked file.

## Verify

```bash
mp account test
```

(one command; add the account name if there are several). On failure:

- `ImportError` / `mp: command not found` → wrong interpreter/venv; confirm which `python3` the project uses and reinstall there.
- Auth error → OAuth: re-run `mp login`. Service account: env vars missing/typoed, or the account lacks access to the target project.

## Companion plugin

The SDK ships its own Claude Code plugin with deeper code-driven analysis skills (`mixpanelyst`, `dashboard-expert`, `setup`) that write Python using `mixpanel_headless` + pandas:

```bash
claude plugin marketplace add mixpanel/mixpanel-headless
claude plugin install mixpanel-headless
```

Optional — suggest it to users who want in-depth data-analyst workflows on top of this engine.

## Rate limits

Standard usage is rate-limited (60 requests/hour at the time of writing); production workloads need early access — see the docs page. Surface this to the user if their workflow is query-heavy.
