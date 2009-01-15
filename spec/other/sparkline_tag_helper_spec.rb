require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::SparklineTagHelper do

  before do
    @helper = TestHelper.new
  end

  describe '#sparkline_tag' do

    it 'should render an image with the correct source' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=0077cc&chm=B,E6F2FA,0,0,0&chls=1,0,0&chds=1.0,3.0'
      )

      @helper.sparkline_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]])
    end

  end

end

class TestHelper

  include Kvlr::ReportsAsSparkline::SparklineTagHelper

end
