require 'rubygems'
require 'mq'
require 'twitter/json_stream'
require 'pit'

query = ARGV.shift
query ||= "iphone"

account = Pit.get("twitter.com", :require => {
                    "username" => "username",
                    "password" => "password"
                  })

username = account["username"]
password = account["password"]

AMQP.start(:host => 'localhost') do
  twitter = MQ.new.fanout('twitter')

  stream = Twitter::JSONStream.connect(
    :path => "/1/statuses/filter.json?track=#{query}",
    :auth => "#{username}:#{password}"
  )

  stream.each_item do |status|
    puts status.inspect
    twitter.publish(status)
  end
end
