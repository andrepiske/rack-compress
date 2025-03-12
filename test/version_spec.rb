require 'minitest/autorun'
require 'rack/compress/version'

describe Rack::Compress::Version do
  it '#to_s' do
    _(Rack::Compress::Version.to_s).must_equal('0.1.3')
  end
end
