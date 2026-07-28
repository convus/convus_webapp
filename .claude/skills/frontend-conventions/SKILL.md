---
name: frontend-conventions
description: >-
  Frontend conventions for this project — the `Form::Group`/`Form::Input`
  components for form fields, the `twlink` class for basic links, the
  `number_display` helper for numbers, the `UI::Time::Component` for times,
  the UI component library rule (buttons are `UI::Button`/`UI::ButtonLink`
  — check `app/components/ui/` and `app/components/form/` before
  hand-rolling markup), the shared collapse helpers for showing/hiding
  elements, and ViewComponent rules (keyword arguments, instance
  variables, `helpers.` prefix in templates). Trigger when adding or modifying views
  (`.html.erb`), view components, Stimulus controllers, Tailwind classes,
  or any frontend code that touches styling or interactivity. **Also
  trigger before any `mcp__playwright__browser_take_screenshot` call** —
  this skill defines the required `tmp/` filename rule so screenshots
  don't land in the project root. Stimulus.js is the JavaScript framework.
---

# Frontend conventions

This project uses **Stimulus.js** for JavaScript interactivity and **Tailwind CSS** for styling.

The `bin/dev` command runs `bin/rails tailwindcss:watch` (see `Procfile.dev`) to build and update Tailwind CSS. JS is served directly via importmap (`config/importmap.rb`, `app/javascript/`) — there's no separate JS build step.

**Format ERB before committing.** After editing any `.html.erb`, run `bin/lint <file>` — it runs `herb-format`, which reflows long `class` attributes and normalizes ERB. CI does *not* run the herb steps (`.github/workflows/ci.yml` only calls `standardrb`, `rubocop`, and `bin/brakeman`), so unformatted ERB won't fail the build — run `bin/lint` anyway to keep formatting consistent. It needs `yarn install` to have run, since the herb tools come from `devDependencies`.

## Standard classes and helpers

- Form fields should be rendered through `Form::Group::Component` (label + input, `app/components/form/group`) or `Form::Input::Component` directly (`app/components/form/input`) — not hand-rolled `<input>`/`<label>` tags with ad-hoc classes. `Form::Group::Component` applies the shared label classes and delegates the field to `Form::Input::Component`, which centralizes the input's Tailwind classes.
- Basic links should use the `twlink` class.
- **Every number** should be rendered with `number_display(number)` (defined in `app/helpers/application_component_helper.rb`). This applies even when a number is composed into a string with non-numeric values — wrap the number itself, not the surrounding string.
  - Good: `[number_display(user.year_joined), user.name].join(" ")`
  - Bad: `[user.year_joined, user.name].join(" ")`
  - "Number" includes years, counts, prices, distances, IDs — anything numeric, even when it reads like a label.
- **Times** should be rendered with `UI::Time::Component` rather than `time_ago_in_words` or raw `strftime`.
- **Horizontally-scrolling containers (`overflow-x-auto`/`overflow-x-scroll`) must bleed to their parent's edges**, with the parent's own horizontal padding reapplied on the scrollable element itself: cancel the parent's `px-N` with `-mx-N` on the scroller, then add that same `px-N` back on the scroller. This keeps the at-rest look identical (content still starts inset) but lets the scroll track — and touch/scroll gestures — reach the container's true edges instead of stopping short inside a padded dead zone. See `UI::Table::Component`'s wrapper (`-mx-4 … px-4`) for the pattern in practice.
  - Good: parent has `p-4`; scroller has `class="-mx-4 flex gap-4 overflow-x-auto px-4"`.
  - Bad: scroller sits inside the parent's padding with no margin adjustment — it never reaches the edge, so gestures starting at the edge miss it and there's no partial-next-item peek.

## Use the UI component library

**Check `app/components/ui/` (and `app/components/form/`) before hand-rolling any UI primitive.** If a `UI::*`/`Form::*` component exists for the pattern — buttons, dropdowns, badges, modals, pagination, tables, alerts — use it; if it almost fits, extend it rather than forking its markup inline. A hand-styled one-off silently drifts from the shared colors/sizes/dark-mode states the next time the design changes.

- **Every button** goes through `UI::Button::Component` — never a bare `<button>` or submit input with ad-hoc Tailwind classes. It centralizes the colors (`:primary`/`:secondary`/`:error`/`:link`), sizes (`:sm`/`:md`/`:lg`), and the focus/active/dark-mode states.
- A link styled as a button is `UI::ButtonLink::Component.new(href:, text:, color:, size:)` — same palette, renders an `<a>` via `link_to`.

