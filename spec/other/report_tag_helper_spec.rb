require File.join(File.dirname(File.dirname(File.expand_path(__FILE__))),'spec_helper')

require 'reportable/report_tag_helper'

describe Saulabs::Reportable::ReportTagHelper do

  before do
    @helper = TestHelper.new
  end

  describe '#raphael_report_tag' do

    data_set = Saulabs::Reportable::ResultSet.new([[DateTime.now, 1.0], [DateTime.now - 1.day, 3.0]], "User", "registrations")

    it 'should return a string' do
      @helper.raphael_report_tag(data_set).class.should == String
    end

    it 'should contain a div tag' do
      @helper.raphael_report_tag(data_set).should =~ /^<div id=".*">.*<\/div>/
    end

    it 'should contain a script tag' do
      @helper.raphael_report_tag(data_set).should =~ /<script type="text\/javascript" charset="utf-8">.*<\/script>/m
    end

    it 'should assign a default dom id to the the div tag if none is specified' do
      @helper.raphael_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}".*<\/div>/
    end

    it 'should assign correct default dom ids to the the div tag if none is specified and there are more than one report tags on the page' do
      @helper.raphael_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}".*<\/div>/
      @helper.raphael_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}1".*<\/div>/
    end
    
    it 'should include the data [1,3]' do
      @helper.raphael_report_tag(data_set).should =~ /\[1,3\]/
    end

  end
  
    describe '#flot_report_tag' do

    data_set = Saulabs::Reportable::ResultSet.new([[DateTime.now, 1.0], [DateTime.now - 1.day, 3.0]], "User", "registrations")

    it 'should return a string' do
      @helper.flot_report_tag(data_set).class.should == String
    end

    it 'should contain a div tag' do
      @helper.flot_report_tag(data_set).should =~ /^<div id=".*">.*<\/div>/
    end

    it 'should contain a script tag' do
      @helper.flot_report_tag(data_set).should =~ /<script type="text\/javascript" charset="utf-8">.*<\/script>/m
    end

    it 'should assign a default dom id to the the div tag if none is specified' do
      @helper.flot_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}".*<\/div>/
    end

    it 'should assign correct default dom ids to the the div tag if none is specified and there are more than one report tags on the page' do
      @helper.flot_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}".*<\/div>/
      @helper.flot_report_tag(data_set).should =~ /^<div id="#{data_set.model_name.downcase}_#{data_set.report_name}1".*<\/div>/
    end

  end

  describe '#google_report_tag' do

    it 'should render an image with the correct source' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=0077cc&chm=B,e6f2fa,0,0,0&chls=1,0,0&chds=1.0,3.0',
        { :title => nil, :alt => nil }
      )

      @helper.google_report_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]])
    end

    it 'should add parameters for labels to the source of the image if rendering of lables is specified' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=0077cc&chm=B,e6f2fa,0,0,0&chls=1,0,0&chds=1.0,3.0&chxt=x,y,r,t&chxr=0,0,3|1,0,3.0|2,0,3.0|3,0,3',
        { :title => nil, :alt => nil }
      )

      @helper.google_report_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]], :labels => [:x, :y, :r, :t])
    end

    it 'should set the parameters for custom colors if custom colors are specified' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=000000&chm=B,ffffff,0,0,0&chls=1,0,0&chds=1.0,3.0',
        { :title => nil, :alt => nil }
      )

      @helper.google_report_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]], :line_color => '000000', :fill_color => 'ffffff')
    end

    it 'should set the parameters for a custom title if a title specified' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=0077cc&chm=B,e6f2fa,0,0,0&chls=1,0,0&chds=1.0,3.0&chtt=title',
        { :title => 'title', :alt => nil }
      )

      @helper.google_report_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]], :title => 'title')
    end

    it 'should use a specified alt text as alt text for the image' do
      @helper.should_receive(:image_tag).once.with(
        'http://chart.apis.google.com/chart?cht=ls&chs=300x34&chd=t:1.0,2.0,3.0&chco=0077cc&chm=B,e6f2fa,0,0,0&chls=1,0,0&chds=1.0,3.0',
        { :title => nil, :alt => 'alt' }
      )

      @helper.google_report_tag([[DateTime.now, 1.0], [DateTime.now, 2.0], [DateTime.now, 3.0]], :alt => 'alt')
    end

  end

end

class TestHelper

  include Saulabs::Reportable::ReportTagHelper

end
