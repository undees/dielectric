$: << File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'sinatra'
require 'station'
require 'song'

get '/' do
  redirect '/index.html'
end

get '/stations/:zip' do |zip|
  stations = Station.find_all_by_zip(zip)
  response['Cache-Control'] = 'public; max-age=86400'
  Station.plist_for_array(stations)
end

get '/:station/:time' do |station, time|
  snapped_at = Time.parse(time)
  song = Song.find_by_station_and_time(station, snapped_at)
  halt 404 unless song

  response['Cache-Control'] = 'public; max-age=86400'
  Song.plist_for_hash(song)
end
