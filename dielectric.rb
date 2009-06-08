require 'rubygems'
require 'sinatra'
require 'hpricot'
require 'tzinfo'
require 'open-uri'
require 'cgi'

get '/' do
  redirect '/index.html'
end

get '/:city/:station/:time' do |city, station, time|
  station.downcase!
  halt 404 unless ['knrk', 'kink'].include? station

  utc = Time.parse(time)

  # Both stations are in Pacific time for now.
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  off = tz.utc_to_local(utc)

  # Oops, TZInfo leaves the time zone in UTC.
  local = Time.local off.year, off.month, off.day, off.hour, off.min

  # These are just examples for teaching purposes.  Please be mindful
  # of people's servers.

  url_makers = {
    'knrk' => lambda {|t| "http://mobile.yes.com/song.jsp?city=24&station=knrk_94.7&hm=#{local.strftime('%H%M')}&a=0"},
    'kink' => lambda {|t| "http://playlist.kink.fm/today_lrp.asp?date=#{local.strftime('%m%d%Y')}"}
  }

  knrk_finder = lambda do |h, t|
    no_match = [nil, nil]
    title = (%r(<td>([^<]+)<br/>).match(h) || no_match)[1]
    artist = (%r(<br/>by ([^\\<]+)<br/>).match(h) || no_match)[1]
    [title, artist]
  end

  kink_finder = lambda do |h, t|
    doc = Hpricot(h)
    songs = (doc / 'tr.body').map do |row|
      time_s, title, artist = (row / 'td').map do |col|
        col.to_plain_text.strip
      end
      stamp = Time.parse(time_s)
      time = Time.local(t.year, t.month, t.day, stamp.hour, stamp.min)
      {:time => time, :artist => artist, :title => title}
    end

    result = songs.reverse.find {|r| r[:time] <= t}
    result ? [result[:title], result[:artist]] : [nil, nil]
  end

  finders = {
    'knrk' => knrk_finder,
    'kink' => kink_finder
  }

  url_maker, finder = url_makers[station], finders[station]
  halt 404 unless url_maker && finder

  url = url_maker[local]
  halt 404 unless url_maker

  headers = {'User-Agent' => 'Mozilla/5.0'}
  html = open(url, headers) {|f| f.read}
  title, artist = finder[html, local]

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
