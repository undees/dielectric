require 'httparty'
require 'tagz'
require 'time'
require 'cgi'

require 'station'

class Song
  include HTTParty
  base_uri 'api.yes.com/1'
  format :json

  def self.fetch_relative_by_station(station, days_ago, zone)
    json = get('/log', :query => {:name => station, :ago => days_ago})
    json['songs'].map {|s| s['at'] = Time.parse(s['at'] + zone); s}
  end

  def self.fetch_recent_by_station(station, zone)
    json = get('/recent', :query => {:name => station, :max => 100})
    json['songs'].reject {|s| s['by'] == '-'}.map {|s| s['at'] = Time.parse(s['at'] + zone); s}
  end

  def self.zone_for_station(station)
    json = get('/station', :query => {:name => station})
    json['tz']
  end

  def self.select_from_range(songs, time)
    return nil if songs.empty?

    earliest, latest = [songs.first['at'], songs.last['at']].sort
    latest += 120

    return nil unless earliest <= time && time <= latest

    songs.sort_by {|s| s['at']}.reverse.find {|s| s['at'] <= time}
  end

  def self.find_by_station_and_time(station, time)
    now = Time.now.getutc
    year, month, day = [now.year, now.month, now.day]
    today = Time.utc year, month, day

    days_ago = ((today - time) / 86400).ceil

    zone = self.zone_for_station station

    self.select_from_range(self.fetch_relative_by_station(station, days_ago, zone), time) ||
      self.select_from_range(self.fetch_recent_by_station(station, zone), time)
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

  def self.no_match
    Tagz.tagz do
      plist_(:version => 1.0) do
        dict_ {}
      end
    end
  end
end
