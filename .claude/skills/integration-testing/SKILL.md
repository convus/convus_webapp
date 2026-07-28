---
name: integration-testing
description: >-
  Conventions for browser specs (`type: :system, :js`) in this project
  — every example pays a Selenium boot cost, so bias hard toward fewer,
  denser examples that walk through state via clicks, prefer
  named-element matchers over CSS selectors or `execute_script`, and
  combine same-setup work into one `it` even when scenarios feel
  independent. **Consult this skill any time you create or modify a
  `:js, type: :system` spec** — in this project that means component
  system specs at `spec/components/**/component_system_spec.rb`, the
  only browser specs this codebase has (there is no `spec/integration/`
  directory). Read alongside the `rspec-testing` skill for the project's
  general `context`/`let` style.
---

# Integration testing

Browser specs (`type: :system, :js`) in this project are component-level interaction specs at `spec/components/**/component_system_spec.rb` — there is no separate feature-flow directory (`spec/integration/` doesn't exist here). They run full Chrome sessions via Capybara/Selenium (`driven_by :selenium, using: :headless_chrome`, configured in `spec/rails_helper.rb`) and pay a real Selenium boot cost per example, so optimize for fewer, denser examples and high-level Capybara helpers.

The general `context`/`let` style and "what to test" rules are in the [`rspec-testing`](../rspec-testing/SKILL.md) skill — the rules below extend it for the system-spec case.

## Always follow the real user path

If a user does it in the UI, the spec does it in the UI — every step, including setup. `FactoryBot.create(:user, …)` to skip a complicated form turns the spec back into a model test and passes silently when the form is broken.

If the UI path is hard or flaky, that's a real signal — usually a production bug (stale asset cache, missing seed data, wrong API URL). Fix the root cause; don't `execute_script` or factory around it.

Legitimate exceptions: reference data that exists in production via seeds/migrations, admin accounts outside the user flow, and stubs for genuinely external services (third-party APIs, geocoders).

## One `it` per setup; many assertions per `it`

Unit specs prefer one assertion per example. **Integration specs prefer the opposite**: when several assertions share the same fixture and the same initial `visit`, fold them into one example that walks through state transitions (click → assert → click → assert).

Use `context` only when the *setup* differs — a different `let!`, a different page, a different feature flag. Don't split a single user flow across sibling `it` blocks just because each step has its own assertion.

**Combine same-setup work, even when scenarios feel independent.** Before writing a new `describe`/`context`/`it`, read the existing file and find an example whose fixtures and initial `visit` match what you need — then append your clicks/assertions to it. It's tempting to leave a separate `it` for things that feel like different concerns ("button-state test", "filter-persistence test", "URL-param test", "mobile-layout test"). Don't. A long, sectioned-with-comments example pays one Selenium boot; four short examples pay four. Failure attribution is fine — the failed line number tells you exactly which phase broke. Only add a new block when the setup genuinely differs.

### Good

```ruby
it "signs up and lands on the home page" do
  visit new_user_registration_path # no signup link on the home page nav — this is the real entry point

  fill_in "Email", with: "newuser@example.com"
  fill_in "Username", with: "testuser"
  fill_in "Password", with: "securepassword123"
  click_button "Sign up"

  expect(page).to have_current_path(root_path)
  expect(page).to have_link("testuser") # nav now shows the signed-in user

  user = User.find_by(email: "newuser@example.com")
  expect(user).to have_attributes(username: "testuser")
end
```

### Bad

```ruby
# Two browser sessions for what's effectively one user flow.
it "creates a user from the signup form" do
  visit new_user_registration_path
  fill_in "Email", with: "newuser@example.com"
  fill_in "Username", with: "testuser"
  fill_in "Password", with: "securepassword123"
  click_button "Sign up"
  expect(User.find_by(email: "newuser@example.com")).to be_present
end

it "redirects to the home page after signup" do
  visit new_user_registration_path
  # ... fill and submit again
  expect(page).to have_current_path(root_path)
end
```

## Carry state forward, don't reset between phases

You know what state the page is in after each click — write the next assertion against that state. Don't click a "Reset" / "Clear" between phases just to get a clean slate; resets cost a click (often two — clear, then re-establish), obscure what's actually happening, and tempt you to think of each phase as an isolated scenario rather than as one continuous user flow.

If a carried-over state makes the next assertion awkward, that's information: usually you can reorder or rephrase phases so the previous phase's end state is exactly what the next phase needs to start from. Treat the example as a flow with state advancing through it, not a sequence of independent scenarios each demanding a pristine baseline.

`visit page.current_url` is a reload, not a reset — use it specifically to verify URL persistence across a fresh page load. Otherwise, prefer letting state flow.

## Navigate by clicking, not re-visiting

After the initial `visit` in `before`, prefer **clicking** to get to the next state. Re-visiting bypasses the very thing system specs exist to verify (client-side state, JS handlers, history, ARIA wiring).

Re-visit only when you specifically want to verify **URL persistence / reload behavior** — and make that intent explicit (`visit page.current_url` with a comment, or a context named "after reload").

```ruby
# Good — drive the flow with clicks after the initial visit
visit new_user_registration_path
fill_in "Email", with: "newuser@example.com"
fill_in "Username", with: "testuser"
fill_in "Password", with: "securepassword123"
click_button "Sign up"
click_link "testuser" # go to your own ratings — don't re-visit the URL directly

# Good — explicit reload to verify URL persistence
visit page.current_url

# Bad — re-rendering that should have been a click
visit ratings_path(user: user.to_param)
```

## Prefer named matchers over CSS selectors and JS

Capybara's high-level helpers find elements by visible role + text. They are more readable, more accessible (they only see what a real user can interact with), and less brittle than scraping selectors. Reach for low-level tools only when the high-level ones can't express what you need.

Order of preference:

1. **Named-element helpers**: `click_button("Sign up")`, `click_link("Settings")`, `find_button(...)`, `have_button(...)`, `fill_in("Email", with: ...)`.
2. **Role-scoped Capybara finders**: `find(:button, "...")`, `within(:section, "Account") { ... }`.
3. **ARIA / data attributes** when there is no visible text: `find('[aria-label="..."]')`, `find('[data-test-id="..."]')`.
4. **CSS selectors** as a last resort.
5. **`page.execute_script`** only when the browser fundamentally cannot otherwise do what the test needs (synthesizing custom events, scrolling for IntersectionObserver, etc.).

If a button has no visible text (icon-only, etc.), add an `aria-label` to the component rather than scraping a selector in the test.

### Good

```ruby
click_button("Sign up")
expect(find_button("Save")["aria-pressed"]).to eq "true"
expect(page).to have_link("Settings")
```

### Bad

```ruby
find('[data-action="click->form#submit"]').click
expect(page).to have_css('button[aria-pressed="true"]')
page.execute_script("document.querySelector('.signup-btn').click()")
```

## Component system specs must assert accessibility

A component system spec (`spec/components/**/component_system_spec.rb`) exists to verify a component renders and behaves correctly in a real browser — and "correctly" includes being accessible. **Every component system spec must call `expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)` at least once**, after the component has rendered (and after any state change that swaps in new markup — an opened menu, an added row, a new field). The axe audit catches missing accessible names, bad ARIA, and broken label associations that no CSS-selector assertion would.

Treat an axe failure as a real bug in the component, not noise to silence: fix the markup (add the `aria-label`, associate the `<label>`, correct the `role`) rather than narrowing the audit — `SKIPPABLE_AXE_RULES` (defined in `spec/rails_helper.rb`) already skips the rules that don't apply to an isolated component preview, so a remaining violation is almost always genuine. Don't add new rules to that skip list to silence a real finding.

```ruby
visit "/lookbook/preview/ui/dropdown/variants"
expect(page).to have_css('[aria-expanded="false"]') # settles on the rendered, controller-connected component

click_button("Menu")

expect(page).to have_css('[aria-expanded="true"]')
expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES) # audit the open menu — new markup that wasn't there at load
```

## ActionCable broadcasts: not wired up here (yet)

`config/cable.yml`'s test adapter is `test` (Rails' `ActionCable::TestAdapter`), not `:async` — it only supports assertion helpers like `assert_broadcast_on`, it does **not** round-trip real messages to a live Capybara browser session. This project doesn't broadcast over the cable yet, either — no `broadcasts_to`/`broadcast_*` calls, no channels beyond the generated `app/channels/application_cable/`.

