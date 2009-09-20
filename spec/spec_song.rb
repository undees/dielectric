require File.join(File.dirname(__FILE__), 'spec_helper')

describe Song, '.find_by_station_and_time' do
  before do
    @today_noon = Time.local(2009, 6, 21, 12)
    @yesterday_noon = @today_noon - 86400
    @songs =
      [
       {'title' => 'Earliest', 'by' => 'Someone', 'at' => @yesterday_noon - 600},
       {'title' => 'Earlier',  'by' => 'Someone', 'at' => @yesterday_noon - 300},
       {'title' => 'Then',     'by' => 'Someone', 'at' => @yesterday_noon      },
       {'title' => 'Later',    'by' => 'Someone', 'at' => @yesterday_noon + 300},
       {'title' => 'Latest',   'by' => 'Someone', 'at' => @yesterday_noon + 600},
      ]

    @near_miss = {'title' => 'After Then', 'by' => 'Someone', 'at' => @yesterday_noon - 120}

    @before_range = @songs[0..1]
    @barely_before_range = @before_range + [@near_miss]
    @song = @songs[2]
    @after_range = @songs[3..4]
  end

  it 'finds songs present in the range' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return(@songs)
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == @song
  end

  it 'returns nil if the range is too early' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return(@before_range)
    Song.should_receive(:find_recent_by_station).with('KNRK').and_return([])
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == nil
  end

  it 'returns nil if the range is too late' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return(@after_range)
    Song.should_receive(:find_recent_by_station).with('KNRK').and_return([])
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == nil
  end

  it 'returns a song just after the range' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return(@barely_before_range)
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == @near_miss
  end

  it 'falls back on an alternate method if the results are empty' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return([])
    Song.should_receive(:find_recent_by_station).with('KNRK').and_return(@songs)
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == @song
  end

  it 'falls back on an alternate method if the results are out of range' do
    Time.should_receive(:now).and_return(@today_noon)
    Song.should_receive(:find_relative_by_station).with('KNRK', 1).and_return(@before_range)
    Song.should_receive(:find_recent_by_station).with('KNRK').and_return(@songs)
    Song.find_by_station_and_time('KNRK', @yesterday_noon).should == @song
  end
end


describe Song do
  it 'can serialize a hash to a plist' do
    song = {'by' => 'Weezer', 'title' => 'Pork and Beans', 'id' => '12661822'}
    Song.plist_for_hash(song).should ==
      <<HERE.gsub(/[\r\n\t]/, '')
<plist version="1.0">
<dict>
	<key>title</key>
	<string>Pork and Beans</string>
	<key>artist</key>
	<string>Weezer</string>
	<key>link</key>
	<string>http://yes.com/i12661822</string>
</dict>
</plist>
HERE
  end

  it 'has a sensible representation of "no match"' do
    Song.no_match.should ==
      <<HERE.gsub(/[\r\n\t]/, '')
<plist version="1.0">
<dict/>
</plist>
HERE
  end
end
