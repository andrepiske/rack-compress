require_relative 'lib/rack/compress/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name    = 'rack-compress'
  s.version = Rack::Compress::Version.to_s
  s.date    = Time.now.strftime("%F")

  s.licenses = ['MIT']

  s.description = "Rack::Compress enables Zstd and Brotli compression on HTTP responses"
  s.summary     = "Compression for Rack responses"

  s.authors = ["André Diego Piske", "Marco Costa"]
  s.email = "andrepiske@gmail.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README.md
  ] + `git ls-files -z lib`.split("\0")

  s.test_files = s.files.select {|path| path =~ /^test\/.*\_spec.rb/}

  s.extra_rdoc_files = %w[README.md COPYING]

  s.add_dependency 'rack', '< 3', '>= 1.4'

  s.add_dependency 'brotli', '>= 0.1.7'
  s.add_dependency 'zstd-ruby', '>= 1.5'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest', '~> 5.6'
  s.add_development_dependency 'rake', '~> 12', '>= 12.3.3'
  s.add_development_dependency 'rdoc', '~> 3.12'

  s.homepage = "http://github.com/andrepiske/rack-compress/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-brotli", "--main", "README"]
  s.require_paths = %w[lib]
end
