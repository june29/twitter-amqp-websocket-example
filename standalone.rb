require 'rubygems'
require 'twitter/json_stream'
require "eventmachine"
require "em-websocket"
require 'pit'

query = ARGV.shift
query ||= "iphone"

account = Pit.get("twitter.com", :require => {
                    "username" => "username",
                    "password" => "password"
                  })

username = account["username"]
password = account["password"]

@channel = EM::Channel.new

EventMachine::run {
  EventMachine::defer {
    puts "server start"

    EM::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
      ws.onopen do
        sid = @channel.subscribe {|msg| ws.send msg}
        puts "#{sid} connected"

        ws.onmessage {|msg|
          puts "<#{sid}>: #{msg}"
        }

        ws.onclose {
          @channel.unsubscribe(sid)
          puts "#{sid} closed"
        }
      end
    end
  }

  EventMachine::defer {
    stream = Twitter::JSONStream.connect(
               :path => "/1/statuses/filter.json?track=#{query}",
               :auth => "#{username}:#{password}"
             )

    stream.each_item do |status|
      puts status.inspect

      @channel.push status;
    end
  }
}
