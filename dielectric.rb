require 'rubygems'
require 'sinatra'
require 'json'
require 'tzinfo'
require 'open-uri'
require 'cgi'

get '/' do
  redirect '/index.html'
end

get '/:city/:station/:time' do |city, station, time|
  # All stations are in Pacific time for now.
  utc = Time.parse(time)
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  off = tz.utc_to_local(utc)

  # Oops, TZInfo leaves the time zone in UTC.
  local = Time.local off.year, off.month, off.day, off.hour, off.min
  day_of = Time.local off.year, off.month, off.day
  days_ago = ((Time.now - day_of) / 86400.0).to_i
  halt 404 unless (0..6).include? days_ago

  url = "http://api.yes.com/1/log?name=#{station}&ago=#{days_ago}"
  json = open(url) {|f| f.read}
  songs = JSON.parse(json)['songs']
  songs.map! {|s| s.merge({'at' => Time.parse(s['at'])})}
  song = songs.reverse.first {|s| s.at < local}

  unless song
    url = "http://api.yes.com/1/recent?name=#{station}&max=100"
    json = open(url) {|f| f.read}
    songs = JSON.parse(json)['songs']
    songs.map! {|s| s.merge({'at' => Time.parse(s['at'])})}
    song = songs.first {|s| s.at < local}
  end

  halt 404 unless song

  title, artist = song['title'], song['by']
  halt 404 unless title && artist

  response['Cache-Control'] = 'public; max-age=86400'

  <<HERE
<plist version="1.0">
<dict>
	<key>title</key>
	<string>#{CGI::escapeHTML title}</string>
	<key>artist</key>
	<string>#{CGI::escapeHTML artist}</string>
</dict>
</plist>
HERE
end

get '/:city/stations' do |city|
  <<HERE
<plist version="1.0">
<array>
	<string>KNRK</string>
	<string>KINK</string>
</array>
</plist>
HERE
end