## Showing and hiding elements: use the collapse helpers

Any time you show, hide, or toggle an element in response to interaction, go through the shared collapse helpers. **Never** hand-roll it with the `hidden` attribute, `element.style.display`, `element.hidden = true`, or ad-hoc `classList.add('hidden')` — those skip the shared show/hide animation and the `hidden!`/`hidden` class contract the rest of the app depends on.

- **Markup-only toggle** (a trigger reveals/collapses a panel, no other logic): add `data-controller="collapse"`, mark the collapsible element `data-collapse-target="content"`, and wire the trigger's `data-action` to `collapse#toggle` / `collapse#show` / `collapse#hide` (`app/javascript/controllers/collapse_controller.js`; optional `data-collapse-duration-value`).
- **Inside your own Stimulus controller** (you have extra logic — a redirect branch, a query-param check, etc.): import the collapse util and call it directly:

  ```js
  import { collapse } from 'utils/collapse_utils'
  // ...
  collapse('show', this.formTarget)   // 'show' | 'hide' | 'toggle'; optional duration (default 200)
  ```

The collapsible element starts hidden with the **`hidden` class** (not the `hidden` attribute) — `collapse` toggles `hidden`/`hidden!` and runs the height transition for you. Because the initial hidden state is a class, component specs assert it by class (`have_css("[…].hidden")`), not Capybara visibility — the rack_test driver doesn't evaluate CSS, so it can't tell a class-hidden element is hidden.

## No dead hooks in markup

Only add an `id` or non-utility `class` when something concrete consumes it — a CSS rule, a JS/Stimulus selector, a test fixture, an accessibility attribute. Don't keep or invent "structural identifier" hooks "in case something needs them later," and don't replace a removed hook with a renamed one out of inertia.

When deleting an `id`/`class`, grep the repo for the name before deciding what to do with it:

- Zero consumers: delete it, don't rename it.
- Consumers exist: either update them, or leave the hook in place — the consumers are the *reason* it earns its spot in the markup.

## ViewComponent rules

This project uses the ViewComponent gem to render components.

- **Prefer view components to partials.**
- Generate a new view component with `rails generate component ComponentName argument1 argument2`.
- View components must initialize with **keyword arguments**. Everything the component needs must be passed in explicitly by the caller — never reach into controller state from inside a component (e.g. `controller.instance_variable_get(:@user)`). If the component needs `@user`, the caller renders `Component.new(user: @user)`.
- In view components, **use instance variables directly** — don't add `attr_reader`/`attr_accessor`. Reference `@foo` everywhere, including in the template.
- In ViewComponent templates, use the `helpers.` prefix for view helpers (e.g. `helpers.time_ago_in_words`).
  - Rule of thumb: try the bare call first. Only add `helpers.` if it fails with `NoMethodError` — route helpers (`user_path`, `new_user_session_path`) and ActionView tag/url builders (`tag.span`, `content_tag`, `link_to`, `button_to`, `url_for`) are mixed into `ViewComponent::Base` directly, so they don't need it.
- **Never nest a component inside a folder that already holds a `component.rb`.** Each component lives in `app/components/<path>/component.rb` (and `spec/components/<path>/component_spec.rb`); siblings go in sibling folders, not subfolders. If you have `ui/dropdown/component.rb` and need a related component, place it at `ui/dropdown_item/component.rb` (module `UI::DropdownItem`), not `ui/dropdown/item/component.rb`.
- **Converting a partial to a component is a faithful move, not a cleanup.** Carry the markup over verbatim — including comments and commented-out code, which are often a deliberate stash someone expects to restore. The only changes a conversion should introduce are the mechanical ones the move *requires* (e.g. adding `helpers.` where a helper now needs it). If you spot genuine dead code worth removing, that's a separate judgment call — raise it or do it in its own commit, don't fold it into the move.

## Manual browser verification

**Every `mcp__playwright__browser_take_screenshot` call must pass a `filename:` that starts with `tmp/`** (e.g. `tmp/tooltip-hover.png`). The MCP tool's default root is the project root — a bare filename like `tooltip.png` lands in the working tree, shows up in `git status`, and has to be cleaned up by hand. `tmp/` is gitignored, so screenshots there stay out of commits and don't pollute the diff. This rule applies to ad-hoc visual verification, not just PR-screenshot capture.
