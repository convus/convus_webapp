---
name: frontend-screenshots
description: >-
  Capture desktop+mobile viewport screenshots of local pages served by
  `bin/dev` via Playwright MCP, with a PII safety check that keeps real
  data out of uploaded images. Use whenever a task needs screenshots of local
  pages — PR documentation, bug repros, before/after comparisons across
  branches, design review, demos — including mid-interaction states like an
  open dropdown, a modal showing, a form mid-fill, or a hover. Use it even when
  the user just says "grab a screenshot" or "show me what this looks like"
  without naming Playwright. For a component that only renders under an env var
  / feature flag / hard-to-reach state, screenshot its Lookbook preview URL
  instead of a full page. Inputs: `(url-path, page-slug)` pairs, optionally with
  per-URL interaction steps. Output: local PNG paths.
allowed-tools: Bash, Read
---

# Frontend screenshots

Drive Playwright MCP to capture viewport screenshots of pages served by `bin/dev`.

## Output filenames (load-bearing — callers parse these)

`tmp/pr_screenshots/<branch>-<page>-<timestamp>-{desktop,mobile}.png`, where `<branch>=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')` and `<timestamp>=$(date +%Y%m%d-%H%M%S)`. Cross-branch shots get an extra `-main-` segment.

## Preflight

- `eval "$(ruby bin/env --export)"` so `$WORKSPACE_ID`, `$DEV_PORT`, `$BASE_URL`, and `$REDIS_URL` are set. **Each Bash tool call is a fresh shell, so re-export in any shell that reads `$BASE_URL`** — `eval "$(ruby bin/env --export)" && curl …` chained in one call is the safe pattern.
- `curl -fs "$BASE_URL/" >/dev/null` — if it isn't up, **stop and ask the user to start it** (`bin/dev`). `bin/env` resolves `$DEV_PORT` from the workspace ID in `.workspace_id` (falling back to `3009` in the root checkout), so the `bin/dev` the user starts binds to the same port and databases this skill expects.
- If `bin/dev` exits immediately with `Could not find 'bundler' (X.X.X)` or similar, the shell resolved system Ruby 2.6 instead of mise-installed 4.0.6 — see the [`sandbox-test-setup`](../sandbox-test-setup/SKILL.md) skill's local-macOS section for the one-line PATH fix; don't reinstall.
- If `mcp__playwright__*` tools aren't registered, the project's `.mcp.json` defines the `playwright` server — approve it on project entry (Claude Code prompts) and restart the session, or `/mcp` → **playwright** → reconnect. A server added mid-session doesn't load until restart.

## Sign in (when needed)

The MCP browser session persists across calls, so signing in is a one-time-per-session step. For public pages (the root page, Lookbook previews at `/lookbook/...`, etc.), skip this entirely. **Only ever authenticate against the local dev server** (`$BASE_URL` / localhost) — never sign in to any other host, and never create, promote, or impersonate users to bypass auth.

`db/seeds.rb` is the stock empty Rails template — convus_webapp doesn't seed any users, so there's no fixed credential to drive Playwright with. When a navigation lands on `/users/sign_in`, ask the user for an email/password to sign in with (and which role, if it matters: `User#role` is `basic_user`, `developer`, or `admin` — `admin_access?` is true for `developer` or `admin`, and gates `/admin/...` routes). Fill `Email` + `Password` and click `Log in`; the post-login redirect dumps you on `/` (or the originally-requested path if Devise stored it).

**Don't upload real PII.** Screenshots are permanent once uploaded. Even when signed in, if a page shows records that don't look like test data (unfamiliar names/emails, real-looking user content), stop and ask — the dev DB may have been loaded with production data.

## Capture

Clear stale shots: `rm -f tmp/pr_screenshots/<branch>-<page>-*.png 2>/dev/null || true`.

Two viewports — resize once each, then walk every URL:
1. `browser_resize` 1440×900 → for each URL: navigate → settle → `browser_take_screenshot` (`fullPage: true`) to `...-desktop.png`.
2. `browser_resize` 390×844 → same loop → `...-mobile.png`.

**Pass the path as workspace-relative**, e.g. `tmp/pr_screenshots/<branch>-<page>-<ts>-desktop.png`. Playwright MCP rejects absolute paths that escape the workspace root with `File access denied: … is outside allowed roots`.

