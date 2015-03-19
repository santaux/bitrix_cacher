require 'rubygems'
require 'eventmachine'
require 'em-proxy'
require 'webrick'
require 'stringio'
require 'net/http'
require 'redis'

module BitrixCacher
  # Application settings:
  module Settings extend self
    # passed paths to cache:
    def passed_paths
      [
        /companies\/\d+/,
        /users\/\w+/
      ]
    end

    # expiration time for cached pages (24 hours by default):
    def expiration_time
      Time.now.to_i + 60*60*24
      #Time.now.to_i + 20 # 20 seconds...
    end
  end

  # Cache reading and writing logic:
  class Cache

    attr_accessor :redis, :request, :cache, :page, :buffer, :page_key

    def initialize(request)
      self.redis = Redis.new
      self.request = request
      self.buffer = ""
      self.page_key = request.uri

      get_page!
    end

    def get_page!
      self.page = redis.get(page_key)
    end

    def set_page!
      redis.set(page_key, buffer)
    end

    def set_page_expiration!
      redis.expireat(page_key, BitrixCacher::Settings.expiration_time)
    end
  end

  # Request processing logic:
  class Request

    attr_accessor :path, :uri, :data, :parsed_request

    def initialize(data)
      self.data = data

      parse_request!
      self.uri = parsed_request.request_uri.to_s
      self.path = parsed_request.path.to_s
    end

    def path_passed?
      re = Regexp.union(BitrixCacher::Settings.passed_paths)
      path.match(re)
    end

    def parse_request!
      self.parsed_request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
      parsed_request.parse(StringIO.new(data))
    end
  end
end

Proxy.start(:host => "0.0.0.0", :port => 3001, :debug => true) do |conn|
  conn.server :srv, :host => "localhost", :port => 3000

  # modify / process request stream
  conn.on_data do |data|
    p [:on_data, data]

    process_request(data)

    if request.path_passed? && !cache.page.nil?
      puts "page: " + cache.page.inspect
      conn.send_data cache.page

      data = nil
      unbind
    end

    data
  end

  # modify / process response stream
  conn.on_response do |backend, resp|
    p [:on_response, backend, resp]

    if request.path_passed? && cache.page.nil?
      cache.buffer << resp
    end

    resp
  end

  # termination logic
  conn.on_finish do |backend, name|
    p [:on_finish, name]
    unbind #if backend == :srv
    #close_connection

    if request.path_passed? && cache.page.nil?
      cache.set_page!
      cache.set_page_expiration!
    end
  end

  def request
    @@request
  end

  def cache
    @@cache
  end

  def process_request(data)
    @@request = BitrixCacher::Request.new(data)
    @@cache = BitrixCacher::Cache.new(request)
  end
end
