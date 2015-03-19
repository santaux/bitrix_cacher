require 'eventmachine'
require 'em-http'

EM.run {
  http = EM::HttpRequest.new("https://m.vk.com").get
  http.callback {
    puts http.response
    puts http.error
    #puts http.inspect
    EM.stop
  }
  http.errback {
    puts http.response
    puts http.error
    #puts http.inspect
    EM.stop
  }
}
