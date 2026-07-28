ConvusRevies is a Rails webapp

[mise](https://mise.jdx.dev/) is used for Ruby and Node version management.

# Development

Start the dev server with `bin/dev`

Run `eval "$(ruby bin/env --export)"` once so `$DEV_PORT` and `$BASE_URL` are set — `bin/env` reads `$CONDUCTOR_PORT` and falls back to `3009`, so the dev server is at `$BASE_URL` ([http://localhost:3009](http://localhost:3009) outside a Conductor workspace). `config/boot.rb` requires `bin/env`, so Ruby entry points already have them; only export into the shell when the shell itself reads them (e.g. `curl "$BASE_URL/..."`).

Check whether the dev server is up: `curl -fs "$BASE_URL/" >/dev/null`. If it isn't, **stop and ask the user to start it**.

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments)

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
bundle install # install ruby dependencies
bundle exec rails db:create db:migrate # create the databases
```
