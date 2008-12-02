require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ClassMethods do

  describe "#report_as_sparkline :registrations" do

    it 'should add the method registrations_report to the model' do
      User.send(:report_as_sparkline, :registrations)

      User.methods.should include('registrations_report')
    end

    it 'should create a new Kvlr::ReportsAsSparkline::Report with the specified name to operate on in the created method' do
      Kvlr::ReportsAsSparkline::Report.should_receive(:new).once.with(User, :registrations, {})

      User.send(:report_as_sparkline, :registrations)
    end

  end

  describe "#report_as_sparkline :cumulated_registrations, { :cumulate => true }" do

    it 'should create a new Kvlr::ReportsAsSparkline::CumulateReport with the specified cumulate option to operate on in the created method' do
      Kvlr::ReportsAsSparkline::CumulatedReport.should_receive(:new).once.with(User, :cumulated_registrations, {})

      User.send(:report_as_sparkline, :cumulated_registrations, :cumulate => true)
    end

  end

end
