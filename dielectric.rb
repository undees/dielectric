$: << File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'sinatra'
require 'station'
require 'song'

get '/' do
  redirect '/index.html'
end

get '/stations/:location' do |location|
  stations = Station.find_all_by_location(location)
  response['Cache-Control'] = 'public; max-age=86400'
  Station.plist_for_array(stations)
end

get '/:station/:time' do |station, time|
  zone = Song.zone_for_station(station)
  snapped_at = Time.parse(time + zone).getutc
  song = Song.find_by_station_and_time(station, snapped_at)
  return Song.no_match unless song

  response['Cache-Control'] = 'public; max-age=86400'
  Song.plist_for_hash(song)
end
