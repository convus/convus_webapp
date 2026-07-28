---
name: rspec-testing
description: >-
  RSpec testing conventions for this project — how to structure specs with
  `context` and `let`, what kinds of tests to write, and what to avoid
  (mocks, controller specs, testing private methods). Trigger when writing
  or modifying any `*_spec.rb` file, adding test coverage for new code,
  refactoring tests, or designing the test layout for a new feature.
  Includes Good/Bad examples of the project's preferred style.
---

# RSpec testing

This project uses RSpec. All business logic should be tested.

## What to test (and what not to)

- Tests should either: help make the code correct now, or prevent bugs in the future. Don't add tests that don't do one of those things.
- Use **request specs**, not controller specs — request specs go through the full middleware/routing stack, so they catch breakage controller specs can't see. Everything making the same request should be in a single test.
- Avoid testing private methods.
- Avoid mocking objects.
  - If making external requests, use VCR. Never hand-write or hand-edit cassettes (not even a single value or a stale `Content-Length`) — when a cassette is missing or its upstream data changed, delete it and re-record by running the tests.
  - Cassettes that get modified when you run specs locally are re-recordings, not unrelated churn — they're supposed to update. Commit them with your branch; don't revert them to "keep the PR focused".
- Don't use `tap` to bundle factory creation with follow-up setup. Create the record in `let`/`let!`, then do the follow-up work on its own line (a separate statement, or a `before` block) — one thing per line reads better and keeps the factory call clean.

### Good

```ruby
let!(:user) { FactoryBot.create(:user) }
before { user.update!(account_private: true) }
```

### Bad

```ruby
let!(:user) do
  FactoryBot.create(:user).tap do |user|
    user.update!(account_private: true)
  end
end
```

## Stubbing ENV

Never partial-mock `ENV` with `allow(ENV).to receive(:[]).and_call_original` — it makes every subsequent `ENV[...]` lookup go through RSpec's message router, which is slow and easy to break by forgetting a `.with(...)` branch.

Use `stub_const` against a merged hash instead:

### Good

```ruby
stub_const("ENV", ENV.to_hash.merge("STRIPE_SECRET_KEY" => "sk_test_123"))
```

### Bad

```ruby
allow(ENV).to receive(:[]).and_call_original
allow(ENV).to receive(:[]).with("STRIPE_SECRET_KEY").and_return("sk_test_123")
```

## Drain Sidekiq jobs, don't run them inline

