require 'rubygems'
require 'eventmachine'
require 'em-proxy'
require 'webrick'
require 'stringio'
require 'net/http'
require 'redis'

Proxy.start(:host => "0.0.0.0", :port => 3003, :debug => true) do |conn|
  conn.server :srv, :host => "vk.com", :port => 443

  def connection_completed
    start_tls
  end

  conn.on_connect do |data,b|
    puts [:on_connect, data, b].inspect
    start_tls
  end

  # modify / process request stream
  conn.on_data do |data|
    p [:on_data, data]

    data
  end

  # modify / process response stream
  conn.on_response do |backend, resp|
    p [:on_response, backend, resp]

    resp
  end

  # termination logic
  conn.on_finish do |backend, name|
    p [:on_finish, name]
    unbind if backend == :srv
  end
end
