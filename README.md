# Shill

A tiny, dependency-free Ruby gem that fetches and exposes a list of projects from a remote JSON endpoint.

* Fetch once, cache in memory.
* Pick a random project with one call.
* Zero external dependencies (uses Net::HTTP & JSON from Ruby stdlib).
* Rails-friendly configuration via `Shill.configure`.

---

## Installation

Add the gem to your project:

```ruby
gem "shill"
```

Then install:

```bash
bundle install
```

## Configuration

### Rails

Create `config/initializers/shill.rb`:

```ruby
Shill.configure do |config|
  config.endpoint_url = "https://marc.io/shill.json"
end
```

### Plain Ruby

```ruby
require "shill"

Shill.endpoint_url = "https://marc.io/shill.json"
```

---

## JSON format

The endpoint must return an **array of objects** with these keys:

* **url** – required
* **description** – required
* **name** – required
* **logo_url** – optional

Example:

```json
[
  {
    "name": "BetaList",
    "url": "https://betalist.com",
    "description": "Startup discovery platform"
  },
  {
    "name": "Room AI",
    "url": "https://roomai.com",
    "description": "Generate interior design with AI",
    "logo_url": "https://roomai.com/logo.png"
  }
]
```

---

## Usage

```ruby
# All projects (memoised)
projects = Shill.projects

# A single random project (memoised list reused)
featured = Shill.random_project

puts featured.name        # => "Room AI"
puts featured.url         # => "https://roomai.com"
```

Need fresh data? Pass `refresh: true`:

```ruby
Shill.projects(refresh: true)
```

---

## Error handling

Every exception is wrapped in `Shill::Error` with a helpful message, e.g.:

* endpoint not configured
* invalid JSON
* missing required keys

---

## Development

```bash
git clone https://github.com/marckohlbrugge/shill.git
cd shill
bundle install
bundle exec rake test    # runs the Minitest suite
```

### Releasing a new version

1. Bump the version in `lib/shill/version.rb` following [Semantic Versioning](https://semver.org/) (e.g. `0.1.1` → `0.1.2`).
2. Update `CHANGELOG.md` (optional but recommended).
3. Commit the changes:

    ```bash
    git commit -am "Bump version to x.y.z"
    ```

4. Run the Bundler release task (builds, pushes the gem, and tags the commit):

    ```bash
    bundle exec rake release      # same as `rake release`
    ```

    Behind the scenes this will:

    * Run `rake build` → creates `pkg/shill-x.y.z.gem`.
    * Run `gem push` to upload the new gem to RubyGems.org using your saved API key.
    * Create a Git tag `vX.Y.Z` and push it to the origin.

5. Done! The new version will be live on RubyGems within a minute or so.

If you prefer to do things manually you can replicate the steps yourself:

```bash
rake build                       # => pkg/shill-x.y.z.gem
gem push pkg/shill-x.y.z.gem     # upload
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push && git push --tags
```

---

## Contributing

Pull requests are very welcome. Please include tests for any change.

---

## License

Shill is released under the MIT License. See `LICENSE.txt` for details.

---

## Caching

By default Shill caches the fetched payload in memory. If you're running inside a Rails application (with `Rails.cache` configured), it will automatically use that instead. You can also set your own cache store:

```ruby
Shill.configure do |c|
  c.cache_store = MyCustomCache.new   # must respond to fetch(key) { ... } and delete(key)
end
```

Force a reload at any time:

```ruby
Shill.projects(refresh: true)   # bypasses cache and stores fresh data
```

---
