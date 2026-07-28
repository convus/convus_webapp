---
name: sandbox-test-setup
description: >-
  Ruby + RSpec environment setup for convus_webapp. Two environments:
  **(A) local macOS Conductor workspace** (`/Users/…/conductor/workspaces/…`) —
  Ruby 4.0.6 is installed via mise but Claude Code's shell sometimes
  spawns subprocesses without the mise shim, so bare `ruby`/`bundle`
  falls back to system 2.6 and fails. Fix is a PATH prefix, not a
  reinstall. **(B) Claude Code's Linux web sandbox** —
  Ruby 4.0.6 must be built from source (~8–10 min, `cache.ruby-lang.org`
  firewalled); also postgres/redis, tailwind build, Chrome-matching
  ChromeDriver, and a local jsdelivr proxy for `:js, type: :system`
  specs. Trigger whenever a session runs RSpec/bundle/`bin/lint`, or
  the user reports `Bundler::RubyVersionMismatch` /
  `command not found: rspec` / `tailwind.css is not present` /
  chromedriver version-mismatch.
---

# Running Ruby + RSpec

**The Ruby patch version (`4.0.6`) is hardcoded throughout this skill** — in
PATH prefixes, `/opt/ruby-*` build paths, and the source-tarball URL. It
mirrors `.tool-versions` / `Gemfile`; when those bump, re-grep this file and
update every occurrence, or the build recipe will silently target the wrong
version.

Pick the section matching the environment: macOS paths under
`/Users/…/conductor/workspaces/…` use **Local macOS**; Linux paths
under `/home/user/…` use **Claude Code web sandbox**.

## Local macOS (Conductor workspace)

