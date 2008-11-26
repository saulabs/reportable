require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ClassMethods do

  describe "#report_as_sparkline :<report_name>" do

    it 'should add the method <report_name>_report to the model' do
      User.methods.should include('registrations_report')
    end

    it 'should create a new Kvlr::ReportsAsSparkline::Report with the specified name to operate on in the created method' do
      Kvlr::ReportsAsSparkline::Report.should_receive(:new).once.with(User, :test, {})

      User.send(:report_as_sparkline, :test)
    end

  end

  describe "#report_as_sparkline :<report_name>, { :cumulate => :<cumulated_report_name> }" do

    it 'should create a new Kvlr::ReportsAsSparkline::CumulateReport with the specified cumulate option to operate on in the created method' do
      Kvlr::ReportsAsSparkline::CumulatedReport.should_receive(:new).once.with(User, :other_report, {})

      User.send(:report_as_sparkline, :test, :cumulate => :other_report)
    end

  end

end
