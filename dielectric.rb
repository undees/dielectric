require 'rubygems'
require 'sinatra'
require 'tzinfo'
require 'open-uri'
require 'cgi'

get '/' do
  'Hello world'
end

get '/:station/:time' do |station, time|
  halt 404 unless station.downcase == 'knrk'

  utc = Time.parse(time)
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  local = tz.utc_to_local(utc)
  clock = local.strftime('%H%M')

  # This is just an example for teaching purposes.  Please be mindful
  # of people's servers.
  url = "http://mobile.yes.com/song.jsp?city=24&station=knrk_94.7&hm=#{clock}&a=0"
  headers = {'User-Agent' => 'Mozilla/5.0'}
  html = open(url, headers) {|f| f.read}

  no_match = [nil, nil]
  title = (%r(<td>([^<]+)<br/>).match(html) || no_match)[1]
  artist = (%r(<br/>by ([^\\<]+)<br/>).match(html) || no_match)[1]

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

get '/stations' do
  <<HERE
<plist version="1.0">
<array>
	<string>KNRK</string>
</array>
</plist>
HERE
end
