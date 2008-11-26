require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportCache do

  it 'should raise an ArgumentError if no block is given' do
    lambda { Kvlr::ReportsAsSparkline::ReportCache.cached(User, :name, :days) }.should raise_error(ArgumentError)
  end

  it 'should not yield if data can be found in the cache' do
    Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return(true)

    lambda { Kvlr::ReportsAsSparkline::ReportCache.cached(User, :name, :days) do
      raise YieldCheckException
    end }.should_not raise_error(YieldCheckException)
  end

  it 'should yield if nothing can be found in the cache' do
    Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return(nil)

    lambda { Kvlr::ReportsAsSparkline::ReportCache.cached(User, :name, :days) do
      raise YieldCheckException
    end }.should raise_error(YieldCheckException)
  end

end

class YieldCheckException < Exception; end
