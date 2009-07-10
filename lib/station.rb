require 'httparty'
require 'tagz'

class Station
  attr_reader :name, :link

  include HTTParty
  base_uri 'api.yes.com/1'
  format :json

  def initialize(options)
    @name = options['name']
    @link = "http://yes.com/#{@name}"
  end

  def ==(other)
    @name == other.name
  end

  def self.find_all_by_location(location)
    results = get('/stations',
                  :query => {:loc => location, :max => 50})['stations']
    results.map {|r| Station.new(r)}
  end

  def self.plist_for_array(stations)
    command = Tagz.tagz do
      plist_(:version => 1.0) do
        array_ do
          stations.each do |station|
            dict_ do
              key_ 'name'
              string_ station.name
              key_ 'link'
              string_ station.link
            end
          end
        end
      end
    end
  end
end
