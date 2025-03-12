# frozen_string_literal: true

require 'rack/utils'
require 'zstd-ruby'
require 'brotli'

module Rack::Compress
  # This middleware enables compression of http responses.
  #
  # Currently supported compression algorithms:
  #
  #   * br # gem 'brotli'
  #   * zstd # gem 'extlz4'
  #
  # The middleware automatically detects when compression is supported
  # and allowed. For example no transformation is made when a cache
  # directive of 'no-transform' is present, or when the response status
  # code is one that doesn't allow an entity body.
  class Deflater
    ##
    # Creates Rack::Compress middleware.
    #
    # [app] rack app instance
    # [options] hash of deflater options, i.e.
    #           'if' - a lambda enabling / disabling deflation based on returned boolean value
    #                  e.g use Rack::Brotli, :if => lambda { |env, status, headers, body| body.map(&:bytesize).reduce(0, :+) > 512 }
    #           'include' - a list of content types that should be compressed
    #           'levels' - Compression levels
    def initialize(app, options = {})
      @app = app

      @condition = options[:if]
      @compressible_types = options[:include]
      @levels_options = { brotli: 4, zstd: 5 }.merge(options[:levels] || {})
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = Rack::Utils::HeaderHash.new(headers)

      unless should_deflate?(env, status, headers, body)
        return [status, headers, body]
      end

      request = Rack::Request.new(env)

      encoding = Rack::Utils.select_best_encoding(%w(zstd br), request.accept_encoding)

      return [status, headers, body] unless encoding

      # Set the Vary HTTP header.
      vary = headers["vary"].to_s.split(",").map(&:strip)
      unless vary.include?("*") || vary.include?("accept-encoding")
        headers["vary"] = vary.push("accept-encoding").join(",")
      end

      case encoding
      when "zstd"
        headers['content-encoding'] = "zstd"
        headers.delete(Rack::CONTENT_LENGTH)
        [status, headers, ZstandardStream.new(body, @levels_options[:zstd])]
      when "br"
        headers['content-encoding'] = "br"
        headers.delete(Rack::CONTENT_LENGTH)
        [status, headers, BrotliStream.new(body, @levels_options[:brotli])]
      when nil
        message = "An acceptable encoding for the requested resource #{request.fullpath} could not be found."
        bp = Rack::BodyProxy.new([message]) { body.close if body.respond_to?(:close) }
        [406, {Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => message.length.to_s}, bp]
      end
    end

    class BrotliStream
      include Rack::Utils

      def initialize(body, level)
        @body = body
        @level = level
      end

      def each(&block)
        @writer = block
        # Use String.new instead of '' to support environments with strings frozen by default.
        buffer = String.new
        @body.each do |part|
          buffer << part
        end

        # TODO: implement Brotli using streaming classes

        yield ::Brotli.deflate(buffer, { quality: @level })
      ensure
        @writer = nil
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    class ZstandardStream
      include Rack::Utils

      def initialize(body, level)
        @body = body
        @level = level
        @compressor = ::Zstd::StreamingCompress.new(level:)
      end

      def each(&block)
        @writer = block

        @body.each do |part|
          yield @compressor.compress(part)
        end

        yield @compressor.finish
      ensure
        @writer = nil
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    private

    def should_deflate?(env, status, headers, body)
      # Skip compressing empty entity body responses and responses with
      # no-transform set.
      if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status) ||
          headers[Rack::CACHE_CONTROL].to_s =~ /\bno-transform\b/ ||
         (headers['content-encoding'] && headers['content-encoding'] !~ /\bidentity\b/)
        return false
      end

      # Skip if @compressible_types are given and does not include request's content type
      return false if @compressible_types && !(headers.has_key?(Rack::CONTENT_TYPE) && @compressible_types.include?(headers[Rack::CONTENT_TYPE][/[^;]*/]))

      # Skip if @condition lambda is given and evaluates to false
      return false if @condition && !@condition.call(env, status, headers, body)

      true
    end
  end
end
