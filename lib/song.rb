require 'httparty'
require 'tagz'
require 'time'
require 'cgi'

class Song
  include HTTParty
  base_uri 'api.yes.com/1'
  format :json

  def self.find_relative_by_station(station, days_ago)
    json = get('/log', :query => {:name => station, :ago => days_ago})
    json['songs'].map {|s| s['at'] = Time.parse(s['at']); s}
  end

  def self.find_by_station_and_time(station, time)
    now = Time.now
    year, month, day = [now.year, now.month, now.day]
    today = Time.local year, month, day

    days_ago = ((today - time) / 86400).ceil
    songs = find_relative_by_station(station, days_ago)
    return nil if songs.empty?

    first = songs.first['at']
    last = songs.last['at']
    return nil unless (first..last).include? time

    return songs.reverse.find {|s| s['at'] <= time}
  end

  def self.plist_for_hash(song)
    Tagz.tagz do
      plist_(:version => 1.0) do
        dict_ do
          key_ 'title'
          string_ CGI::escapeHTML(song['title'])
          key_ 'artist'
          string_ CGI::escapeHTML(song['by'])
          key_ 'link'
          string_ "http://yes.com/i#{song['id']}"
        end
      end
    end
  end
end
