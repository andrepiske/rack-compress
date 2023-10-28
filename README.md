[![Gem Version](https://badge.fury.io/rb/rack-compress.svg)](https://badge.fury.io/rb/rack-compress) [![Build Status](https://github.com/andrepiske/rack-compress/actions/workflows/test.yml/badge.svg)](https://github.com/andrepiske/rack-compress/actions/workflows/test.yml)

# Rack::Compress


`Rack::Compress` compresses `Rack` responses using [Google's Brotli](https://github.com/google/brotli) and [Facebook's Zstandard](https://github.com/facebook/zstd) compression algorithms.

Those generally compresses better than `gzip` for the same CPU cost.
Brotli is supported by [Chrome, Firefox, IE and Opera](http://caniuse.com/#feat=brotli), while
Zstandard (aka. Zstd) began making its way into major browsers and as of today it's available on Chrome behind feature flags, see [the caniuse page](https://caniuse.com/zstd).

### Use

Install gem:

    gem install rack-compress

Requiring `'rack/compress'` will autoload `Rack::compress` module.
The following example shows what a simple rackup
(`config.ru`) file might look like:

```ruby
require 'rack'
require 'rack/compress'

use Rack::Compress

run theapp
```

Note that it is up to the browser or the HTTP client to choose the compression algorithm.
This occurs via the [accept-encoding](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding)
header. `Rack::Compress` always gives priority to `zstd` when the client supports it, since
it should perform better than Brotli
[according to benchmarking](https://github.com/andrepiske/compress-benchmark#conclusions).

It's possible to also customize the compression levels for each algorithm:

```ruby
use Rack::Compress, {
  levels: {
    brotli: 11, # must be between 0 and 11
    zstd: 19 # must be between 1 and 19
  }
}
```

In case you want to better control which MIME types get compressed:

```ruby
use Rack::Compress, { include: [
  'text/html',
  'text/css',
  'application/javascript',
] }
```

The above will compress all those MIME types and not any other.

### Testing

To run the entire test suite, run 

    rake test

### Acknowledgements

Thanks to [Marco Costa](https://github.com/marcotc) for the original gem form which this one
was forked from.

