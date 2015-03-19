require 'rubygems'
require 'eventmachine'
require 'em-proxy'
require 'webrick'
require 'stringio'
require 'net/http'
require 'redis'

module EchoServer
  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_data data
    puts ">>>you sent:\n\n #{data} \n\n"

    uri = "http://localhost/companies/"
    page = redis.get(uri)

    puts ">>>I sent:\n\n #{page} \n\n"
    send_data page

    close_connection #if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end

  def redis
    @@redis ||= Redis.new
  end
end

# Note that this will block current thread.
EventMachine.run {
  EventMachine.start_server "127.0.0.1", 3003, EchoServer
}
