ConvusRevies is a Rails webapp

[mise](https://mise.jdx.dev/) is used for Ruby and Node version management.

# Development

Start the dev server with `bin/dev`

Run `eval "$(ruby bin/env --export)"` once so `$WORKSPACE_ID`, `$DEV_PORT`, `$BASE_URL`, and `$REDIS_URL` are set. `config/boot.rb` loads `bin/env` for every Ruby entry point, so those are already set inside any Rails process; only export them into the shell when the shell itself reads them (e.g. `curl "$BASE_URL/..."`).

`bin/env` reads the workspace ID from `.workspace_id` (written by `bin/workspace_setup`) and uses it as `$DEV_PORT`, so each checkout gets its own port, its own postgres databases (`convus_reviews_{development,test}_<id>`), and its own redis database. Without a `.workspace_id` — the root checkout — it falls back to port `3009` and the databases go un-suffixed.

Check whether the dev server is up: `curl -fs "$BASE_URL/" >/dev/null`. If it isn't, **stop and ask the user to start it**.

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments). Use `bin/char_count {FILE OR FOLDER}` to get the non-whitespace character count

## Testing

This project uses Rspec for tests. All business logic should be tested.

- Tests should either: help make the code correct now or prevent bugs in the future. Don't add tests that don't do one of those things.
- Use `context` and `let` to make the differences between tests clear
- Use request specs, not controller specs. Everything making the same request should be in a single test
- Avoid testing private methods
- Avoid mocking objects

The `rspec-testing` skill covers the rest of the project-specific style. The `integration-testing` skill covers `:js, type: :system` browser specs — in this project those are the component system specs at `spec/components/**/component_system_spec.rb`.

## Frontend Development

Uses Stimulus.js for JavaScript and Tailwind CSS for styling. `bin/dev` runs `tailwindcss:watch`; JS is served via importmap with no build step.

The `frontend-conventions` skill covers the `Form::Group`/`Form::Input` components, the `twlink` class, the `number_display` helper, `UI::Time::Component`, the collapse helpers, and ViewComponent rules.

## Pull requests

- When creating a PR, run the `/pr` workflow rather than calling `gh pr create` directly — `/pr` detects frontend diffs, captures desktop+mobile screenshots, and posts them as a `## Screenshots` PR comment.
- To attach a local image (screenshot, .png/.jpg) to an existing GitHub PR, the `gh` CLI **cannot upload images** — use the `github-upload-image-to-pr` skill, which drives a real browser to GitHub's user-attachments uploader.

# Initial setup

```bash
bin/workspace_setup # assign a workspace ID, then run bin/setup
```

`bin/workspace_setup` claims the next free ID from the local `dev_workspaces`
postgres database, writes it to `.workspace_id` (gitignored), and execs
`bin/setup` — which installs gems and JS deps, then creates, loads, migrates,
and seeds the databases. Pass `--without_seeds` to skip seeding and
`parallel:prepare`. Conductor runs it automatically on workspace creation
(`conductor.json`).

Use `bin/setup` on its own only when the checkout already has a `.workspace_id`
(or is the root checkout, which intentionally has none and uses the un-suffixed
databases).

`bin/workspace_teardown` reverses it: stops `bin/dev`, drops that workspace's
databases, releases the ID for reuse, and removes `.workspace_id`. It only
touches databases whose names end in `_<id>`, so the shared un-suffixed ones are
never at risk. Conductor runs it on workspace deletion.
