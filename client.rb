require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'

class Handler  < EventMachine::Connection
  include EventMachine::HttpServer

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )

    # query our threaded server (max concurrency: 20)
    http = EM::Protocols::HttpClient.request(
      :host=>"localhost",
      :port=>80,
      :request=>"/"
    )

    # once download is complete, send it to client
    http.callback do |r|
      resp.status = 200
      resp.content = r[:content]
      resp.send_response
    end

  end
end

EventMachine::run {
  EventMachine::start_server("0.0.0.0", 8080, Handler)
  puts "Listening..."
}
