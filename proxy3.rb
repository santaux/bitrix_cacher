require 'rubygems'
require 'eventmachine'
require 'em-proxy'

# Strandard blank em-proxy program:

Proxy.start(:host => "0.0.0.0", :port => 3002, :debug => true) do |conn|
  conn.server :srv, :host => "localhost", :port => 80

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
    unbind #if backend == :srv
    #close_connection
  end
end