If you add real-time UI updates (a Turbo Stream broadcast that should update an open browser session in a system spec), switch the test adapter to `:async` first — otherwise the broadcast never reaches the page and no assertion will observe it. Once that's done, **don't synthesize `turbo:morph-element` events with `execute_script` to fake the refresh** — call the real broadcaster (`broadcast_replace_to`, `broadcast_refresh_later_to`, etc.) and let Capybara's `wait:` do the synchronization: prepare the data the broadcast will render → call the real broadcaster → assert on an unambiguous post-morph element with a `wait:` (e.g. `expect(page).to have_css(some_new_selector, wait: 5)`). The trailing wait is the synchronization barrier — the test proceeds only once the morph has actually rendered.

## Build Tailwind before running system specs

CI builds `app/assets/builds/tailwind.css` automatically; your local sandbox does not. Without it, Tailwind utility classes (most importantly `hidden` → `display: none`) silently don't apply, and assertions like `expect(tooltip).not_to be_visible` fail in confusing ways that look like flakes but aren't.

**Before running any `:js, type: :system` spec locally, run `bin/rails tailwindcss:build`** (or have `bin/dev` running, which watches and rebuilds). If a system spec is failing on visibility/styling assertions, check `app/assets/builds/tailwind.css` exists and is recent before assuming the test or component is broken.

See the [`frontend-conventions`](../frontend-conventions/SKILL.md) skill for the rest of the styling rules.

## Other conventions

- Always include `:js, type: :system`.
- Define a few small DSL-style helpers in the file (`def fill_signup_form(...)`, `def open_dropdown_menu`) when they make assertions readable. Don't reach for `page.execute_script` to replace what a helper method could do in Ruby.
