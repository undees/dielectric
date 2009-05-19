require 'rubygems'
require 'sinatra'
require 'tzinfo'
require 'open-uri'

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

  title = %r(<td>([^<]+)<br/>).match(html)[1]
  artist = %r(<br/>by ([^\\<]+)<br/>).match(html)[1]

  halt 404 unless title && artist

  <<HERE
<plist version="1.0">
<dict>
	<key>title</key>
	<string>#{title}</string>
	<key>artist</key>
	<string>#{artist}</string>
</dict>
</plist>
HERE
end