Run enqueued jobs by draining them in the default fake mode — `SomeJob.drain` for one job, `Sidekiq::Worker.drain_all` for everything (clear first with `Sidekiq::Worker.clear_all` when earlier setup left jobs queued — see `spec/rails_helper.rb`'s global `config.before { Sidekiq::Worker.clear_all }`). Don't wrap the exercise in `Sidekiq::Testing.inline!`. Draining lets the request finish and commit before the jobs run, against that committed state — the way production does it — and keeps the test from silently pulling in every cascading job.

## Always fix failing tests

Fix every failing test, even ones that were already failing on `main`. Confirming a failure pre-dates your branch (via `git stash` or checking out `main`) explains *what* broke — not whether you fix it. You fix it.

## Don't weaken assertions to make a failing test pass

When a test goes red, the correct move is **investigate why**, not edit the assertion to match the new output. Watch for these tempting "fixes" that are actually erasing signal:

- Changing an expected value to whatever the page/chart/response now happens to render (e.g. `0` → `null`, an exact count → a range, a specific string → a substring/regex).
- Loosening `eq` to `include`, dropping `count:` constraints, or replacing `expect(...).to ...` with `expect(...).not_to be_nil`.
- Deleting the assertion entirely with a "looks unrelated" handwave.

The right loop: reproduce the failure, figure out *what* changed and *why*, then decide intentionally — fix the code if the original assertion captured the right behavior, or update the assertion (with a comment) if the behavior intentionally changed. If you're about to change a test "to make it easier", stop and explain why the new expectation is correct, not just convenient.

## Match a target attributes hash, not one attribute at a time

When you're checking several fields on the same object or response, build one expected-attributes hash and assert against it in a single matcher. Don't write a chain of one-attribute-per-line `expect`s.

- Object (ActiveRecord, plain Ruby): `expect(record).to have_attributes(target_attributes)`
- Hash (JSON response, parsed body): `expect(hash).to eq(target.as_json)` for full match, or `expect(hash).to include(target_attributes)` for partial.

This collapses what would be 4 brittle assertions into 1, makes the *contract* visible at a glance, and gives a single readable diff when something changes. It also avoids the trap of weak per-field assertions like `expect(x).to be_present` or `expect(url).not_to include("blank.png")` standing in for "the right value" — match the value directly.

### Good

```ruby
target_attributes = {username: "testuser", email: "test@example.com"}
expect(user).to have_attributes(target_attributes)

expect(json_result["citations"]).to eq([target_citation.as_json])
```

### Bad

```ruby
expect(user.username).to eq("testuser")
expect(user.email).to be_present
expect(user.email).to eq("test@example.com")

display_name = json_result["citations"].first["display_name"]
expect(display_name).to be_present
expect(display_name).not_to eq(target_citation.pretty_url)
expect(display_name).to eq(target_citation.display_name)
```

The bad version spreads one logical assertion across many lines, mixes weak presence checks with the real expected value, and produces noisier failure output.

## Structuring with `context` and `let`

Use `context` and `let` to isolate what varies between examples. Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. **Avoid repeating setup across sibling `it` blocks.**

### Good

```ruby
describe "display_name" do
  let(:citation) { Citation.new(url: "https://example.com/article", title:) }
  let(:title) { nil }

  it "returns the pretty_url when title is blank" do
    expect(citation.display_name).to eq citation.pretty_url
  end

  context "when title is present" do
    let(:title) { "Example Article" }

    it "returns title" do
      expect(citation.display_name).to eq "Example Article"
    end
  end
end
```

### Bad

```ruby
it "returns display_name" do
  citation = FactoryBot.create(:citation, title: "Example Article")
  expect(citation.display_name).to eq "Example Article"
end
it "returns pretty_url when title is blank" do
  citation = FactoryBot.create(:citation)
  allow(citation).to receive(:title) { nil }
  expect(citation.display_name).to eq citation.pretty_url
end
```

The bad version repeats setup, mocks the object, and doesn't communicate what each case represents.

## One example per distinct setup — combine same-setup `it` blocks

`context`/`let`/`before` isolate what *varies*. The corollary runs the other way: if two sibling `it` blocks share the **same** setup — no differing `context`, `before`, or `let` override between them — collapse them into **one** example. Each distinct setup earns exactly one `it`; put all of that setup's assertions (and all of its requests/renders) in that single block.

This is the same instinct as "everything making the same request should be in a single test", generalized: splitting same-setup assertions across sibling `it` blocks re-runs identical setup (factories, HTTP requests, renders) once per block for zero isolation benefit, and scatters one logical behavior across the file. Two `it` blocks that differ *only* in the request params or the assertion — with identical `let`s and no `before` between them — are one example.

After writing a spec, scan each `context`/`describe`: if it holds multiple `it` blocks and they don't each sit behind a distinct `context`/`before`/`let`, merge them.

### Good

```ruby
context "signed-in user" do
  let(:current_user) { FactoryBot.create(:user) }
  before { sign_in current_user }

  it "shows the edit form and updates the username" do
    get edit_u_path(current_user.to_param)
    expect(response.body).to match("Edit account")

    patch u_path(current_user.to_param), params: {user: {username: "new-username"}}
    expect(current_user.reload.username).to eq "new-username"
  end
end
```

### Bad

```ruby
context "signed-in user" do
  let(:current_user) { FactoryBot.create(:user) }   # re-created for every it below
  before { sign_in current_user }

  it "shows the edit form" do
    get edit_u_path(current_user.to_param)
    expect(response.body).to match("Edit account")
  end
  it "updates the username" do
    patch u_path(current_user.to_param), params: {user: {username: "new-username"}}
    expect(current_user.reload.username).to eq "new-username"
  end
end
```

This only merges blocks whose setup is identical. Different setup still means separate examples, each in its own `context` with the `let`/`before` that differs — that's the section above, not a contradiction of it.