Ruby 4.0.6 is installed via [mise](https://mise.jdx.dev/), but Claude
Code's shell sometimes spawns subprocesses without the mise shim on
PATH — bare `ruby` then resolves to `/usr/bin/ruby` (2.6) and `bundle`
fails. **The Ruby is installed; the PATH just isn't right** — don't
reinstall, don't edit the Gemfile.

Check first; only prefix PATH if `ruby -v` doesn't already print 4.0.6
(`mise exec -- ruby`/`bundle` are unreliable in this harness — they
can still resolve to system 2.6, so use the direct prefix):

```bash
ruby -v
# If it's not 4.0.6:
export PATH="/Users/seth/.local/share/mise/installs/ruby/4.0.6/bin:$PATH"
```

Then run specs the normal way:

```bash
bundle exec rspec spec/path/to/file_spec.rb
```

(No need to `eval "$(ruby bin/env --export)"` first — `config/boot.rb` loads
`bin/env` for every Ruby entry point, so `DEV_PORT` / `BASE_URL` are
already set inside the process. Only export them into the shell when
the shell itself reads them, e.g. `curl "$BASE_URL/..."`.)

If `rails_helper` aborts complaining about a pending migration, run
`bundle exec rails db:create db:migrate` first
(`ActiveRecord::Migration.maintain_test_schema!`).

Lint with `bin/lint` (same PATH prefix if needed). Postgres, redis,
and CDN access are handled by your local dev environment —
skip the rest of this skill **except** Tailwind build below, which
can still bite a fresh Conductor workspace where `bin/dev` hasn't
run.

## Claude Code web sandbox

The Gemfile pins `ruby "4.0.6"`. No prebuilt 4.0.6 binary is reachable
(`cache.ruby-lang.org` is 403'd, `ruby/ruby-builder`'s toolcache tops
out at `3.5.0-preview1`), so build from the GitHub source tag — about
8–10 min on a 4-core sandbox. Don't fall back to 3.x and patch the
Gemfile; Bundler 4.x's resolver behaves differently and you'll waste
time chasing fake regressions. Once `/opt/ruby-4.0.6/x64/` exists,
`bundle install` works as-is.

## One-shot Ruby 4.0.6 build

Skip if `/opt/ruby-4.0.6/x64/bin/ruby --version` already prints 4.0.6.
Two quirks the bash block handles: (1) GitHub source tarballs lack a
pre-generated `configure`, so `autogen.sh` runs first; (2) `make install`
fetches ~30 bundled gems via `BASERUBY`, whose hardcoded CA bundle
doesn't include the sandbox egress-proxy CA — so we pre-stage every
bundled gem with `curl` (which honours
`/etc/ssl/certs/ca-certificates.crt`) before `make install`.

```bash
# 1. Source — GitHub tag tarball (cache.ruby-lang.org is blocked)
mkdir -p /tmp/ruby-build-src && cd /tmp/ruby-build-src
curl -sfL "https://github.com/ruby/ruby/archive/refs/tags/v4.0.6.tar.gz" \
  | tar -xz
cd ruby-4.0.6

# 2. Generate ./configure (GitHub source tarballs don't ship it)
./autogen.sh

# 3. Pre-stage every bundled gem (avoids the rubygems-cert MITM issue)
while read name ver _; do
  case "$name" in ''|'#'*) continue ;; esac
  out="gems/${name}-${ver}.gem"
  [ -s "$out" ] || curl -sfL --max-time 60 -o "$out" \
    "https://rubygems.org/downloads/${name}-${ver}.gem"
done < gems/bundled_gems

# 4. Configure + build + install (BASERUBY = preinstalled /opt/ruby-3.3.6)
mkdir -p /tmp/ruby-build-src/build && cd /tmp/ruby-build-src/build
/tmp/ruby-build-src/ruby-4.0.6/configure \
  --prefix=/opt/ruby-4.0.6/x64 \
  --enable-shared \
  --disable-install-doc \
  --with-openssl-dir=/usr
make -j"$(nproc)"
SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt make install

# 5. Match the GitHub-Actions hostedtoolcache layout some shebangs assume
mkdir -p /opt/hostedtoolcache/Ruby/4.0.6
[ -e /opt/hostedtoolcache/Ruby/4.0.6/x64 ] || \
  ln -s /opt/ruby-4.0.6/x64 /opt/hostedtoolcache/Ruby/4.0.6/x64

cd "$REPO_DIR"  # wherever convus_webapp is checked out, e.g. /home/user/convus_webapp
/opt/ruby-4.0.6/x64/bin/ruby --version   # => ruby 4.0.6 ... [x86_64-linux]
```

## Toolchain on PATH

The Playwright Chromium directory has a build number that changes
between sandbox images, so glob it instead of hardcoding. `service`
lives only on `/usr/sbin`.

```bash
CHROME_DIR=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux | sort -V | tail -1)
export PATH="/opt/ruby-4.0.6/x64/bin:$CHROME_DIR:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
export LD_LIBRARY_PATH="/opt/ruby-4.0.6/x64/lib:$LD_LIBRARY_PATH"
bundle install
```

## Services + DB

Start postgres and redis once per session (redis logs a benign ulimit
warning). Set the `postgres` superuser's password + create the test DB
once per machine. `CI=1` makes `database.yml` use the postgres/password
creds at 127.0.0.1. This app is single-database (no analytics DB).

```bash
service postgresql start
service redis-server start

# Once per machine:
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"
sudo -u postgres psql -c "CREATE DATABASE convus_reviews_test OWNER postgres;"

eval "$(ruby bin/env --export)"
export RAILS_ENV=test CI=1
bundle exec rails db:migrate db:test:prepare
```

## Tailwind build (both environments)

The application layout calls `stylesheet_link_tag 'tailwind'`. Without
`app/assets/builds/tailwind.css`, specs that render the layout (request
specs hitting `format: :html`, or any `:js, type: :system` spec) fail
with `Sprockets::Rails::Helper::AssetNotFound`. This applies to both
the sandbox AND a fresh Conductor workspace where `bin/dev` /
`tailwindcss:build` haven't run yet. **Don't write the failure off as
"pre-existing" — build Tailwind:**

```bash
bundle exec rails tailwindcss:build
```

(See the `integration-testing` skill — same rule applies to
layout-rendering request specs, not just system specs.)

## Running plain specs

After Toolchain + Services + DB above:

```bash
bundle exec rspec spec/models spec/requests spec/jobs
```

## Running `:js, type: :system` specs (component system)

Two extra hurdles in the sandbox:

### 1. Chrome + matching ChromeDriver

- Chrome binary lives at `/opt/pw-browsers/chromium-*/chrome-linux/chrome`
  — the `chromium-NNNN` directory has a Playwright build number that
  changes between sandbox images, so glob it.
- `/opt/node22/bin/chromedriver` is too new (it tracks current stable;
  Chrome here is whatever Playwright bundled). Pull the matching driver
  from Google's CfT bucket — `storage.googleapis.com` is allowed:
  ```bash
  CHROME_DIR=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux | sort -V | tail -1)
  CHROME_VER=$("$CHROME_DIR/chrome" --version | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
  curl -sfL "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VER}/linux64/chromedriver-linux64.zip" \
    -o /tmp/chromedriver.zip
  unzip -o -q /tmp/chromedriver.zip -d /tmp
  cp /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
  ```
- Capybara's default `:selenium_chrome_headless` doesn't pass
  `--no-sandbox` or a unique `--user-data-dir`, both required when
  Chrome runs as root in a container, and it doesn't route
  `cdn.jsdelivr.net` to the local proxy above. convus_webapp has no
  `spec/support/local_chrome.rb` for this — create one, gated on
  `LOCAL_CHROME_OVERRIDE=1` so CI and developer machines are
  unaffected (everything under `spec/support/**/*.rb` is
  auto-required by `spec/rails_helper.rb`, so this only needs doing
  once per checkout):
  ```bash
  cat > spec/support/local_chrome.rb <<'RUBY'
  if ENV["LOCAL_CHROME_OVERRIDE"]
    Capybara.register_driver :selenium_chrome_headless do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-site-isolation-trials")
      options.add_argument("--ignore-certificate-errors")
      options.add_argument("--host-resolver-rules=MAP cdn.jsdelivr.net 127.0.0.1:8443")
      options.add_argument("--user-data-dir=/tmp/chrome-test-#{Process.pid}-#{rand(10_000)}")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
  end
  RUBY
  ```
  Then just set `LOCAL_CHROME_OVERRIDE=1` when running system specs.

### 2. `cdn.jsdelivr.net` is firewalled

`config/importmap.rb` pins three modules from `cdn.jsdelivr.net` (403'd)
— `@bikeindex/time-localizer`, `@floating-ui/dom`, and `sortablejs`.
Without them, pages render empty. Fetch from `registry.npmjs.org`
(allowed) and serve locally over TLS at the same path layout. Versions
below mirror `config/importmap.rb`; bump when that changes.

```bash
mkdir -p /tmp/cdn/bikeindex-time-localizer \
         /tmp/cdn/floating-ui-dom /tmp/cdn/sortablejs
curl -sL "https://registry.npmjs.org/@bikeindex/time-localizer/-/time-localizer-0.2.0.tgz" \
  | tar -xz -C /tmp/cdn/bikeindex-time-localizer --strip-components=1
curl -sL "https://registry.npmjs.org/@floating-ui/dom/-/dom-1.7.3.tgz" \
  | tar -xz -C /tmp/cdn/floating-ui-dom --strip-components=1
curl -sL "https://registry.npmjs.org/sortablejs/-/sortablejs-1.15.6.tgz" \
  | tar -xz -C /tmp/cdn/sortablejs --strip-components=1

# Reproduce the jsdelivr URL layout
mkdir -p '/tmp/cdn/serve/npm/@bikeindex' \
         '/tmp/cdn/serve/npm/@floating-ui/dom@1.7.3' \
         '/tmp/cdn/serve/npm/sortablejs@1.15.6/modular'
ln -sf /tmp/cdn/bikeindex-time-localizer \
       '/tmp/cdn/serve/npm/@bikeindex/time-localizer@0.2.0'
cp /tmp/cdn/floating-ui-dom/dist/floating-ui.dom.mjs \
   '/tmp/cdn/serve/npm/@floating-ui/dom@1.7.3/+esm'
cp /tmp/cdn/sortablejs/modular/sortable.esm.js \
   '/tmp/cdn/serve/npm/sortablejs@1.15.6/modular/sortable.esm.js'

# Self-signed cert for *.jsdelivr.net
openssl req -x509 -newkey rsa:2048 -keyout /tmp/cdn/key.pem \
  -out /tmp/cdn/cert.pem -sha256 -days 365 -nodes \
  -subj "/CN=cdn.jsdelivr.net" \
  -addext "subjectAltName=DNS:cdn.jsdelivr.net" 2>/dev/null

# TLS server on :8443 (script lives next to this skill)
python3 .claude/skills/sandbox-test-setup/assets/cdn_server.py &
disown
```

The `--host-resolver-rules` argument (in the override above) routes
`cdn.jsdelivr.net` → this local server, and `--ignore-certificate-errors`
trusts the self-signed cert.

## End-to-end recap

Assumes Ruby 4.0.6 is already built. Combines the steps above — but note the
last line has three prerequisites this block does *not* perform: a
Chrome-matching chromedriver on PATH, `spec/support/local_chrome.rb` created,
and `cdn_server.py` running. Do those sections first or that line fails.

```bash
CHROME_DIR=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux | sort -V | tail -1)
export PATH="/opt/ruby-4.0.6/x64/bin:$CHROME_DIR:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
export LD_LIBRARY_PATH="/opt/ruby-4.0.6/x64/lib:$LD_LIBRARY_PATH"
service postgresql start && service redis-server start
cd "$REPO_DIR"
bundle install
eval "$(ruby bin/env --export)"
export RAILS_ENV=test CI=1
bundle exec rails db:migrate db:test:prepare
bundle exec rails tailwindcss:build           # only if specs render the layout

bundle exec rspec spec/models spec/requests   # plain
LOCAL_CHROME_OVERRIDE=1 bundle exec rspec spec/components --tag type:system   # system; CDN proxy must be running
```

## Sandbox network: what's allowed vs. blocked

Quick probe: `curl -sIL --max-time 5 "https://<host>" -o /dev/null -w "%{http_code}\n"`.

- **Allowed**: github.com, codeload.github.com, rubygems.org,
  registry.npmjs.org, storage.googleapis.com, files.pythonhosted.org.
- **Blocked**: cache.ruby-lang.org, cdn.jsdelivr.net, most generic CDNs,
  download.ruby-lang.org, api.github.com.

If a tool's default download URL is blocked, look for a GitHub or
npm-registry alternative before giving up.
