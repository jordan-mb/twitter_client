#!/usr/bin/env ruby
require 'oauth'
require 'launchy'
require 'yaml'
require 'addressable/uri'
require 'json'
require './super_secret_twitter.rb'

class Twitter
  COMMANDS = ["t to tweet", "d to direct message",
              "p to get a friend's last post", "u to see your timeline",
              "e to exit"]

  CONSUMER = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET,
    :site => "http://twitter.com")

  def initialize
    @token = get_token('tokenfile')
  end

  def run
    puts "Welcome to Jordan and Niranjan's Twitter client!!!!!!!!"
    while true
      puts "Here are the available commands: #{COMMANDS}"
      case gets.chomp[0]
      when 'e'
        break
      when 't'
        post_status(@token)
      when 'd'
        send_dm(@token)
      when 'p'
        p read_status(@token)
      when 'u'
        p user_timeline(@token)
      else
        puts "This is not a command. Try harder."
      end
    end
    puts "Thanks for using Jordan and Niranjan's Twitter client!"
  end

  private

  def get_access_token

    request_token = CONSUMER.get_request_token
    puts "Go here. NOW!"
    Launchy.open(request_token.authorize_url)

    puts "Login, then type your verification code in"
    oauth_verifier = gets.chomp

    access_token = request_token.get_access_token(
      :oauth_verifier => oauth_verifier)

  end

  def user_timeline(access_token)
    begin
      timeline = access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json").body
      JSON.parse(timeline)[0]["text"]
    rescue
      "No timeline to show"
    end
  end

  def post_status(access_token)
    status = {:status => get_status}
    access_token.post("http://api.twitter.com/1.1/statuses/update.json",
      status)
  end

  def send_dm(access_token)
    dm = {:text => get_status, :screen_name => get_destination}
    access_token.post("https://api.twitter.com/1.1/direct_messages/new.json",
      dm)
  end

  def read_status(access_token)
    begin
      status_info = Addressable::URI.new(
        :scheme => "https",
        :host => "api.twitter.com",
        :path => "/1.1/statuses/user_timeline.json",
        :query_values => {:screen_name => get_destination, :count => "1"}
      )
      status_json = access_token.get(status_info.to_s).body
      JSON.parse(status_json)[0]["text"]
    rescue
      "No last post to show"
    end
  end

  def get_status
    puts "Say what you wanna say. Keep it under 140 peeps:"
    gets.chomp[0...140]
  end

  def get_destination
    puts "Whom? DON'T put an '@' before their username!"
    gets.chomp
  end

  def get_token(token_file)
    if File.exist?(token_file)
      File.open(token_file) {|f| YAML.load(f)}
    else
      access_token = get_access_token
      File.open(token_file, "w") {|f| YAML.dump(access_token, f)}

      access_token
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Twitter.new.run
end