**Full page, no `target:` arg.** Capture the whole page (`fullPage: true`) so nothing below the fold is cut off. convus_webapp's layout (`app/views/layouts/application.html.erb`) has no site footer, so there's nothing to hide before the shot.

Element-only crops (`target:`) still slice context off — don't use them for page captures.

**Settle before the screenshot.** Stimulus + Chartkick render after document load; either `browser_wait_for` on a known element or pause ~500ms–1s. Otherwise charts capture mid-draw.

**Mid-interaction states are in scope.** When the caller asks for a dropdown open, a modal showing, a hover state, a partially-filled form, etc., drive Playwright between settle and the screenshot — `browser_click`, `browser_type`, `browser_press_key`, `browser_hover`, then wait for the UI to reach the target state (`browser_wait_for` on a marker element, or check via `browser_evaluate`) before `browser_take_screenshot`. Treat the interaction sequence as part of the page-slug — e.g. capture `dropdown-open` after clicking, distinct from a static page-load shot. For cross-branch comparisons, run the *same* interaction sequence on each branch so the screenshots actually compare like-for-like.

Sanity-check each PNG: under ~5 KB usually means the page errored. Pull `browser_console_messages` and look only for **uncaught exceptions from app code** (Stimulus registration failures, `TypeError`s in `app/javascript/**`) — asset 404s and third-party deprecation warnings are noise. To diagnose a failed capture: HTTP status via `curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL/<path>"`, response body via `curl -s "$BASE_URL/<path>" | head -200`, full backtrace via `tail -200 log/development.log`.

Only stop and surface to the user once you understand the cause and either (a) have a fix to propose, (b) need input they must provide (e.g. which URL to screenshot instead), or (c) concluded it's a real bug in the diff.

## Component previews (when no page shows the state)

Some components only render in a context you can't reproduce on a normal dev page — gated by an env var, a feature flag, or a hard-to-reach error/empty state. When a component has a Lookbook preview, screenshot the **preview URL** instead of hunting for a page that happens to render it:

```
$BASE_URL/lookbook/preview/<preview_path>/<scenario>
```

`<preview_path>` is the component's module nesting underscored (drop the `ComponentPreview` suffix), and `<scenario>` is the preview method. `UI::Dropdown::ComponentPreview#placements` → `/lookbook/preview/ui/dropdown/placements`. If a scenario doesn't exist yet, add a method to the component's `*_preview.rb` first — a preview that renders the exact state (pass the args that trigger it) is often the fastest path to a clean shot.

The preview page loads Tailwind and renders the component standalone (no site chrome), so capture the viewport as usual (`fullPage: false`); a small render-timing line at the bottom is harmless. Everything else still applies — same PII caution, same `(url-path, page-slug)` naming (use a slug like `dropdown-placements`).

convus_webapp's component previews render from static sample data (`OpenStruct` records, hardcoded chart series) rather than the dev DB, so there's no seed step before a preview renders. This is component-only: a preview can't show layout/stacking against the rest of the page (e.g. a navbar z-index fix), so use a real page for those.

## Cross-branch comparison (optional)

When the caller wants before/after, repeat the capture loop against `main`.

1. `git status` — abort if there are uncommitted changes.
2. Diff `db/migrate/` between the branch and `main`; abort if it changed — a branch-only migration leaves the DB schema ahead of `main`'s code, so `main` pages can error.
3. `BRANCH=$(git rev-parse --abbrev-ref HEAD)`, `git checkout origin/main` (detached — `git checkout main` fails if a sibling worktree holds the `main` branch; detached HEAD at `origin/main` is allowed concurrently and is the same code), navigate the browser to force Rails to reload the changed files, repeat capture into `...-main-...` filenames, then `git checkout $BRANCH`.

A `Gemfile.lock` diff is **not** a reason to abort.

The dev DB persists across checkouts, so any signed-in session usually still works.

## Clean up

Once every screenshot is captured, quit Chrome with `browser_close`. Leaving it running holds the shared browser profile lock, so the next `browser_navigate` (this skill or another) fails with "Browser is already in use". Always close it before returning, even if the capture failed partway.
