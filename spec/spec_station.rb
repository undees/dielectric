describe Station do
  before do
    @knrk_options = {'name' => 'KNRK', 'timezone' => 'PST'}
    @knrk = Station.new @knrk_options
  end

  it 'finds stations by location' do
    Station.should_receive(:get).
      and_return({'stations' => [@knrk_options]})
    Station.find_all_by_zip(97205).should == [@knrk]
  end

  it 'provides a link back to the data provider' do
    @knrk.link.should == 'http://yes.com/KNRK'
  end

  it 'serializes a list of stations to a plist' do
    Station.plist_for_array([@knrk]).should ==
      <<HERE.gsub(/[\r\n\t]+/, '')
<plist version="1.0">
<dict>
	<key>KNRK</key>
	<string>http://yes.com/KNRK</string>
</dict>
</plist>
HERE
  end
end
