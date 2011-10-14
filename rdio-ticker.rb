#!/usr/bin/ruby

# rdio-ticker.rb
# Shows a stream of playing songs from users that a given user is following.

require 'rubygems'
require 'json'
require 'date'
require 'time'

POLL_INTERVAL = 30 # seconds

if ARGV[0].nil?
  puts "Usage: ./rdio-ticker.rb RDIO_USERNAME"
  exit 1
end

def colorize(text, color_code)
  "#{color_code}#{text}\e[0m"
end

def red(text); colorize(text, "\e[31m"); end
def green(text); colorize(text, "\e[32m"); end
def yellow(text); colorize(text, "\e[33m"); end
def blue(text); colorize(text, "\e[34m"); end
def magenta(text); colorize(text, "\e[35m"); end
def cyan(text); colorize(text, "\e[36m"); end

def curl_request(params)
  response = `curl --silent --cookie "session=\"c1/+hfJqU4l7W2fP339IplSoE9s=?secret=UydhNDhlMDQ3MzI0NDRiY2Q3NWJkZTY0NGNkM2Y0MmI0MycKcDAKLg==\"" -d "__rdio_console_secret=a48e04732444bcd75bde644cd3f42b43#{params}" http://rdioconsole.appspot.com/call`
  if response == "null"
    puts "Error: User not found"
    exit 1
  else
    JSON.parse(response)
  end
end

puts "Loading..."

# Find user key
user_key = curl_request("&method=findUser&vanityName=#{ARGV[0]}")["result"]["key"]

# Find users that user is following
user_following = curl_request("&method=userFollowing&user=#{user_key}&count=100")["result"]
user_following_keys = user_following.map { |user| user["key"] }.join(",")
displayed_tracks = []

if user_following_keys == ""
  puts "Error: User is not following anyone"
  exit 1
end
  
loop do
  # Fetch latest tracks from users
  last_played_tracks = curl_request("&method=get&keys=#{user_following_keys}&extras=lastSongPlayed,lastSongPlayTime")["result"].values
  last_played_tracks.each do |track|
    # Only show songs that have been played within the past 5 minutes and haven't already been displayed
    if track["lastSongPlayed"] && track["lastSongPlayTime"]
      if !displayed_tracks.include?(track["lastSongPlayed"]["key"]) && Time.now - Time.parse(DateTime.strptime(track["lastSongPlayTime"], "%FT%T%n").to_s) < 60 * 5
        puts cyan(track["firstName"] + " " + track["lastName"]).ljust(40, " ") + green(track["lastSongPlayed"]["artist"]).ljust(40, " ") + yellow(track["lastSongPlayed"]["name"])
        displayed_tracks << track["lastSongPlayed"]["key"]
      end
    end
  end
  
  sleep POLL_INTERVAL
  
end