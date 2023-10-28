require_relative 'compress/deflater'
require_relative 'compress/version'

module Rack
  module Compress
    def self.release
      Version.to_s
    end

    def self.new(app, options={})
      Rack::Compress::Deflater.new(app, options)
    end
  end
end
