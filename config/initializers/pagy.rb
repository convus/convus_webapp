# Pagy initializer (43.x)
# See https://ddnexus.github.io/pagy/docs/api/pagy

Pagy::OPTIONS[:limit] = 25
Pagy::OPTIONS[:limit_max] = 100
# To limit pages, cap collections with .limit(max_records) before passing to pagy.
# See https://ddnexus.github.io/pagy/guides/how-to/#paginate-only-max-records

# Raise RangeError for out-of-range pages so we can redirect to last valid page
Pagy::OPTIONS[:raise_range_error] = true

require "pagy/toolbox/helpers/support/series"
