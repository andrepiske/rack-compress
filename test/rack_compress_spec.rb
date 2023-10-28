require 'minitest/autorun'
require 'rack/compress'

describe Rack::Compress do
  it '#release' do
    _(Rack::Compress.release).must_equal(Rack::Compress::Version.to_s)
  end
end
